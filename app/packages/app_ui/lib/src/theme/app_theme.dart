import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// {@template app_theme}
/// The Default App [ThemeData].
///
/// **Every colour in here comes from the ramp.** The fork built this theme from
/// `AppColors`, its Instagram palette, and so every Material component that
/// falls back to a theme colour - ripples, default indicators, default buttons,
/// dividers - drew from that palette rather than from the one `DESIGN.md`
/// decided. A screen this product has not rebuilt yet is still the fork's
/// screen, but it is no longer painted in the fork's colours.
/// {@endtemplate}
class AppTheme {
  /// {@macro app_theme}
  const AppTheme();

  /// Defines the brightness of theme.
  Brightness get brightness => Brightness.light;

  /// The appearance this theme paints from. `DESIGN.md` section 3.
  GiColors get gi => const GiColors.light();

  /// Defines the background color of theme. Depth 0, the ground.
  Color get backgroundColor => gi.surface;

  /// Defines the primary color of theme.
  ///
  /// **The tint, not the label colour.** Material spends `primary` on the
  /// things it decides are actionable: a selected indicator, a default button
  /// fill, a text field focus ring. On an unconverted fork screen that is
  /// where the one accent belongs, and it is what stops Flutter's stock
  /// `Colors.blue` appearing on a screen that never asked for a colour.
  Color get primary => gi.tint;

  /// Defines light [ThemeData].
  ThemeData get theme => _build(
    FlexThemeData.light(
      scheme: FlexScheme.custom,
      colors: FlexSchemeColor.from(
        brightness: brightness,
        primary: primary,
        swapOnMaterial3: true,
      ),
      useMaterial3: true,
      useMaterial3ErrorColors: true,
    ),
  );

  /// Everything both appearances share, applied over whichever Flex scheme
  /// built the base. Kept in one place so the two themes cannot drift apart.
  ThemeData _build(ThemeData base) {
    return base.copyWith(
      // Flex derives its own surface tones by blending. Those blends are not
      // on the ramp, so the scheme's grounds are overwritten with ramp stops
      // rather than trusted.
      colorScheme: base.colorScheme.copyWith(
        primary: gi.tint,
        surface: gi.depth(0),
        onSurface: gi.label,
        onSurfaceVariant: gi.labelSecondary,
        surfaceContainerLowest: gi.depth(0),
        surfaceContainerLow: gi.depth(.15),
        surfaceContainer: gi.depth(.30),
        surfaceContainerHigh: gi.depth(.45),
        surfaceContainerHighest: gi.depth(.60),
        outline: gi.depth(1),
        outlineVariant: gi.depth(.80),
        error: gi.incorrect,
      ),
      scaffoldBackgroundColor: gi.surface,
      canvasColor: gi.surface,
      dividerColor: gi.separator,
      splashColor: gi.surfacePressed,
      highlightColor: gi.surfacePressed,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: gi.label),
      dividerTheme: DividerThemeData(
        color: gi.separator,
        space: 0,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        fillColor: gi.depth(.30),
        hintStyle: GiText.body.copyWith(color: gi.labelTertiary),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        surfaceTintColor: gi.surface,
        backgroundColor: gi.surface,
        foregroundColor: gi.label,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: gi.surface,
        selectedItemColor: gi.label,
        unselectedItemColor: gi.labelTertiary,
      ),
      // Sheets sit at depth 0.15. `AppColors.background` was
      // ARGB(255, 32, 30, 30), a warm neutral grey, and section 3 says no
      // surface in this app is one.
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        surfaceTintColor: gi.depth(.15),
        backgroundColor: gi.depth(.15),
        modalBackgroundColor: gi.depth(.15),
      ),
      dialogTheme: DialogThemeData(backgroundColor: gi.depth(.15)),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: gi.tint),
    );
  }

  /// Defines iOS dart SystemUiOverlayStyle.
  static const SystemUiOverlayStyle iOSDarkSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      );

  /// Text theme of the App theme.
  TextTheme get textTheme => contentTextTheme.apply(
    bodyColor: gi.label,
    displayColor: gi.label,
    decorationColor: gi.label,
  );

  /// The Content text theme based on [ContentTextStyle].
  ///
  /// Colourless: [textTheme] applies the appearance's label colour, so this
  /// carries metrics only and cannot ship one appearance's ink on the other's
  /// ground.
  static final contentTextTheme = TextTheme(
    displayLarge: ContentTextStyle.headline1,
    displayMedium: ContentTextStyle.headline2,
    displaySmall: ContentTextStyle.headline3,
    headlineLarge: ContentTextStyle.headline4,
    headlineMedium: ContentTextStyle.headline5,
    headlineSmall: ContentTextStyle.headline6,
    titleLarge: ContentTextStyle.headline7,
    titleMedium: ContentTextStyle.subtitle1,
    titleSmall: ContentTextStyle.subtitle2,
    bodyLarge: ContentTextStyle.bodyText1,
    bodyMedium: ContentTextStyle.bodyText2,
    labelLarge: ContentTextStyle.button,
    bodySmall: ContentTextStyle.caption,
    labelSmall: ContentTextStyle.overline,
  );

  /// The UI text theme based on [UITextStyle].
  static final uiTextTheme = TextTheme(
    displayLarge: UITextStyle.headline1,
    displayMedium: UITextStyle.headline2,
    displaySmall: UITextStyle.headline3,
    headlineMedium: UITextStyle.headline4,
    headlineSmall: UITextStyle.headline5,
    titleLarge: UITextStyle.headline6,
    titleMedium: UITextStyle.subtitle1,
    titleSmall: UITextStyle.subtitle2,
    bodyLarge: UITextStyle.bodyText1,
    bodyMedium: UITextStyle.bodyText2,
    labelLarge: UITextStyle.button,
    bodySmall: UITextStyle.caption,
    labelSmall: UITextStyle.overline,
  );
}

