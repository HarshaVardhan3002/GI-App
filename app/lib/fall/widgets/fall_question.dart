import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/media/media.dart';
import 'package:intl/intl.dart';

/// {@template fall_question}
/// The case before it is answered.
///
/// The image takes 40% of the screen rather than Heute's full 1.25 aspect,
/// **because this screen is for reading rather than for looking**. The reader
/// has already seen the image at its largest on the card; here it is context
/// for a question, and the question is what has to fit.
/// {@endtemplate}
class FallQuestion extends StatelessWidget {
  /// {@macro fall_question}
  const FallQuestion({
    required this.giCase,
    required this.selectedOptionId,
    required this.onSelect,
    required this.onConfirm,
    super.key,
  });

  /// The case being answered.
  final GiCase giCase;

  /// Which option is chosen, or null before one is.
  final String? selectedOptionId;

  /// Called with an option's id when a row is pressed.
  final ValueSetter<String> onSelect;

  /// Called when the reader commits to their answer.
  final VoidCallback onConfirm;

  /// Section 8's proportion for this screen.
  static const double imageFraction = .40;

  /// Shorter than Heute's 150: less image to dissolve into, and the content
  /// below it starts sooner.
  static const double dissolveHeight = 96;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    final size = MediaQuery.sizeOf(context);
    final imageHeight = size.height * imageFraction;
    final languageCode = Localizations.localeOf(context).languageCode;

    return ColoredBox(
      color: colors.surface,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: GiImageView(image: giCase.images.first),
          ),
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
                    colors.surface.withValues(alpha: 0),
                    colors.surface,
                  ],
                  stops: const [0, .84],
                ),
              ),
            ),
          ),
          // The content scrolls and the button scrolls with it. A button
          // pinned to the bottom would sit over the last answer on a short
          // screen, and there is nothing here that has to stay reachable while
          // the reader is still reading the options.
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: imageHeight,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xlg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatDate(context, giCase.date)} · '
                    '${_questionTypeLabel(context.l10n, giCase.questionType)}',
                    style: GiText.caption.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
                  const Gap.v(AppSpacing.sm),
                  Text(
                    giCase.question(languageCode),
                    style: GiText.question.copyWith(color: colors.label),
                  ),
                  const Gap.v(AppSpacing.xlg),
                  GiGroup(
                    children: [
                      for (final option in giCase.options)
                        GiRow(
                          label: option.text(languageCode),
                          isSelected: option.id == selectedOptionId,
                          onTap: () => onSelect(option.id),
                          trailing: option.id == selectedOptionId
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: colors.tint,
                                )
                              : null,
                        ),
                    ],
                  ),
                  const Gap.v(AppSpacing.lg),
                  FallConfirmButton(
                    isEnabled: selectedOptionId != null,
                    onTap: onConfirm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        _ => type.toUpperCase(),
      };
}

/// {@template fall_confirm_button}
/// *Antwort bestätigen*. The one tinted action on this screen.
///
/// **Disabled until an answer is chosen, and it says so by going quiet rather
/// than by refusing.** A tinted button that does nothing when pressed teaches
/// the reader to distrust tint, and tint is the only signal this app has for
/// what to do next.
/// {@endtemplate}
class FallConfirmButton extends StatelessWidget {
  /// {@macro fall_confirm_button}
  const FallConfirmButton({
    required this.isEnabled,
    required this.onTap,
    super.key,
  });

  /// Whether an answer has been chosen.
  final bool isEnabled;

  /// Commits the answer.
  final VoidCallback onTap;

  /// Section 6: buttons.
  static const double radius = 14;

  /// Section 6: the same height as an answer row, so the button reads as the
  /// end of the group rather than as a different kind of thing.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    return Tappable.scaled(
      onTap: isEnabled ? onTap : null,
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEnabled ? colors.tint : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Center(
            child: Text(
              context.l10n.confirmAnswerText,
              style: GiText.headline.copyWith(
                // White on the tint in both appearances: the tint is a
                // saturated blue in each, and the label colour would vanish
                // into it in the light one.
                color: isEnabled ? Colors.white : colors.labelTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
