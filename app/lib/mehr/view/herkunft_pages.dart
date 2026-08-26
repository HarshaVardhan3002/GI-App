import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/mehr/mehr.dart';
import 'package:url_launcher/url_launcher.dart';

/// {@template bildquellen_page}
/// Every dataset the images in this build came from, once each.
///
/// Constraint 1 puts attribution on the case itself. This screen is the other
/// half of it: **the whole set at once**, so a reader can see what the app is
/// built on without opening cases one at a time until they have seen them all.
/// {@endtemplate}
class BildquellenPage extends StatelessWidget {
  /// {@macro bildquellen_page}
  const BildquellenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;
    final cases = context.read<CaseSource>().cases;

    // One entry per dataset, not per image: a set of thirty images from one
    // dataset is one credit, and printing it thirty times would bury the
    // second dataset.
    final bySource = <String, GiImage>{};
    for (final giCase in cases) {
      for (final image in giCase.images) {
        bySource.putIfAbsent(image.source, () => image);
      }
    }

    return MehrScaffold(
      title: l10n.imageSourcesRowText,
      backLabel: l10n.moreNavBarItemLabel,
      children: [
        for (final image in bySource.values) ...[
          // A placeholder's `source` is a schema sentinel, not a dataset name,
          // and neither it nor its licence field should be printed at a reader
          // in a German screen. What is true about a placeholder is who made
          // it and that it is one.
          GiGroupHeader(
            image.isPlaceholder ? l10n.placeholderImageLabelText : image.source,
          ),
          GiGroup(
            children: [
              if (!image.isPlaceholder)
                GiRow(
                  label: l10n.licenceLabelText,
                  value: image.licenceSpdx,
                  labelColor: colors.labelSecondary,
                ),
              GiRow(
                label: l10n.rightsLabelText,
                value: image.licenceHolder,
                labelColor: colors.labelSecondary,
              ),
              GiRow(
                label: image.attributionText,
                labelStyle: GiText.footnote.copyWith(
                  color: image.isRightsCleared
                      ? colors.labelTertiary
                      : colors.warning,
                ),
              ),
              // An uncleared image's sourceUrl is a filler value like a
              // placeholder's, so the same rule covers both.
              if (image.isRightsCleared)
                GiRow(
                  label: l10n.sourceText,
                  labelColor: colors.tint,
                  onTap: () => openExternal(image.sourceUrl),
                  trailing: Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: colors.labelTertiary,
                  ),
                ),
            ],
          ),
          const Gap.v(AppSpacing.lg),
        ],
      ],
    );
  }
}

/// {@template leitlinien_page}
/// The guidelines this build quotes, and their rights position.
///
/// **The rights note is printed in full and never summarised.** Constraint 2
/// is a legal position rather than a design one, and a paraphrase of a rights
/// note is how you end up misstating one.
/// {@endtemplate}
class LeitlinienPage extends StatelessWidget {
  /// {@macro leitlinien_page}
  const LeitlinienPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;
    final cases = context.read<CaseSource>().cases;

    final byRegister = <String, GiGuideline>{};
    for (final giCase in cases) {
      byRegister.putIfAbsent(
        giCase.guideline.awmfRegisterNumber,
        () => giCase.guideline,
      );
    }

    return MehrScaffold(
      title: l10n.guidelinesRightsRowText,
      backLabel: l10n.moreNavBarItemLabel,
      children: [
        for (final guideline in byRegister.values) ...[
          // Same reason as the image sources: `000-000` is a schema filler,
          // not a register number, and it should not be printed as though it
          // were one.
          GiGroupHeader(
            guideline.isPlaceholder
                ? l10n.placeholderImageLabelText
                : guideline.awmfRegisterNumber,
          ),
          GiGroup(
            children: [
              GiRow(
                label: guideline.title,
                labelStyle: GiText.body.copyWith(color: colors.label),
              ),
              GiRow(
                label: guideline.publisher,
                labelStyle: GiText.subhead.copyWith(
                  color: colors.labelSecondary,
                ),
              ),
              GiRow(
                label: guideline.level,
                value: guideline.version,
                labelColor: colors.labelSecondary,
              ),
              GiRow(
                label: guideline.rightsNote,
                labelStyle: GiText.footnote.copyWith(
                  color: colors.labelTertiary,
                ),
              ),
              // A placeholder guideline has no URL that resolves, and a row
              // offering to open one would be the screen lying about what it
              // has.
              if (!guideline.isPlaceholder)
                GiRow(
                  label: l10n.openGuidelineText,
                  labelColor: colors.tint,
                  onTap: () => openExternal(guideline.url),
                  trailing: Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: colors.labelTertiary,
                  ),
                ),
            ],
          ),
          if (!guideline.isPlaceholder) MehrNote(l10n.leavesAppNoticeText),
          const Gap.v(AppSpacing.lg),
        ],
      ],
    );
  }
}

/// {@template ueber_page}
/// What this app is.
///
/// One paragraph of description that is true today, and one notice saying the
/// rest is not written. **Content is provisional** and this page is one of the
/// places physicians and teammates will rewrite; a page of confident marketing
/// copy nobody has reviewed would be worse than an empty one.
/// {@endtemplate}
class UeberPage extends StatelessWidget {
  /// {@macro ueber_page}
  const UeberPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;

    return MehrScaffold(
      title: l10n.aboutAppRowText,
      backLabel: l10n.moreNavBarItemLabel,
      children: [
        GiGroup(
          children: [
            GiRow(
              label: l10n.aboutAppBodyText,
              labelStyle: GiText.body.copyWith(color: colors.label),
            ),
          ],
        ),
        const Gap.v(AppSpacing.lg),
        GiGroup(
          background: colors.warning.withValues(alpha: .14),
          children: [
            GiRow(
              label: l10n.contentPendingNoticeText,
              labelStyle: GiText.footnote.copyWith(color: colors.warning),
            ),
          ],
        ),
      ],
    );
  }
}

/// {@template impressum_page}
/// The imprint.
///
/// **Left undone on purpose, and named as undone.** A German product published
/// to an app store is legally required to carry one, and its contents are a
/// company name, an address and a responsible person - facts that are not on
/// this machine and cannot honestly be invented. The screen exists, it is
/// reachable, and it says exactly what is missing.
/// {@endtemplate}
class ImpressumPage extends StatelessWidget {
  /// {@macro impressum_page}
  const ImpressumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;

    return MehrScaffold(
      title: l10n.imprintRowText,
      backLabel: l10n.moreNavBarItemLabel,
      children: [
        GiGroup(
          background: colors.warning.withValues(alpha: .14),
          children: [
            GiRow(
              label: l10n.imprintPendingNoticeText,
              labelStyle: GiText.footnote.copyWith(color: colors.warning),
            ),
          ],
        ),
      ],
    );
  }
}

/// Opens a URL outside the app. The row that calls this says so first.
Future<void> openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
