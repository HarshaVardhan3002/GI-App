import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/fall/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';

/// {@template fall_reveal}
/// The answer, and what it traces to.
///
/// **No image.** The reader has answered; what is on trial now is the
/// reasoning and the recommendation behind it, and an image at the top would
/// be the screen still asking a question it has already settled.
///
/// The quote, the Konsensstärke and the citation are rows of **one** group.
/// Constraint 2 says guideline text is cited, never redistributed, and putting
/// the citation in the same group as the quote is how a later layout change is
/// stopped from separating them.
/// {@endtemplate}
class FallReveal extends StatelessWidget {
  /// {@macro fall_reveal}
  const FallReveal({
    required this.giCase,
    required this.selectedOptionId,
    super.key,
  });

  /// The case being revealed.
  final GiCase giCase;

  /// What the reader chose.
  final String selectedOptionId;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final recommendation = giCase.recommendation;

    // `where().firstOrNull` rather than `firstWhere(orElse:)`: `orElse`'s type
    // is read off the list's runtime element type, which makes it a trap for
    // any list handed across an interface. This does not care.
    final chosen = giCase.options
        .where((option) => option.id == selectedOptionId)
        .firstOrNull;
    final isCorrect = chosen?.isCorrect ?? false;

    return ColoredBox(
      color: colors.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top:
              MediaQuery.paddingOf(context).top +
              FallHeader.barHeight +
              AppSpacing.xlg,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xlg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FallVerdict(isCorrect: isCorrect),
            const Gap.v(AppSpacing.lg),
            GiGroupHeader(l10n.reasoningHeaderText),
            Text(
              giCase.explanation(languageCode),
              style: GiText.body.copyWith(color: colors.labelSecondary),
            ),
            const Gap.v(AppSpacing.xlg),
            GiGroupHeader(
              l10n.recommendationHeaderText(
                recommendation.number,
                recommendation.strength,
              ),
            ),
            GiGroup(
              children: [
                GiRow(
                  label: recommendation.quote,
                  labelStyle: GiText.quote.copyWith(color: colors.label),
                ),
                GiRow(
                  label: l10n.consensusLabelText,
                  value: recommendation.consensus,
                  labelColor: colors.labelSecondary,
                ),
                if (recommendation.levelOfEvidence.isNotEmpty)
                  GiRow(
                    label: l10n.evidenceLabelText,
                    value: recommendation.levelOfEvidence,
                    labelColor: colors.labelSecondary,
                  ),
                GiRow(
                  label: recommendation.citation,
                  labelStyle: GiText.footnote.copyWith(
                    color: colors.labelTertiary,
                  ),
                ),
                GiRow(
                  label: l10n.sourceText,
                  labelColor: colors.tint,
                  onTap: () => showHerkunftSheet(context, giCase: giCase),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colors.labelTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// {@template fall_verdict}
/// Right or wrong, on one line.
///
/// **One line, and then the screen moves on.** No score, no streak, no
/// animation that congratulates. Constraint 4 rules out gamification, and a
/// verdict that performs would make the reasoning underneath it feel like a
/// consolation prize.
/// {@endtemplate}
class FallVerdict extends StatelessWidget {
  /// {@macro fall_verdict}
  const FallVerdict({required this.isCorrect, super.key});

  /// Whether the chosen answer was the correct one.
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    final colour = isCorrect ? colors.correct : colors.incorrect;

    return Row(
      children: [
        Icon(
          isCorrect ? Icons.check_rounded : Icons.close_rounded,
          size: 22,
          color: colour,
        ),
        const Gap.h(AppSpacing.sm),
        Text(
          isCorrect
              ? context.l10n.verdictCorrectText
              : context.l10n.verdictIncorrectText,
          style: GiText.headline.copyWith(color: colour),
        ),
      ],
    );
  }
}
