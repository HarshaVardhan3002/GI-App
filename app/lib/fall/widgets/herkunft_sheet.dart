import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [HerkunftSheet] over the case screen.
///
/// Transparent barrier and background: the sheet is the Dick material and has
/// to see the screen behind it to be one.
Future<void> showHerkunftSheet(
  BuildContext context, {
  required GiCase giCase,
}) {
  GiHaptics.selection(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // The theme's sheet colour is opaque, and painting it under the material
    // would make the blur read as a tinted panel rather than as glass.
    barrierColor: Colors.black.withValues(alpha: .4),
    // The theme turns Material's own drag handle on for every sheet. This one
    // draws its own inside the material, so the theme's would sit above the
    // sheet's rounded edge and there would be two.
    showDragHandle: false,
    builder: (context) => HerkunftSheet(giCase: giCase),
  );
}

/// {@template herkunft_sheet}
/// Where this case came from: the image, the guideline, and who signed it off.
///
/// **This screen is the product's honesty made inspectable.** Constraint 1
/// says images are open, de-identified CC BY 4.0 with attribution on screen;
/// constraint 2 says guideline text is cited and never redistributed;
/// constraint 3 says nothing unreviewed reaches a reader. Each of those is a
/// claim, and a claim nobody can check is worth nothing. Every one of them has
/// a row here.
///
/// When anything in the case is a stand-in, the warning is the first thing on
/// the sheet, before the credits it would otherwise appear to lend weight to.
/// {@endtemplate}
class HerkunftSheet extends StatelessWidget {
  /// {@macro herkunft_sheet}
  const HerkunftSheet({required this.giCase, super.key});

  /// The case whose provenance this is.
  final GiCase giCase;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    final l10n = context.l10n;
    final image = giCase.images.first;
    final guideline = giCase.guideline;

    return GiSheetMaterial(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xlg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Grabber(),
              const Gap.v(AppSpacing.md),
              if (giCase.isPlaceholder) ...[
                GiGroup(
                  // A wash of the warning colour rather than a depth: this
                  // group is not part of the list, it is a caveat over it.
                  background: colors.warning.withValues(alpha: .14),
                  children: [
                    GiRow(
                      label: l10n.placeholderNoticeText,
                      labelStyle: GiText.footnote.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ],
                ),
                const Gap.v(AppSpacing.lg),
              ],
              GiGroupHeader(l10n.imageCreditHeaderText),
              GiGroup(
                children: [
                  // `source`, `className` and `licenceSpdx` are schema keys,
                  // not display strings. On a cleared image they happen to
                  // read as dataset names; on anything else they print
                  // `placeholder`, `PLACEHOLDER`, `UNVERIFIED` and
                  // `dyed-lifted-polyps` at a German reader. Constraint 4 is
                  // not satisfied by a value that came out of a JSON file.
                  GiRow(
                    label: l10n.datasetLabelText,
                    value: image.isRightsCleared
                        ? image.source
                        : image.isPlaceholder
                        ? l10n.placeholderImageLabelText
                        : l10n.testImageLabelText,
                    labelColor: colors.labelSecondary,
                  ),
                  if (image.isRightsCleared) ...[
                    GiRow(
                      label: l10n.imageClassLabelText,
                      value: image.className,
                      labelColor: colors.labelSecondary,
                    ),
                    GiRow(
                      label: l10n.licenceLabelText,
                      value: image.licenceSpdx,
                      labelColor: colors.labelSecondary,
                    ),
                  ],
                  GiRow(
                    label: l10n.rightsLabelText,
                    value: image.licenceHolder,
                    labelColor: colors.labelSecondary,
                  ),
                ],
              ),
              const Gap.v(AppSpacing.lg),
              GiGroupHeader(l10n.guidelineHeaderText),
              GiGroup(
                children: [
                  GiRow(
                    label: l10n.awmfLabelText,
                    value: guideline.awmfRegisterNumber,
                    labelColor: colors.labelSecondary,
                  ),
                  GiRow(
                    label: l10n.recommendationNumberLabelText,
                    value: giCase.recommendation.number,
                    labelColor: colors.labelSecondary,
                  ),
                  // The guideline's own rights position, in full and in its
                  // own words. Summarising a rights note is how you end up
                  // misstating one.
                  GiRow(
                    label: guideline.rightsNote,
                    labelStyle: GiText.footnote.copyWith(
                      color: colors.labelTertiary,
                    ),
                  ),
                  GiRow(
                    label: l10n.openGuidelineText,
                    labelColor: colors.tint,
                    onTap: () => _open(guideline.url),
                    trailing: Icon(
                      Icons.north_east_rounded,
                      size: 16,
                      color: colors.labelTertiary,
                    ),
                  ),
                ],
              ),
              const Gap.v(AppSpacing.xs),
              // It says it leaves the app before it does.
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Text(
                  l10n.leavesAppNoticeText,
                  style: GiText.footnote.copyWith(
                    color: colors.labelTertiary,
                  ),
                ),
              ),
              const Gap.v(AppSpacing.lg),
              GiGroupHeader(l10n.releaseHeaderText),
              GiGroup(
                children: [
                  GiRow(
                    label: l10n.reviewedByLabelText,
                    value: l10n.notReviewedText,
                    labelColor: colors.labelSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// {@template grabber}
/// The bar that says this sheet can be dragged away.
/// {@endtemplate}
class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 36,
        height: 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.gi.separator,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
