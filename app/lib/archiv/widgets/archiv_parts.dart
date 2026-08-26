import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/app/routes/routes.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/media/media.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// {@template archiv_header}
/// The screen's name, and how much is in it.
///
/// The count is not decoration: a reader arriving here wants to know whether
/// there are twelve cases behind this or two hundred before they start
/// scrolling.
///
/// The title is Fira, not Newsreader. The screen mockups set it in the serif,
/// and `DESIGN.md` section 5 permits exactly three uses of that face - the
/// wordmark, the question and the guideline quote. A screen title is a fourth.
/// **A deliberate departure from the mockup, flagged rather than buried.**
/// {@endtemplate}
class ArchivHeader extends StatelessWidget {
  /// {@macro archiv_header}
  const ArchivHeader({required this.count, super.key});

  /// How many cases are on the sheet.
  final int count;

  /// The same 44dp as every other bar in the app.
  static const double barHeight = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    return IgnorePointer(
      child: GiMaterial(
        edge: VerticalDirection.up,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: barHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.archiveNavBarItemLabel,
                        style: GiText.headline.copyWith(color: colors.label),
                      ),
                      Text(
                        context.l10n.caseCountText(count),
                        style: GiText.subhead.copyWith(
                          color: colors.label.withValues(alpha: .55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: GiMaterial.fadeExtent),
          ],
        ),
      ),
    );
  }
}

/// {@template archiv_month_header}
/// Which month the cells under it belong to.
///
/// Pinned, so the reader always knows where they are in a sheet that has no
/// other landmarks. It sits on the ground colour rather than on a material:
/// it is part of the sheet, not chrome over it.
/// {@endtemplate}
class ArchivMonthHeader extends SliverPersistentHeaderDelegate {
  /// {@macro archiv_month_header}
  const ArchivMonthHeader({required this.label});

  /// `August 2026`.
  final String label;

  /// Enough for a caption line and the air around it.
  static const double height = 40;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = context.gi;
    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm + 2,
          bottom: AppSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            label.toUpperCase(),
            style: GiText.caption.copyWith(
              color: colors.labelTertiary,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(ArchivMonthHeader oldDelegate) =>
      oldDelegate.label != label;
}

/// {@template archiv_cell}
/// One case on the sheet: its image, its day, and whether it has been
/// answered.
///
/// **The dot marks answered, and it only claims correctness when it is
/// earned.** `docs/SCREENS.md` specifies a `correct`-coloured dot on every
/// answered case, which would put a green mark on a case the reader got wrong.
/// In a product about clinical reasoning that is not a small inaccuracy. A
/// wrongly answered case is marked in [GiColors.labelTertiary] instead:
/// present, unmistakably not green, and not a red scoreboard either -
/// constraint 4 rules out gamification, and a grid of failures is exactly
/// that. **A deliberate departure, flagged for review.**
/// {@endtemplate}
class ArchivCell extends StatelessWidget {
  /// {@macro archiv_cell}
  const ArchivCell({required this.giCase, super.key});

  /// The case this cell is for.
  final GiCase giCase;

  /// How far up the scrim under the date reaches.
  static const double scrimHeight = 36;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    // `AnswerSource` is provided as a plain value, so `context.watch` would
    // read it without ever hearing it change. It is a Listenable for exactly
    // this: answering a case marks its cell without the sheet being rebuilt.
    final answers = context.read<AnswerSource>();
    final isDark = colors.brightness == Brightness.dark;
    final scrimColor = isDark ? Colors.black : Colors.white;
    final dateColor = isDark ? Colors.white : colors.label;

    return Tappable.scaled(
      backgroundColor: Colors.transparent,
      onTap: () {
        GiHaptics.selection(context);
        context.pushNamed(
          AppRoutes.post.name,
          pathParameters: {'id': giCase.post.id},
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The cell has a ground of its own. Images are contained rather
            // than cropped, so a 1356x520 strip fills a fraction of a 4:5
            // cell; without a ground the rest of the cell is the page and the
            // cell stops reading as a cell - the answered dot in particular
            // ends up floating in what looks like empty page.
            ColoredBox(color: colors.depth(.30)),
            GiImageView(image: giCase.images.first),
            // The date has to stay legible over any image, and section 11
            // rules out a cast shadow. A scrim is the same job done as a
            // surface rather than as an effect.
            // **The scrim follows the appearance, and it used to not.** A
            // black scrim under white text is right over a photograph in the
            // dark appearance and reads as a grey slab across the bottom of
            // every cell in the light one, where the cell above it is nearly
            // white. It is the ground's own extreme in each appearance, so the
            // band belongs to the cell rather than being laid over it.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: scrimHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scrimColor.withValues(alpha: 0),
                      scrimColor.withValues(alpha: .70),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              bottom: AppSpacing.xs,
              child: Text(
                DateFormat('d. MMM').format(giCase.date),
                style: GiText.caption.copyWith(color: dateColor),
              ),
            ),
            // `Positioned` has to be the Stack's direct child, so the
            // rebuild happens inside it rather than around it.
            Positioned(
              right: AppSpacing.sm,
              top: AppSpacing.sm,
              child: ListenableBuilder(
                listenable: answers,
                builder: (context, _) {
                  final answer = answers.answerOf(giCase.post.id);
                  if (answer == null) return const SizedBox.shrink();
                  return SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: answer.isCorrect
                            ? colors.correct
                            : colors.labelTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
