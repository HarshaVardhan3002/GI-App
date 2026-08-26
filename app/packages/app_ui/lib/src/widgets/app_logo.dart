import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template app_logo}
/// The application wordmark.
///
/// *GI Daily*, set in Newsreader at 20/24, weight 400 - the first of the three
/// places this product uses a serif, alongside the question and the guideline
/// quote. See `DESIGN.md` section 5.
///
/// This replaced an SVG, and it keeps the SVG's sizing contract so that no call
/// site had to change. A vector scales to whatever box it is given; text does
/// not. So when a caller asks for a [width] or a [height], the wordmark is
/// scaled into that box with the requested [fit], exactly as the vector was.
/// When a caller asks for neither, it renders at its designed size instead of
/// being stretched to an arbitrary default.
/// {@endtemplate}
class AppLogo extends StatelessWidget {
  /// {@macro app_logo}
  const AppLogo({
    this.fit = BoxFit.contain,
    super.key,
    this.width,
    this.height,
    this.color,
  });

  /// How the wordmark is scaled when [width] or [height] is given.
  ///
  /// Ignored when both are null, because there is no box to fit into.
  final BoxFit fit;

  /// The width of the wordmark. Null renders it at its designed size.
  final double? width;

  /// The height of the wordmark. Null renders it at its designed size.
  final double? height;

  /// The colour of the wordmark. Defaults to the adaptive foreground.
  final Color? color;

  /// The wordmark, exactly as it is written. Never all-caps.
  static const String wordmark = 'GI Daily';

  @override
  Widget build(BuildContext context) {
    final text = Text(
      wordmark,
      maxLines: 1,
      softWrap: false,
      // The wordmark's type is one of the eight roles, not a local decision.
      style: GiText.wordmark.copyWith(
        color: color ?? context.gi.label,
      ),
    );

    if (width == null && height == null) return text;

    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(fit: fit, child: text),
    );
  }
}
