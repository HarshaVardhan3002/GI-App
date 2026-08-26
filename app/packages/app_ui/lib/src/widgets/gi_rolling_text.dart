import 'dart:async';

import 'package:flutter/material.dart';

/// {@template gi_rolling_text}
/// A single line of text that shows itself in full by rolling, rather than by
/// giving up in an ellipsis.
///
/// **German clinical language does not fit on a phone.** *Zylinderepithel-
/// metaplasie*, *Ösophagogastroduodenoskopie*, *Konsensusempfehlung* are
/// ordinary words in this product, not edge cases, and a heading built from
/// them truncates on every device we ship to. An ellipsis is a design telling
/// the reader that the rest is not worth their attention, which in a heading
/// naming a finding is untrue.
///
/// So the line rests at its start, and after [dwell] rolls right to left at a
/// steady [speed] until its end is showing, rests again, and returns. The
/// reader does nothing. It is the same behaviour as a departure board: legible
/// at rest, complete if you keep watching.
///
/// **It only ever moves when it has something to reveal.** Text that fits is
/// laid out and left alone, with no controller running and no ticker
/// registered, so the common case costs nothing.
///
/// It also stops entirely when the platform asks for reduced motion. A reader
/// who has turned animation off has said that text moving under their eyes is
/// a problem for them, and the fallback is the ellipsis they would otherwise
/// have had.
/// {@endtemplate}
class GiRollingText extends StatefulWidget {
  /// {@macro gi_rolling_text}
  const GiRollingText(
    this.text, {
    this.style,
    this.dwell = const Duration(milliseconds: 2200),
    this.speed = 26,
    this.textAlign = TextAlign.start,
    super.key,
  });

  /// The line. Newlines are not expected here; this is a heading.
  final String text;

  /// How it is set.
  final TextStyle? style;

  /// How long the line rests at each end before it moves.
  ///
  /// Long on purpose. The rest is the reading position, and the roll is the
  /// thing that happens if you have not finished; a short dwell would make it
  /// a ticker, which is a different and much more irritating object.
  final Duration dwell;

  /// Density-independent pixels per second while rolling.
  ///
  /// Slow enough to read at, which is the whole point: a fast roll would only
  /// tell the reader that more text exists.
  final double speed;

  /// Alignment while at rest and while the text fits.
  final TextAlign textAlign;

  @override
  State<GiRollingText> createState() => _GiRollingTextState();
}

class _GiRollingTextState extends State<GiRollingText>
    with SingleTickerProviderStateMixin {
  /// Drives the offset. Its duration is set from the overflow distance when
  /// the roll starts, so long headings and short ones move at the same speed
  /// rather than taking the same time.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration.zero,
  );

  Timer? _timer;
  double _overflow = 0;
  bool _reversed = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GiRollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different heading is a different measurement. Stop where we are and
    // let the next layout decide again, or the new text inherits the old
    // text's offset.
    if (oldWidget.text != widget.text) _stop();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _controller
      ..stop()
      ..value = 0;
    _reversed = false;
  }

  /// Called from layout, so it must not call `setState`.
  void _sync(double overflow, bool animationsEnabled) {
    if (!animationsEnabled || overflow <= 0) {
      if (_timer != null || _controller.isAnimating) {
        // Deferred: layout is not a safe place to touch a controller.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _stop();
        });
      }
      _overflow = overflow;
      return;
    }
    if (_overflow == overflow && _timer != null) return;
    _overflow = overflow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _schedule();
    });
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(widget.dwell, _roll);
  }

  Future<void> _roll() async {
    if (!mounted || _overflow <= 0) return;
    final seconds = _overflow / widget.speed;
    _controller.duration = Duration(milliseconds: (seconds * 1000).round());
    try {
      // Linear, not eased. An eased marquee reads as something sliding into
      // place; this is a line being read past, and it should move at reading
      // pace throughout.
      if (_reversed) {
        await _controller.reverse();
      } else {
        await _controller.forward();
      }
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    _reversed = !_reversed;
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    // `disableAnimations` is the platform's own accessibility switch; on
    // Android it is "Remove animations", on iOS "Reduce Motion".
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    final style = widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();
        // Read everything off the painter before disposing it. Touching it
        // afterwards trips `!debugDisposed` and replaces the heading with an
        // error box, which is exactly what the first run of this did.
        final textWidth = painter.width;
        final height = painter.height;
        final overflow =
            (textWidth - constraints.maxWidth).clamp(0.0, double.infinity);
        painter.dispose();

        _sync(overflow, animationsEnabled);

        if (overflow <= 0 || !animationsEnabled) {
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
            style: style,
          );
        }

        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          // The line runs to both edges of its box while rolling. There is no
          // fade mask at the edges: `DESIGN.md` section 4 rule 4 gives this
          // app one fade, the one under a bar, and adding a second kind here
          // would make the heading look like chrome.
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_controller.value * overflow, 0),
                child: child,
              ),
              child: OverflowBox(
                alignment: AlignmentDirectional.centerStart,
                maxWidth: textWidth + 1,
                child: Text(
                  widget.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: style,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
