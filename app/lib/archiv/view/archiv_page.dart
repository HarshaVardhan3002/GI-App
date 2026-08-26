import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/archiv/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:intl/intl.dart';

/// {@template archiv_page}
/// Every case that has been released, as a contact sheet.
///
/// **A contact sheet, not a list.** These are images, and a physician scanning
/// for the one they half remember is looking for a shape and a colour, not for
/// a row of dates with thumbnails beside them. Two columns at 4:5 with 2dp
/// between them puts as much image on screen as the format allows.
/// {@endtemplate}
class ArchivPage extends StatelessWidget {
  /// {@macro archiv_page}
  const ArchivPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.read<CaseSource>().cases;

    return AppScaffold(
      top: false,
      bottom: false,
      body: cases.isEmpty
          ? const ArchivEmpty()
          : ArchivView(cases: cases),
    );
  }
}

/// {@template archiv_view}
/// The sheet itself, one pinned header per month.
/// {@endtemplate}
class ArchivView extends StatelessWidget {
  /// {@macro archiv_view}
  const ArchivView({required this.cases, super.key});

  /// Newest first, as [CaseSource] gives them.
  final List<GiCase> cases;

  /// `DESIGN.md` section 6's smallest unit, used as the gutter. Anything wider
  /// starts to read as a grid of cards rather than as a sheet of film.
  static const double gutter = 2;

  @override
  Widget build(BuildContext context) {
    final months = _byMonth(cases);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // The bar floats over the sheet, so the sheet starts underneath it.
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    MediaQuery.paddingOf(context).top + ArchivHeader.barHeight,
              ),
            ),
            for (final month in months) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: ArchivMonthHeader(label: month.label),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: gutter,
                        crossAxisSpacing: gutter,
                        childAspectRatio: 4 / 5,
                      ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ArchivCell(giCase: month.cases[index]),
                    childCount: month.cases.length,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    MediaQuery.paddingOf(context).bottom + AppSpacing.xlg,
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ArchivHeader(count: cases.length),
        ),
      ],
    );
  }

  /// Groups cases into months, keeping the order they arrived in.
  ///
  /// Not sorted here: **the order is the publisher's**, and re-sorting in the
  /// UI would hide a content set that arrived in the wrong order rather than
  /// showing it.
  static List<_Month> _byMonth(List<GiCase> cases) {
    final months = <String, List<GiCase>>{};
    for (final giCase in cases) {
      final key = '${giCase.date.year}-${giCase.date.month}';
      (months[key] ??= []).add(giCase);
    }
    return [
      for (final entry in months.entries)
        _Month(first: entry.value.first.date, cases: entry.value),
    ];
  }
}

class _Month {
  const _Month({required this.first, required this.cases});

  final DateTime first;
  final List<GiCase> cases;

  String get label => DateFormat('MMMM yyyy').format(first);
}

/// {@template archiv_empty}
/// Nothing has been released.
/// {@endtemplate}
class ArchivEmpty extends StatelessWidget {
  /// {@macro archiv_empty}
  const ArchivEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
        child: Text(
          context.l10n.archiveEmptyText,
          textAlign: TextAlign.center,
          style: GiText.subhead.copyWith(color: context.gi.labelSecondary),
        ),
      ),
    );
  }
}
