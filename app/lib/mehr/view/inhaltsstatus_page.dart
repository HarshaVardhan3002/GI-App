import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/mehr/mehr.dart';

/// {@template inhaltsstatus_page}
/// What is in the content set, including what a reader never sees.
///
/// **This is the constraint made inspectable.** The product claims that only
/// approved content renders and that placeholders are always marked. A claim
/// nobody can check is worth nothing, so the counts are here: how many cases
/// were approved, how many are still drafts, how many were rejected, and how
/// much of the set is still standing in for the real thing.
///
/// The placeholder counts carry `warning` because that is what they are. A
/// prototype where every image is a stand-in should say so on the screen built
/// for saying so.
/// {@endtemplate}
class InhaltsstatusPage extends StatelessWidget {
  /// {@macro inhaltsstatus_page}
  const InhaltsstatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;
    final status = context.read<CaseSource>().contentStatus;

    return MehrScaffold(
      title: l10n.contentStatusRowText,
      backLabel: l10n.moreNavBarItemLabel,
      children: [
        GiGroupHeader(l10n.releaseGroupHeaderText),
        GiGroup(
          children: [
            // The only count on this screen that is good news, and the only
            // one in `correct`.
            GiRow(
              label: l10n.approvedRowText,
              labelColor: colors.labelSecondary,
              trailing: Text(
                '${status.approvedCount}',
                style: GiText.body.copyWith(color: colors.correct),
              ),
            ),
            GiRow(
              label: l10n.draftRowText,
              value: '${status.draftCount}',
              labelColor: colors.labelSecondary,
            ),
            GiRow(
              label: l10n.rejectedRowText,
              value: '${status.rejectedCount}',
              labelColor: colors.labelSecondary,
            ),
          ],
        ),
        const Gap.v(AppSpacing.lg),
        GiGroupHeader(l10n.placeholderGroupHeaderText),
        GiGroup(
          children: [
            _PlaceholderRow(
              label: l10n.imagesRowText,
              part: status.placeholderImageCount,
              total: status.imageCount,
            ),
            _PlaceholderRow(
              label: l10n.recommendationsRowText,
              part: status.placeholderRecommendationCount,
              total: status.recommendationCount,
            ),
            // Wider than the placeholder count and deliberately so: a set can
            // hold no placeholders at all and still hold photographs nobody
            // has cleared the rights to.
            _PlaceholderRow(
              label: l10n.unclearedRightsRowText,
              part: status.unclearedImageCount,
              total: status.imageCount,
            ),
          ],
        ),
        MehrNote(l10n.contentStatusNoteText),
      ],
    );
  }
}

/// A row whose value goes orange when anything is still a stand-in.
class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({
    required this.label,
    required this.part,
    required this.total,
  });

  final String label;
  final int part;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    return GiRow(
      label: label,
      labelColor: colors.labelSecondary,
      trailing: Text(
        context.l10n.outOfText(part, total),
        style: GiText.body.copyWith(
          color: part == 0 ? colors.labelSecondary : colors.warning,
        ),
      ),
    );
  }
}
