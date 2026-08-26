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
/// **This is the Normal material only.** Ultradünn, Dick, reduced-transparency
/// collapse and the shared [BackdropGroup] pass are Phase 8; the dimensions
/// here are the ones that phase will keep.
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: outer,
                end: inner,
                colors: [
                  tint.withValues(alpha: .58),
                  tint.withValues(alpha: .16),
                ],
              ),
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

    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.compose(
          outer: GiMaterial.saturate(saturation),
          inner: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.depth(.15).withValues(alpha: .88),
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
