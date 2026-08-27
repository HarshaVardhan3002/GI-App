import 'dart:ui' as ui;

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template gi_material}
/// A bar that content passes under rather than stops at.
///
/// **The difference between glass and frost is saturation, not blur.** A plain
/// [BackdropFilter] desaturates what sits behind it, which is why default glass
/// reads as fog on a window. `ColorFilter` implements [ui.ImageFilter], so
/// [ui.ImageFilter.compose] can put a saturation matrix outside the blur and
/// push the colour back up. Light then appears to pass through the surface
/// instead of stopping at it.
///
/// `DESIGN.md` section 4, Normal: blur 26, saturation 1.8, tint at depth 0.30
/// graded 58% at the screen edge to 16% at the inner edge, and the inner
/// [fadeExtent] masking to transparent so the bar has no edge to notice.
///
/// **This does not use `BackdropFilter.grouped`, and Phase 8's claim that it
/// does is withdrawn.** On Flutter 3.35.7, two grouped filters inside one
/// [BackdropGroup] that carry the *same* filter make the second paint the
/// first's backdrop. Measured on `emulator-5554`, same frame: with grouping the
/// bottom bar sampled (123,40,28) against the top bar's (134,51,36), which is
/// the endoscopic image 1400px above it; without grouping it sampled (19,10,10)
/// against (27,8,9) directly beneath it. Both bars use Normal, so they are
/// exactly the identical-filter case. It went unnoticed in Phase 8 because in
/// dark, over a red image, a bar showing the wrong red still looks like a bar.
///
/// Grouping bought about 1.2ms of raster at p50. A bar that shows the wrong
/// part of the screen is not worth 1.2ms. [GiBackdropGroup] stays in the tree
/// because it also carries [MaterialQuality]; only the sharing is off, and it
/// goes back on when the sharing is correct.
///
/// It takes its kill switch from [MaterialQuality]. With the switch off it
/// paints the same
/// tint opaque at the same depth, at the same size, in the same place. The
/// screen is never missing a surface, only its transparency.
/// {@endtemplate}
class GiMaterial extends StatelessWidget {
  /// {@macro gi_material}
  const GiMaterial({required this.edge, this.child, super.key});

  /// Which screen edge this bar is pinned to. The tint is heaviest there and
  /// the fade runs away from it.
  final VerticalDirection edge;

  /// What sits on the material.
  final Widget? child;

  /// Section 4: blur 26.
  static const double blurSigma = 26;

  /// Section 4: saturation 1.8. Below 1 this would be frost.
  static const double saturation = 1.8;

  /// Section 4 rule 3, fade never stop. No hairline where chrome ends.
  static const double fadeExtent = 36;

