import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/app/routes/routes.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/mehr/mehr.dart';
import 'package:flutter_instagram_offline_first_clone/selector/selector.dart';
import 'package:go_router/go_router.dart';

/// {@template mehr_page}
/// Settings, and where the content comes from.
///
/// **Profil became Mehr.** There is no account here, so there is no profile: a
/// tab called Profil would promise a person and deliver settings, which is the
/// kind of small lie that makes an app feel borrowed.
///
/// **Nothing on this screen is tinted.** A settings list has no single next
/// action, and tinting a row here would spend the one signal the app has on
/// something that is not one.
/// {@endtemplate}
class MehrPage extends StatelessWidget {
  /// {@macro mehr_page}
  const MehrPage({super.key});

  /// Shown on the Version row. Read from the bundle rather than typed here in
  /// a later phase; today it is one place to change rather than several.
  static const String version = '0.1.0';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;
    final status = context.read<CaseSource>().contentStatus;

    Widget chevron() => Icon(
      Icons.arrow_forward_ios_rounded,
      size: 14,
      color: colors.labelTertiary,
    );

    return MehrScaffold(
      title: l10n.moreNavBarItemLabel,
      children: [
        GiGroupHeader(l10n.displayHeaderText),
        GiGroup(
          children: [
            GiRow(
              label: l10n.appearanceRowText,
              value: _appearanceLabel(context),
              trailing: chevron(),
              onTap: () => context.pushNamed(AppRoutes.appearance.name),
            ),
            GiRow(
              label: l10n.languageRowText,
              value: _languageLabel(context),
              trailing: chevron(),
              onTap: () => context.pushNamed(AppRoutes.language.name),
            ),
          ],
        ),
        const Gap.v(AppSpacing.lg),
        GiGroupHeader(l10n.contentOriginHeaderText),
        GiGroup(
          children: [
            GiRow(
              label: l10n.imageSourcesRowText,
              trailing: chevron(),
              onTap: () => context.pushNamed(AppRoutes.imageSources.name),
            ),
            GiRow(
              label: l10n.guidelinesRightsRowText,
              trailing: chevron(),
              onTap: () => context.pushNamed(AppRoutes.guidelineRights.name),
            ),
            GiRow(
              label: l10n.contentStatusRowText,
              value: l10n.approvedCountText(status.approvedCount),
              trailing: chevron(),
              onTap: () => context.pushNamed(AppRoutes.contentStatus.name),
            ),
          ],
        ),
        const Gap.v(AppSpacing.lg),
        GiGroupHeader(l10n.aboutHeaderText),
        GiGroup(
          children: [
            GiRow(
              label: l10n.aboutAppRowText,
              trailing: chevron(),
              onTap: () => context.pushNamed(AppRoutes.aboutApp.name),
            ),
            // Not a page we chose. A German product published to an app store
            // needs one, and it belongs here with the version.
            GiRow(
              label: l10n.imprintRowText,
              trailing: chevron(),
              onTap: () => context.pushNamed(AppRoutes.imprint.name),
            ),
            GiRow(label: l10n.versionRowText, value: version),
          ],
        ),
      ],
    );
  }

  static String _appearanceLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (context.watch<ThemeModeBloc>().state) {
      ThemeMode.light => l10n.appearanceLightText,
      ThemeMode.dark => l10n.appearanceDarkText,
      ThemeMode.system => l10n.appearanceSystemText,
    };
  }

  static String _languageLabel(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en'
      ? context.l10n.languageEnglishText
      : context.l10n.languageGermanText;
}
