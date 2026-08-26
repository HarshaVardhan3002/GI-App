import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// {@template fall_header}
/// The way back, and the day this case belongs to.
///
/// The same Normal material as Heute's header, so the two screens feel like
/// one surface at different depths rather than two apps. The back control is
/// tinted because on a pushed screen the way back *is* the affordance the
/// reader looks for, and naming the destination rather than drawing an arrow
/// alone says where it goes.
/// {@endtemplate}
class FallHeader extends StatelessWidget {
  /// {@macro fall_header}
  const FallHeader({this.date, super.key});

  /// The case's day. Null draws nothing on the trailing side.
  final DateTime? date;

  /// Matches the tab bar and Heute's header: 44dp, section 6's minimum
  /// target.
  static const double barHeight = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    return GiMaterial(
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
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Tappable.faded(
                      backgroundColor: Colors.transparent,
                      onTap: () {
                        GiHaptics.selection(context);
                        context.pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15,
                              color: colors.tint,
                            ),
                            const Gap.h(AppSpacing.xs),
                            Text(
                              context.l10n.backToHeuteText,
                              style: GiText.subhead.copyWith(
                                color: colors.tint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (date != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Text(
                          _shortDate(context, date!),
                          style: GiText.subhead.copyWith(
                            color: colors.label.withValues(alpha: .7),
                          ),
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
    );
  }

  /// `25. Aug.` The card carries the month in full; up here it is a stamp, not
  /// a sentence.
  static String _shortDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d. MMM', locale).format(date);
  }
}
