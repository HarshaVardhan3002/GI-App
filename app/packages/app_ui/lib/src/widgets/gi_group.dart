import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template gi_group}
/// An inset group of rows.
///
/// The unit every list in this app is built from: answers on the case screen,
/// the recommendation and its citation, the provenance sheet, the settings
/// list. **What is in one group belongs together**, which is why the guideline
/// quote and the line naming its source are rows of the same group rather than
/// two blocks that a later layout change could separate.
///
/// Ground is depth 0.30, hairlines are depth 1, radius 14. `DESIGN.md`
/// sections 3 and 6.
/// {@endtemplate}
class GiGroup extends StatelessWidget {
  /// {@macro gi_group}
  const GiGroup({required this.children, this.background, super.key});

  /// The rows, in order.
  final List<Widget> children;

  /// Overrides the group's ground. Used only by the placeholder notice, which
  /// carries a warning wash instead of a depth.
  final Color? background;

  /// Section 6: containers.
  static const double radius = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? colors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                // Inset to the text, not to the group's edge: a hairline that
                // runs the full width reads as a cut, one that starts where
                // the text starts reads as a list.
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  child: ColoredBox(
                    color: colors.separator,
                    child: const SizedBox(height: 0.5, width: double.infinity),
                  ),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// {@template gi_group_header}
/// The word above a group.
///
/// Fira Sans in caps rather than a second face. The screen mockups set these
/// in Fira Mono, and `DESIGN.md` section 5 allows exactly three uses of a
/// second typeface - the wordmark, the question and the guideline quote - none
/// of which is this. Caps and letter-spacing carry the same job.
/// {@endtemplate}
class GiGroupHeader extends StatelessWidget {
  /// {@macro gi_group_header}
  const GiGroupHeader(this.label, {super.key});

  /// What the group holds. Named plainly.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: GiText.caption.copyWith(
          color: context.gi.labelTertiary,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// {@template gi_row}
/// One row of a [GiGroup].
///
/// 56dp, which is the answer-row height in `DESIGN.md` section 6 and
/// comfortably past the 44dp minimum target. A row that wraps grows past it
/// rather than clipping.
/// {@endtemplate}
class GiRow extends StatelessWidget {
  /// {@macro gi_row}
  const GiRow({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.labelColor,
    this.labelStyle,
    super.key,
  });

  /// The row's own text, on the leading side.
  final String label;

  /// The answer to it, on the trailing side. Null draws nothing.
  final String? value;

  /// Drawn after [value]. A chevron, a check, an external-link mark.
  final Widget? trailing;

  /// Null makes the row inert, and it will not respond to a press.
  final VoidCallback? onTap;

  /// Depth 0.60 under the row, for a chosen answer.
  final bool isSelected;

  /// Overrides the label's colour. Used for a row that is itself an action.
  final Color? labelColor;

  /// Overrides the label's style outright, for the guideline quote.
  final TextStyle? labelStyle;

  /// Section 6.
  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    final content = Container(
      constraints: const BoxConstraints(minHeight: minHeight),
      color: isSelected ? colors.surfacePressed : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  labelStyle ??
                  GiText.body.copyWith(color: labelColor ?? colors.label),
            ),
          ),
          if (value != null) ...[
            const Gap.h(AppSpacing.md),
            Text(
              value!,
              textAlign: TextAlign.end,
              style: GiText.body.copyWith(color: colors.labelSecondary),
            ),
          ],
          if (trailing != null) ...[
            const Gap.h(AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Tappable.faded(
      onTap: onTap,
      backgroundColor: Colors.transparent,
      child: content,
    );
  }
}