/// {@template app_dark_theme}
/// Dark Mode App [ThemeData]. The appearance this product is designed for:
/// endoscopic images are read against black.
/// {@endtemplate}
class AppDarkTheme extends AppTheme {
  /// {@macro app_dark_theme}
  const AppDarkTheme();

  @override
  Brightness get brightness => Brightness.dark;

  @override
  GiColors get gi => const GiColors.dark();

  @override
  ThemeData get theme => _build(
    FlexThemeData.dark(
      scheme: FlexScheme.custom,
      // Depth 0 in the dark ramp is #000000, so true black is not a stylistic
      // choice here. It is the ramp's own ground.
      darkIsTrueBlack: true,
      colors: FlexSchemeColor.from(
        brightness: brightness,
        primary: primary,
        appBarColor: AppColors.transparent,
        swapOnMaterial3: true,
      ),
      useMaterial3: true,
      useMaterial3ErrorColors: true,
    ),
  );
}

/// Theme for the [SystemUiOverlayStyle]
class SystemUiOverlayTheme {
  /// {@macro system_ui_overlay_theme}
  const SystemUiOverlayTheme();

  /// Defines iOS light SystemUiOverlayStyle.
  static const SystemUiOverlayStyle iOSLightSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      );

  /// Defines iOS dark SystemUiOverlayStyle.
  static const SystemUiOverlayStyle iOSDarkSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      );

  /// Defines Android light SystemUiOverlayStyle.
  ///
  /// `final` rather than `const`: the bar's colour is depth 0 of the light
  /// ramp, and the ramp is interpolated at runtime.
  static final SystemUiOverlayStyle androidLightSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: GiRamp.of(0, brightness: Brightness.light),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      );

  /// Defines light SystemUiOverlayStyle.
  static final SystemUiOverlayStyle androidDarkSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: GiRamp.of(0, brightness: Brightness.dark),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      );

  /// Defines a portrait only orientation for any device.
  static void setPortraitOrientation() {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
  }
}
