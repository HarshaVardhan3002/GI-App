import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/heute/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:intl/intl.dart';

/// {@template tageskarte}
/// One case, one screen.
///
/// **The image is top-anchored and the text block is bottom-anchored, and
/// neither knows the other exists.** That is what makes overlap structurally
/// impossible rather than something to check by eye: anchored to opposite
/// edges, neither can push the other off screen. Where they meet, they meet
/// inside the dissolve.
///
/// The arithmetic is in `docs/SCREENS.md`. Worst case is 96dp of overlap on a
/// 360x640, against a [dissolveHeight] of 150. **That makes the dissolve the
/// collision-absorption mechanism rather than decoration**, and shortening it
/// below 96 breaks the smallest device we target.
/// {@endtemplate}
class Tageskarte extends StatelessWidget {
  /// {@macro tageskarte}
  const Tageskarte({required this.giCase, required this.isLast, super.key});

  /// The case this card is for.
  final GiCase giCase;

  /// Whether another case sits below this one. Drives the peek.
  final bool isLast;

  /// The image never gets cropped by layout, so its height follows its width.
  static const double imageAspect = 1.25;

  /// See the class doc: this number is a constraint, not a taste.
  static const double dissolveHeight = 150;

  /// How much of the next card shows above the bottom bar.
  static const double peekHeight = 10;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = width * imageAspect;

    return ColoredBox(
      color: context.gi.surface,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: TageskarteImages(images: giCase.images),
          ),
          // The image does not end, it stops being the image. No hairline, no
          // edge, nothing to notice.
          Positioned(
            top: imageHeight - dissolveHeight,
            left: 0,
            right: 0,
            height: dissolveHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.gi.surface.withValues(alpha: 0),
                    context.gi.surface,
                  ],
                  // Weighted late so the fade reads as the image dissolving
                  // rather than as a grey band laid over it.
                  stops: const [0, .85],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: peekHeight + AppSpacing.lg,
            child: TageskarteText(giCase: giCase),
          ),
          if (!isLast)
            const Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: 0,
              height: peekHeight,
              child: TageskartePeek(),
            ),
        ],
      ),
    );
  }
}

/// {@template tageskarte_text}
/// Everything under the image, as one bottom-anchored block.
///
/// Its height is **bounded**, because the question is capped at two lines. An
/// uncapped headline would make the block unbounded and collision undecidable
/// at design time, which is why the cap is a layout decision rather than a
/// typographic one.
/// {@endtemplate}
class TageskarteText extends StatelessWidget {
  /// {@macro tageskarte_text}
  const TageskarteText({required this.giCase, super.key});

  /// The case being described.
  final GiCase giCase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final colors = context.gi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (giCase.images.length > 1) ...[
          TageskarteDots(count: giCase.images.length),
          const Gap.v(AppSpacing.md),
        ],
        Text(
          '${_formatDate(context, giCase.date)} · '
          '${_questionTypeLabel(l10n, giCase.questionType)}',
          style: GiText.caption.copyWith(color: colors.labelSecondary),
        ),
        const Gap.v(AppSpacing.sm),
        Text(
          giCase.question(languageCode),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GiText.question.copyWith(color: colors.label),
        ),
        const Gap.v(AppSpacing.lg),
        FallOeffnen(postId: giCase.post.id),
        const Gap.v(AppSpacing.md),
        // Attribution is the block's last line rather than the image's edge.
        // On a 360x640 the text block sits exactly where the image ends, so the
        // two would have collided; here it cannot, and it is still directly
        // beneath the image and still unambiguously about it.
        Text(
          giCase.images.first.attributionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GiText.footnote.copyWith(
            color: giCase.isPlaceholder ? colors.warning : colors.labelTertiary,
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
