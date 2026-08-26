import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// {@template mehr_scaffold}
/// The shape every screen under Mehr has: a bar, and a scrolling column of
/// groups underneath it.
///
/// One widget rather than six copies, because a settings tree is exactly where
/// small inconsistencies accumulate. **A new sub-page needs no new layout
/// decision**, which is the same reason `GiGroup` exists.
/// {@endtemplate}
class MehrScaffold extends StatelessWidget {
  /// {@macro mehr_scaffold}
  const MehrScaffold({
    required this.title,
    required this.children,
    this.backLabel,
    this.trailing,
    super.key,
  });

  /// The screen's name, in the bar.
  final String title;

  /// What the back control says it goes to. Null draws no back control, which
  /// is what a root tab wants.
  final String? backLabel;

  /// The bar's trailing slot.
  final Widget? trailing;

  /// The page's content, in order.
  final List<Widget> children;

  /// The same 44dp as every other bar in the app.
  static const double barHeight = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;

    // Each screen under Mehr is a route of its own, so the group belongs on
    // the scaffold rather than one level up: pushing a sub-page pushes its own
    // backdrop pass with it.
    return GiBackdropGroup(
      child: AppScaffold(
        top: false,
        bottom: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top:
                      MediaQuery.paddingOf(context).top +
                      barHeight +
                      AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  // The last row can always be scrolled clear of the chrome.
                  bottom:
                      MediaQuery.paddingOf(context).bottom + AppSpacing.xxlg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: GiMaterial(
                edge: VerticalDirection.up,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: barHeight,
                        child: Stack(
                          children: [
                            // The title is centred on the screen rather than
                            // between the controls, so it does not shift when a
                            // back label gets longer.
                            Center(
                              child: Text(
                                title,
                                style: GiText.headline.copyWith(
                                  color: colors.label,
                                ),
                              ),
                            ),
                            if (backLabel != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Tappable.faded(
                                  backgroundColor: Colors.transparent,
                                  onTap: () {
                                    GiHaptics.selection(context);
                                    context.pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
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
                                          backLabel!,
                                          style: GiText.subhead.copyWith(
                                            color: colors.tint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (trailing != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.lg,
                                  ),
                                  child: trailing,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: GiMaterial.fadeExtent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// {@template mehr_note}
/// A sentence under a group, explaining what the group does not say itself.
/// {@endtemplate}
class MehrNote extends StatelessWidget {
  /// {@macro mehr_note}
  const MehrNote(this.text, {super.key});

  /// The sentence.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        right: AppSpacing.xs,
        top: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: GiText.footnote.copyWith(color: context.gi.labelTertiary),
      ),
    );
  }
}
