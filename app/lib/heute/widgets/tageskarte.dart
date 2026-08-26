import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/heute/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:intl/intl.dart';

/// {@template tageskarte}
/// One case, one screen.
///
/// **The image field takes what the text block leaves, and overlap is
/// structurally impossible rather than arithmetically survivable.**
///
/// The card was a Stack with the image pinned to the top at a
/// fixed 1.25 aspect and the text pinned to the bottom, and `docs/SCREENS.md`
/// carries the collision arithmetic that made that safe. It was only ever safe
/// for one image shape: a 1356x520 strip left two thirds of the screen as dead
/// black, and a tall portrait would have eaten the question.
///
/// It is a Column now. The text block takes its natural height, the image
/// field takes everything else, and the two cannot reach each other because
/// they are siblings rather than layers. The dissolve stops being a
/// collision-absorption mechanism and becomes what it looks like: the bottom
/// of the image dissolving into the ground.
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
  /// **It lives here rather than in the carousel** because the dots that
  /// report it live in the text block, which is the carousel's sibling. The
  /// first pass left it at a hardcoded zero, so the carousel moved and the
  /// dots said it had not.
  int _imageIndex = 0;

  /// How far the bottom of the image field dissolves into the ground.
  static const double dissolveHeight = 150;

  /// How much of the next card shows above the bottom bar.
  static const double peekHeight = 10;

  @override
  Widget build(BuildContext context) {
    // The tab bar is a material and the card runs underneath it, so the bar no
    // longer shortens the body. The text block and the peek have to clear it
    // themselves, or they render behind the labels.
    //
    // **The bar's height is already in here.** With `extendBody`, a Scaffold
    // reports `max(bar height, viewPadding.bottom)` as the body's bottom
    // padding precisely so a full-bleed body can do this. Adding
    // `BottomNavBar.barHeight` on top counted the bar twice and left the peek
    // floating 49dp above the bar.
    final barInset = MediaQuery.paddingOf(context).bottom;
    final giCase = widget.giCase;

    return ColoredBox(
      color: context.gi.surface,
      child: Column(
        children: [
          // **The image field takes everything the text does not.** It was a
          // fixed 1.25 aspect, which was true of exactly one image shape; a
          // 1356x520 strip left two thirds of the screen as dead black under
          // it. The field is now whatever is left, and the image is contained
          // inside it, so every aspect fills the same screen and none of them
          // is cropped, stretched, or floated in a hole.
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                TageskarteImages(
                  images: giCase.images,
                  onIndexChanged: (index) =>
                      setState(() => _imageIndex = index),
                ),
                // The image does not end, it stops being the image. No
                // hairline, no edge, nothing to notice.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
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
                        // Weighted late so the fade reads as the image
                        // dissolving rather than as a grey band laid over it.
                        stops: const [0, .85],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: TageskarteText(
              giCase: giCase,
              imageIndex: _imageIndex,
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
    );
  }
}

/// {@template tageskarte_text}
/// Everything under the image, as one bottom-anchored block.
///
/// Its height is **bounded**, because the question is one rolling line. An
/// uncapped headline would make the block unbounded and collision undecidable
/// at design time, which is why the cap is a layout decision rather than a
/// typographic one. It was two ellipsised lines; a rolling line is shorter, so
/// the block only ever gained clearance from the image.
/// {@endtemplate}
class TageskarteText extends StatelessWidget {
  /// {@macro tageskarte_text}
  const TageskarteText({
    required this.giCase,
    this.imageIndex = 0,
    super.key,
  });

  /// The case being described.
  final GiCase giCase;

  /// Which image the carousel above is showing.
  final int imageIndex;

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
          TageskarteDots(
            count: giCase.images.length,
            active: imageIndex,
          ),
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
        // Attribution is the block's last line rather than the image's edge.
        // On a 360x640 the text block sits exactly where the image ends, so the
        // two would have collided; here it cannot, and it is still directly
        // beneath the image and still unambiguously about it.
        Text(
          giCase.images.first.attributionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GiText.footnote.copyWith(
            // Orange whenever the reader is owed a warning about what they are
            // looking at: a stand-in, or a real photograph whose rights are
            // not cleared. Both are things this app must never let pass as
            // ordinary content.
            color:
                giCase.isPlaceholder ||
                    !giCase.images.first.isRightsCleared
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
