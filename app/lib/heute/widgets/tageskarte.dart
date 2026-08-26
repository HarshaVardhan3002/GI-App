import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/heute/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/media/media.dart';
import 'package:intl/intl.dart';

/// {@template tageskarte}
/// One case, one screen.
///
/// **The card is shaped by the image it is carrying, and the space the image
/// does not want is lit by the image rather than left black.**
///
/// Two earlier passes were wrong in the same way. The first pinned the image to
/// a fixed 1.25 aspect, which was true of exactly one image shape. The second
/// gave the image everything the text left and contained it inside that, which
/// stopped the cropping but produced the real defect: a 1356x520 strip floating
/// in the middle of a black field, the same rectangle of chrome whatever the
/// case was. **A layout that ignores its content has decided its content does
/// not matter.**
///
/// Now the image field is [GiImage.aspectRatio] tall at full width, bounded at
/// both ends so no shape can starve the question or shrink itself to a stamp,
/// and anchored to the top so the image runs full bleed under the wordmark.
/// Everything it leaves is [GiAmbient]: the image itself, decoded small, scaled
/// up and blurred past recognition. The text reads off a pane of the Ultradünn
/// material laid over that light.
/// {@endtemplate}
class Tageskarte extends StatefulWidget {
  /// {@macro tageskarte}
  const Tageskarte({required this.giCase, required this.isLast, super.key});

  /// The case this card is for.
  final GiCase giCase;

  /// Whether another case sits below this one. Drives the peek.
  final bool isLast;

  @override
  State<Tageskarte> createState() => _TageskarteState();
}

class _TageskarteState extends State<Tageskarte> {
  /// Which image the carousel is on.
  ///
  /// **It lives here rather than in the carousel** because two siblings report
  /// it: the dots in the text block, and the ambient light behind everything.
  /// The first pass left it at a hardcoded zero, so the carousel moved and the
  /// dots said it had not.
  int _imageIndex = 0;

  /// How much of the next card shows above the bottom bar.
  static const double peekHeight = 10;

  /// The tallest the image field may be, as a fraction of the card.
  ///
  /// A 527x675 portrait wants 128% of the screen at full width. Letting it have
  /// that would push the question off the bottom, so it is capped and contained
  /// inside the cap: pillarboxed by a few dp each side, with the ambient
  /// showing in the margin, which is the shape a portrait frame should make.
  static const double maxFieldFraction = .62;

  /// The shortest it may be. A 2.6:1 strip wants 38% of a phone screen and
  /// reads as a postage stamp at that size. Below this the field keeps its
  /// height and the strip is contained inside it, letting the light through
  /// above and below.
  static const double minFieldFraction = .34;

  /// How far the bottom edge of the image feathers into its own light.
  ///
  /// Short on purpose. **This is the one place in the app where image pixels
  /// are deliberately hidden**, and the only reason it is defensible is that an
  /// endoscopic frame's bottom edge is the dark periphery of the lumen rather
  /// than the finding, and that Fall shows the same image whole and
  /// unfeathered. This is the card's teaser, not the record.
  static const double bleedExtent = 32;

  @override
  Widget build(BuildContext context) {
    // The tab bar is a material and the card runs underneath it, so the bar no
    // longer shortens the body. The text block and the peek have to clear it
    // themselves, or they render behind the labels.
    //
    // **The bar's height is already in here.** With `extendBody`, a Scaffold
    // reports `max(bar height, viewPadding.bottom)` as the body's bottom
    // padding precisely so a full-bleed body can do this.
    final barInset = MediaQuery.paddingOf(context).bottom;
    final giCase = widget.giCase;
    final index = _imageIndex.clamp(0, giCase.images.length - 1);
    final image = giCase.images[index];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final aspect = image.aspectRatio > 0 ? image.aspectRatio : 1.25;
        final field = (constraints.maxWidth / aspect).clamp(
          cardHeight * minFieldFraction,
          cardHeight * maxFieldFraction,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // The ground, lit by the frame it carries. Behind everything, the
            // pane included, which is the point of the pane being thin.
            GiAmbient(
              image: image,
              focusEnd: (field / cardHeight).clamp(0.0, 1.0),
            ),
            // **No scroll view here, on purpose.** The first attempt at this
            // put one in so an enlarged text scale could not overflow, and it
            // handed the Column unbounded height, which is a contradiction
            // with the [Expanded] below it and rendered nothing at all. It was
            // also solving a problem the Expanded already solves: when the
            // text block grows, the image field is what yields. The card gives
            // way at the image rather than at the question, which is the right
            // order for this screen.
            //
            // A second scrollable inside the vertical pager would also have
            // taken the drag off it.
            Column(
              children: [
                // Takes what the text leaves, and inside that sits at the
                // image's own height, anchored to the top. Full bleed to
                // the top of the screen: the wordmark is a material
                // floating over the image, not a bar above it.
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _BleedingField(
                      height: field,
                      child: TageskarteImages(
                        images: giCase.images,
                        onIndexChanged: (i) => setState(() => _imageIndex = i),
                      ),
                    ),
                  ),
                ),
                GiThinMaterial(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: TageskarteText(giCase: giCase, imageIndex: index),
                  ),
                ),
                if (!widget.isLast)
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                      bottom: barInset,
                    ),
                    child: const SizedBox(
                      height: peekHeight,
                      child: TageskartePeek(),
                    ),
                  )
                else
                  SizedBox(height: barInset + peekHeight),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// {@template bleeding_field}
