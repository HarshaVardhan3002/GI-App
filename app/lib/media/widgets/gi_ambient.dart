import 'dart:ui' as ui;

import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';

/// {@template gi_ambient}
/// The image's own light, spilled onto the ground around it.
///
/// **An endoscopic image arrives at whatever shape the scope left it in**, and
/// this app refuses to crop one, so a frame that is not the screen's shape
/// leaves space. That space used to be flat ramp: a 1356x520 strip sat in the
/// middle of two thirds of dead black, and the screen read as a photograph
/// stamped onto a page rather than a screen lit by a photograph.
///
/// This fills it with the image itself, decoded small, scaled up and blurred
/// until nothing of it survives but its colour and where that colour sits. It
/// is the same mechanism as an ambient-mode video player: the ground is not
/// decorated, it is *lit*, and the light comes from the only saturated thing on
/// the screen.
///
/// **It does not break `DESIGN.md` section 1 rule 1.** No colour is introduced
/// here that is not already in the image; there is no palette, no accent and
/// nothing chosen. Blur it far enough and a gradient is what an image becomes.
///
/// **It costs almost nothing**, which is the reason it is built this way rather
/// than as a large blur. The asset is decoded at [sourceWidth] pixels wide, so
/// the texture is smaller than an icon; scaling that back up to a phone screen
/// is already a smooth field, and [blurSigma] only removes the last of the
/// blockiness. A full-resolution frame under a sigma-60 blur would have been
/// the most expensive thing on the screen.
/// {@endtemplate}
class GiAmbient extends StatelessWidget {
  /// {@macro gi_ambient}
  const GiAmbient({
    required this.image,
    this.navInset = 0,
    this.ground,
    super.key,
  });

  /// The image whose light this is. A placeholder has none, and draws nothing.
  final GiImage image;

  /// How much of the bottom edge gets no light at all, as a fraction of this
  /// box's height.
  ///
  /// **The navigation bar's band.** The bar is a material with the screen
  /// visible through it, and a bar showing the strongest part of a colour
  /// spill is a bar that changes colour with the case behind it. The light
  /// runs up to the bar and stops.
  final double navInset;

  /// What the light is composited over. Defaults to [GiColors.surface].
  ///
  /// Heute passes black: there the light falls on letterbox bars, and a bar is
  /// the absence of a picture rather than a surface of the app.
  final Color? ground;

  /// How wide the ambient source is decoded. Deliberately tiny: everything
  /// above roughly 64px is detail that the blur is about to destroy anyway.
  static const int sourceWidth = 48;

  /// What is left to do after the upscale. Small, because the upscale did the
  /// work.
  static const double blurSigma = 24;

  /// Section 4's own argument, applied to a ground rather than a bar: a blur
  /// desaturates, and light that has lost its colour reads as fog.
  ///
  /// Modest, and lower than any of the three materials. The first build ran
  /// this at 1.5 and the ground came back a saturated olive competing with the
  /// frame above it, which breaks section 1 rule 1: **the image is the only
  /// saturated thing on screen.** The light has to carry the image's hue, not
  /// its intensity.
  static const double saturation = 1.2;

  /// How far past the box the source is scaled, so the blur never reaches an
  /// edge of the texture and darkens it.
  static const double overscan = 1.4;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    // A placeholder is drawn, not photographed. There is no light to spill,
    // and inventing some would be decoration standing in for content.
    if (image.isPlaceholder) {
      return ColoredBox(color: ground ?? colors.surface);
    }

    final blurEnabled = MaterialQuality.blurOf(context);
    final isDark = colors.brightness == Brightness.dark;

    Widget light = Transform.scale(
      scale: overscan,
      child: Image.asset(
        image.assetPath,
        cacheWidth: sourceWidth,
        fit: BoxFit.cover,
        // The upscale is the blur. Bilinear on a 48px source across a phone
        // screen is a smooth field on its own.
        filterQuality: FilterQuality.high,
        // No error state and no placeholder state. If the asset is missing the
        // image field above says so in orange; the ground saying it twice
        // would be the screen shouting.
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );

    if (blurEnabled) {
      light = ImageFiltered(
        imageFilter: ui.ImageFilter.compose(
          outer: GiMaterial.saturate(saturation),
          inner: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
            // Decal, so the blur samples transparency past the texture rather
            // than smearing its edge pixels outward into a streak.
            tileMode: TileMode.decal,
          ),
        ),
        child: light,
      );
    }

    return IgnorePointer(
      child: ColoredBox(
        color: ground ?? colors.surface,
        // Static: it does not move when the card scrolls and it does not
        // rebuild when the text does, so it rasterises once and is then free.
        child: RepaintBoundary(
          child: ClipRect(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // **It gets stronger downward, and dies at the bar.**
                //
                // The spill is weakest where it meets the picture and heaviest
                // at the foot of the screen. That is the way round it has to
                // be: light next to the frame competes with the frame, and
                // light under the text is what stops the reading end of the
                // card from being a black hole. It stops dead at [navInset],
                // because the tab bar is a material and a bar carrying the
                // brightest part of a colour spill is a bar that changes
                // colour with the case behind it.
                //
                // **Half strength at its strongest, and a fifth in light.**
                // The first build ran this at full alpha and the card read as
                // glowing rather than as lit: a ground as saturated as the
                // endoscopic frame above it, the tint on *Fall öffnen* sitting
                // on red. Light spills off a photograph at a fraction of the
                // photograph.
                //
                // The two appearances need different numbers because the
                // arithmetic is not the same in both. On black, compositing
                // the frame *adds*, and the result is light. On white it
                // *subtracts*, and the same alpha does not read as light at
                // all, it reads as a stain on the paper. Light gets a wash.
                colors: isDark
                    ? const [
                        Color(0x59FFFFFF),
                        Color(0x80FFFFFF),
                        Color(0xB3FFFFFF),
                        Color(0x00FFFFFF),
                      ]
                    : const [
                        Color(0x33FFFFFF),
                        Color(0x47FFFFFF),
                        Color(0x66FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                stops: [0, .55, (1 - navInset).clamp(.6, 1.0), 1],
              ).createShader(rect),
              child: SizedBox.expand(child: light),
            ),
          ),
        ),
      ),
    );
  }
}