  /// A saturation matrix, as [ColorFilter.matrix] wants it.
  ///
  /// Luminance weights are the Rec. 709 ones Skia uses, so a fully desaturated
  /// pixel keeps its perceived brightness.
  static ColorFilter saturate(double s) {
    const r = 0.213;
    const g = 0.715;
    const b = 0.072;
    final inv = 1 - s;
    return ColorFilter.matrix(<double>[
      inv * r + s, inv * g, inv * b, 0, 0, //
      inv * r, inv * g + s, inv * b, 0, 0, //
      inv * r, inv * g, inv * b + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tint = context.gi.depth(.30);
    final fromTop = edge == VerticalDirection.up;
    final outer = fromTop ? Alignment.topCenter : Alignment.bottomCenter;
    final inner = fromTop ? Alignment.bottomCenter : Alignment.topCenter;

    final blurEnabled = MaterialQuality.blurOf(context);

    return ClipRect(
      child: ShaderMask(
        // The mask applies to the material, blur included. Fading only the
        // tint would leave a sharply cut rectangle of blurred image, which is
        // the hairline rule 3 exists to prevent.
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          // The fade is a fixed 36dp whatever the bar's height, so the stop is
          // read off the bar's painted size rather than assumed. `rect` is the
          // laid-out child, which is why this is not a LayoutBuilder: the
          // Scaffold hands a bar loose constraints as tall as the screen.
          final fadeStart = rect.height <= fadeExtent
              ? 0.0
              : (rect.height - fadeExtent) / rect.height;
          return LinearGradient(
            begin: outer,
            end: inner,
            colors: const [Colors.white, Colors.white, Colors.transparent],
            stops: [0, fadeStart, 1],
          ).createShader(rect);
        },
        child: BackdropFilter(
          filter: ui.ImageFilter.compose(
            outer: saturate(saturation),
            inner: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          ),
          enabled: blurEnabled,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // **Held at 58%, not graded down across the bar.** The tint used
              // to ramp 58% to 16% over the bar's whole height, on top of the
              // ShaderMask above already fading the material to nothing over
              // its last [fadeExtent]. Two mechanisms doing one job, and the
              // one that lost was legibility: by the label row the tint was
              // near 16%, so a bar over a bright endoscopic frame barely
              // darkened it. Measured on `emulator-5554`, *Heute* against a
              // pale mucosal wall came out at **1.10:1**. It was unreadable,
              // on the second case a reader sees.
              //
              // Section 4 still reads 58% to 16%: the grade is the mask's, in
              // the 36dp tail where it belongs, and the bar holds its tint
              // over the text it is there to carry. Against the same frame
              // that measured 1.10:1 this holds about 6.4:1.
              //
              // Reduced transparency drops the alpha and nothing else.
              color: blurEnabled ? tint.withValues(alpha: .58) : tint,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// {@template gi_sheet_material}
/// The Dick material, for sheets.
///
/// `DESIGN.md` section 4: blur 40, saturation 1.5, tint at depth 0.15 and 88%.
/// Heavier and less transparent than a bar, because a sheet is a place you are
/// in rather than chrome you are looking past.
///
/// Its top edge is a 1px inset highlight at 16% white. Section 4 rule 4:
/// **edges are light, not shadow. No cast shadows anywhere in this app.**
/// {@endtemplate}
class GiSheetMaterial extends StatelessWidget {
  /// {@macro gi_sheet_material}
  const GiSheetMaterial({required this.child, super.key});

  /// The sheet's content.
  final Widget child;

  /// Section 4, Dick.
  static const double blurSigma = 40;

  /// Section 4, Dick. Lower than a bar's: less of the screen shows through, so
  /// less needs putting back.
  static const double saturation = 1.5;

  /// Section 6: sheets.
  static const double radius = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    const shape = BorderRadius.vertical(top: Radius.circular(radius));

    final blurEnabled = MaterialQuality.blurOf(context);

    return ClipRRect(
      borderRadius: shape,
      // Plain, not `.grouped`, for the reason recorded on [GiMaterial]: on
      // Flutter 3.35.7 a shared group draws the wrong backdrop.
      child: BackdropFilter(
        filter: ui.ImageFilter.compose(
          outer: GiMaterial.saturate(saturation),
          inner: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        ),
        enabled: blurEnabled,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: blurEnabled
                ? colors.depth(.15).withValues(alpha: .88)
                : colors.depth(.15),
            borderRadius: shape,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: .16),
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// {@template gi_thin_material}
/// The Ultradünn material, for a surface that sits directly on media.
///
/// `DESIGN.md` section 4: blur 18, saturation 1.8, tint at depth 0.30 and 24%.
/// **The thinnest of the three, and the only one whose site is "over media".**
/// It was not built until a screen needed it, because a widget nothing calls
/// is dead code; Heute's card now reads its text off a pane laid over the
/// image's own ambient light, which is that site exactly.
///
/// Thin is the whole point. A sheet at 88% would put the light out, and the
/// reason the pane is there is that the light should carry on underneath it.
/// Section 4 rule 1 still holds: this floats over moving content, it is not a
/// card on a flat ground.
///
/// Its top edge is a 1px inset highlight at 16% white. Rule 4: **edges are
/// light, not shadow.**
/// {@endtemplate}
class GiThinMaterial extends StatelessWidget {
  /// {@macro gi_thin_material}
  const GiThinMaterial({required this.child, this.radius = 20, super.key});

  /// What reads off the pane.
  final Widget child;

  /// The top corners. Square when a caller wants the pane to run to the edge.
  final double radius;

  /// Section 4, Ultradünn.
  static const double blurSigma = 18;

  /// Section 4, Ultradünn. The highest of the three: least of the surface is
  /// tint, so most of what the reader sees is blurred image, and blurred image
  /// is where the colour is lost.
  static const double saturation = 1.8;

  /// Section 4, Ultradünn.
  ///
  /// **55%, not the 24% first written down.** 24% was set against an
  /// assumption about what "over media" meant, and the media in this app is an
  /// endoscopic frame lit by a xenon source, which is the brightest thing on
  /// the screen by a wide margin. Once Heute's pane moved up to sit directly
  /// under the frame, 24% of a near-black tint over that light left the
  /// question and the tint reading off a bright olive ground.
  ///
  /// It is still the thinnest of the three by a long way, and 45% of the light
  /// still comes through, which is the whole reason the pane is this material
  /// and not a sheet.
  static const double tintAlpha = .55;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    final shape = BorderRadius.vertical(top: Radius.circular(radius));

    final blurEnabled = MaterialQuality.blurOf(context);
    final tint = colors.depth(.30);

    return ClipRRect(
      borderRadius: shape,
      // Plain, not `.grouped`, for the reason recorded on [GiMaterial].
      child: BackdropFilter(
        filter: ui.ImageFilter.compose(
          outer: GiMaterial.saturate(saturation),
          inner: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        ),
        enabled: blurEnabled,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Section 4: reduced transparency collapses the material to an
            // opaque surface at the same depth. Same depth, same place, same
            // size; only the light behind it goes.
            color: blurEnabled ? tint.withValues(alpha: tintAlpha) : tint,
            borderRadius: shape,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: .16)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