/// The image field, feathered at the bottom so the frame ends in its own light
/// rather than at a cut.
///
/// The mask is `dstIn` over the whole field, so what shows through the last
/// few dp is the ambient behind it, at exactly the colours that edge of the
/// image was. That is what makes it read as bleeding rather than as a gradient
/// laid on top of it.
/// {@endtemplate}
class _BleedingField extends StatelessWidget {
  const _BleedingField({required this.height, required this.child});

  /// The field's laid-out height.
  final double height;

  /// The carousel.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const bleed = _TageskarteState.bleedExtent;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          // Read off the painted rect rather than assumed, for the same reason
          // `GiMaterial` does: the feather is a fixed number of dp whatever
          // height the field ended up at.
          final start = rect.height <= bleed
              ? 0.0
              : (rect.height - bleed) / rect.height;
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.white, Colors.white, Colors.transparent],
            stops: [0, start, 1],
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

/// {@template tageskarte_text}
/// Everything under the image, as one block on a pane.
///
/// Its height is **bounded**, because the question is one rolling line. An
/// uncapped headline would make the block unbounded and the card's shape
/// undecidable at design time, which is why the cap is a layout decision rather
/// than a typographic one.
/// {@endtemplate}
class TageskarteText extends StatelessWidget {
  /// {@macro tageskarte_text}
  const TageskarteText({required this.giCase, this.imageIndex = 0, super.key});

  /// The case being described.
  final GiCase giCase;

  /// Which image the carousel above is showing.
  final int imageIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final colors = context.gi;
    // The attribution belongs to the frame on screen, not to the first frame
    // of the set. A carousel whose images come from different datasets was
    // crediting all of them to whoever published image one.
    final image = giCase.images[imageIndex.clamp(0, giCase.images.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (giCase.images.length > 1) ...[
          TageskarteDots(count: giCase.images.length, active: imageIndex),
          const Gap.v(AppSpacing.md),
        ],
        Text(
          '${_formatDate(context, giCase.date)} · '
          '${_questionTypeLabel(l10n, giCase.questionType)}',
          style: GiText.caption.copyWith(color: colors.labelSecondary),
        ),
        const Gap.v(AppSpacing.sm),
        // One line that rolls, not two that stop at an ellipsis. German
        // clinical headings do not fit on a phone, and the reader should not
        // have to open the case to find out what the case is about. See
        // `GiRollingText`.
        GiRollingText(
          giCase.question(languageCode),
          style: GiText.question.copyWith(color: colors.label),
        ),
        const Gap.v(AppSpacing.lg),
        FallOeffnen(postId: giCase.post.id),
        const Gap.v(AppSpacing.md),
        Text(
          image.attributionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GiText.footnote.copyWith(
            // Orange whenever the reader is owed a warning about what they are
            // looking at: a stand-in, or a real photograph whose rights are not
            // cleared. Both are things this app must never let pass as ordinary
            // content.
            color: giCase.isPlaceholder || !image.isRightsCleared
                ? colors.warning
                : colors.labelTertiary,
          ),
        ),
      ],
    );
  }

  static String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d. MMMM', locale).format(date).toUpperCase();
  }

  static String _questionTypeLabel(AppLocalizations l10n, String type) =>
      switch (type) {
        'finding' => l10n.questionTypeFindingText,
        'diagnosis' => l10n.questionTypeDiagnosisText,
        'treatment' => l10n.questionTypeTreatmentText,
        // An unknown type is a content error, and printing it is how it gets
        // noticed rather than quietly rendering as nothing.
        _ => type.toUpperCase(),
      };
}
