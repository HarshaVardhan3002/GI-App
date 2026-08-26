import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';

/// {@template gi_image_view}
/// One [GiImage], wherever a case shows one.
///
/// Three states, and the widget picks between them rather than the caller:
/// a real image, a stand-in for one that does not exist yet, and an image that
/// failed to load. Heute and Fall both use this, so an image cannot look like
/// one thing on the card and another on the case.
/// {@endtemplate}
class GiImageView extends StatelessWidget {
  /// {@macro gi_image_view}
  const GiImageView({required this.image, super.key});

  /// The image to show.
  final GiImage image;

  @override
  Widget build(BuildContext context) {
    if (image.isPlaceholder) return GiImagePlaceholder(image: image);

    return Image.asset(
      image.assetPath,
      // **`contain`, never `cover`.** An endoscopic image arrives at whatever
      // shape the scope and the publication left it in: a 1400x1081 frame, a
      // 1356x520 three-panel strip, a 527x675 portrait. `cover` fills the
      // frame by cutting whatever does not fit, and in an endoscopic image the
      // edge of the lumen is often the finding. Cropping it is a clinical
      // mistake dressed as a design one, and stretching it to fit is worse.
      //
      // **The frame is sized to this image**, so in the common case `contain`
      // has nothing to letterbox: Heute gives the field the image's own aspect
      // and Fall does the same. What space remains, when a shape is clamped,
      // shows `GiAmbient` rather than flat ramp.
      //
      // An earlier pass refused that on the grounds that a blurred backdrop
      // invents detail at the edge a reader is judging. It does not: the
      // ambient is decoded at 48px and blurred past any structure, so there is
      // no detail left in it to mistake for the image, and it never overlaps
      // the frame. Black around a frame is not neutrality, it is a second
      // design decision made by default.
      fit: BoxFit.contain,
      // The image is the content, so a failure to load it is worth seeing
      // rather than worth hiding behind an empty box.
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: context.gi.depth(.30),
        child: Center(
          child: Text(
            context.l10n.imageMissingText,
            textAlign: TextAlign.center,
            style: GiText.footnote.copyWith(color: context.gi.warning),
          ),
        ),
      ),
    );
  }
}

/// {@template gi_image_placeholder}
/// What stands where a real endoscopic image will go.
///
/// **Drawn, not shipped.** This was a set of baked `.webp` files, and their
/// colours (#1D1E22 ground, #C6CACF text, #B1783E accent) were on no stop of
/// the ramp - a flat neutral grey of exactly the kind `DESIGN.md` section 11
/// names as a wrongness tell. An asset cannot follow the appearance and cannot
/// be checked by anything but eye. A widget reads the ramp, so it is correct
/// in both appearances by construction and stays correct if a stop moves.
///
/// The word carries [GiColors.warning] because that is what orange is for
/// here: a reader is owed the knowledge that this is not a real case before
/// they read the question beside it.
/// {@endtemplate}
class GiImagePlaceholder extends StatelessWidget {
  /// {@macro gi_image_placeholder}
  const GiImagePlaceholder({required this.image, super.key});

  /// The image this stands in for. Its `className` names the finding the real
  /// image will show.
  final GiImage image;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    return ColoredBox(
      color: colors.depth(.30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A contact-sheet cell is roughly 170dp tall and the full notice
          // would not fit in it, let alone read. **The word alone is the part
          // that has to survive**: it is the one that tells a reader this is
          // not a real case.
          if (constraints.maxHeight < 220) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  context.l10n.placeholderImageLabelText,
                  textAlign: TextAlign.center,
                  style: GiText.caption.copyWith(
                    color: colors.warning,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xlg,
              ),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.placeholderImageLabelText,
                style: GiText.caption.copyWith(
                  color: colors.warning,
                  letterSpacing: 1.2,
                ),
              ),
              const Gap.v(AppSpacing.md),
              Text(
                context.l10n.placeholderImageBodyText,
                textAlign: TextAlign.center,
                style: GiText.subhead.copyWith(color: colors.labelSecondary),
              ),
                // `image.className` is not drawn here. It carries the
                // dataset's own label - `polyp`, `oesophagitis-a` - which is
                // an English developer token, and constraint 4 says the
                // interface is German. It stays on the model for the
                // provenance sheet, where it is quoted as the dataset's word
                // rather than presented as this app's.
              ],
            ),
          ),
        );
        },
      ),
    );
  }
}
