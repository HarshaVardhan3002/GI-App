import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/mehr/mehr.dart';
import 'package:flutter_instagram_offline_first_clone/selector/selector.dart';

/// {@template erscheinungsbild_page}
/// System, Hell, Dunkel.
///
/// The note under the group is not a disclaimer. **Dark is not a preference
/// here, it is what the images are read against**, and a reader who switches to
/// light should know that before they wonder why an endoscopic image looks
/// worse than it did.
/// {@endtemplate}
class ErscheinungsbildPage extends StatelessWidget {
  /// {@macro erscheinungsbild_page}
  const ErscheinungsbildPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;
    final current = context.watch<ThemeModeBloc>().state;

    GiRow option(ThemeMode mode, String label) => GiRow(
      label: label,
      isSelected: mode == current,
      onTap: () {
        GiHaptics.selection(context);
        context.read<ThemeModeBloc>().add(ThemeModeChanged(mode));
      },
      trailing: mode == current
          ? Icon(Icons.check_rounded, size: 20, color: colors.tint)
          : null,
    );

    return MehrScaffold(
      title: l10n.appearanceRowText,
      backLabel: l10n.moreNavBarItemLabel,
      children: [
        GiGroup(
          children: [
            option(ThemeMode.system, l10n.appearanceSystemText),
            option(ThemeMode.light, l10n.appearanceLightText),
            option(ThemeMode.dark, l10n.appearanceDarkText),
          ],
        ),
        MehrNote(l10n.appearanceNoteText),
      ],
    );
  }
}

/// {@template sprache_page}
/// Deutsch, and English for whoever is building this.
///
/// English is listed as what it is. Constraint 4 says the product is German;
/// an English option presented as an equal choice would read as a promise that
/// the clinical content has been translated and reviewed, and it has not.
/// {@endtemplate}
class SprachePage extends StatelessWidget {
  /// {@macro sprache_page}
  const SprachePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.gi;
    final current = Localizations.localeOf(context).languageCode;

    GiRow option(String code, String label) => GiRow(
      label: label,
      isSelected: code == current,
      onTap: () {
        GiHaptics.selection(context);
        context.read<LocaleBloc>().add(LocaleChanged(Locale(code)));
      },
      trailing: code == current
          ? Icon(Icons.check_rounded, size: 20, color: colors.tint)
          : null,
    );

    return MehrScaffold(
      title: l10n.languageRowText,
      backLabel: l10n.moreNavBarItemLabel,
      children: [
        GiGroup(
          children: [
            option('de', l10n.languageGermanText),
            option('en', l10n.languageEnglishText),
          ],
        ),
        MehrNote(l10n.languageNoteText),
      ],
    );
  }
}
