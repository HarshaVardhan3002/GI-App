import 'package:flutter/widgets.dart';

/// {@template gi_ramp}
/// The Gletscherspalte ground, as a continuous ramp rather than a set of named
/// colours.
///
/// `DESIGN.md` §3: hard-set tokens produce a visible step wherever two meet, so
/// a component asks for a **depth between 0 and 1** and gets a colour
/// interpolated between the stops. The named stops are positions on the ramp,
/// not the ramp itself.
///
/// No surface is neutral grey. Every depth carries a trace of the tint, so the
/// ground reads as one material lit at different depths rather than separate
/// greys stacked on each other.
/// {@endtemplate}
abstract final class GiRamp {
  /// The seven measured stops, dark appearance.
  static const List<Color> dark = [
    Color(0xFF000000),
    Color(0xFF04080B),
    Color(0xFF080F14),
    Color(0xFF0C161D),
    Color(0xFF122029),
    Color(0xFF182A35),
    Color(0xFF1E3542),
  ];

  /// The seven measured stops, light appearance.
  static const List<Color> light = [
    Color(0xFFFFFFFF),
    Color(0xFFF7FAFC),
    Color(0xFFF1F5F9),
    Color(0xFFE9F0F6),
    Color(0xFFE0EAF2),
    Color(0xFFD6E2EC),
    Color(0xFFC9D8E4),
  ];

  /// Where each stop sits on the ramp. Deliberately uneven: the ramp moves
  /// fastest near the ground, where a step would be most visible.
  static const List<double> positions = [0, .15, .30, .45, .60, .80, 1];

  /// The colour at [depth] on the ramp, interpolated between the stops.
  ///
  /// [depth] is clamped, so a caller cannot fall off either end.
  static Color of(double depth, {required Brightness brightness}) {
    final stops = brightness == Brightness.dark ? dark : light;
    final d = depth.clamp(0.0, 1.0);

    for (var i = 0; i < positions.length - 1; i++) {
      final lower = positions[i];
      final upper = positions[i + 1];
      if (d > upper) continue;
      final t = upper == lower ? 0.0 : (d - lower) / (upper - lower);
      return Color.lerp(stops[i], stops[i + 1], t)!;
    }
    return stops.last;
  }
}

/// {@template gi_colors}
/// One appearance of the palette: the ramp, plus the semantic colours that do
/// not live on it.
///
/// Resolved once per theme rather than read through an inherited widget on
/// every build, so a widget can be `const` where it would otherwise not be.
/// {@endtemplate}
@immutable
class GiColors {
  /// {@macro gi_colors}
  const GiColors({
    required this.brightness,
    required this.label,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.tint,
    required this.correct,
    required this.incorrect,
    required this.warning,
  });

  /// The dark appearance, which is the one this product is designed for:
  /// endoscopic images are read against black.
  const GiColors.dark()
    : brightness = Brightness.dark,
      label = const Color(0xFFFFFFFF),
      labelSecondary = const Color(0xFF9BAAB6),
      labelTertiary = const Color(0xFF6B7A86),
      tint = const Color(0xFF3FA9F5),
      correct = const Color(0xFF30D158),
      incorrect = const Color(0xFFFF453A),
      warning = const Color(0xFFFF9F0A);

  /// The light appearance. Available, and not the default.
  const GiColors.light()
    : brightness = Brightness.light,
      label = const Color(0xFF0B1620),
      labelSecondary = const Color(0xFF485A69),
      labelTertiary = const Color(0xFF7A8B99),
      tint = const Color(0xFF0B6BB5),
      correct = const Color(0xFF2E7D4F),
      incorrect = const Color(0xFFC0392B),
      warning = const Color(0xFFB26A00);

  /// Which appearance this is. Drives [depth].
  final Brightness brightness;

  /// Primary text. Holds 12.55:1 or better at every depth.
  final Color label;

  /// Supporting text: metadata, dates, citations.
  final Color labelSecondary;

  /// Text that is present but not being read: disabled rows, hints.
  final Color labelTertiary;

  /// The one accent. It marks the single next action on a screen and nothing
  /// else.
  final Color tint;

  /// A correct answer. Never appears on anything that is not a verdict.
  final Color correct;

  /// An incorrect answer. Same rule.
  final Color incorrect;

  /// Placeholder content and other things the reader is owed a warning about.
  final Color warning;

  /// {@macro gi_ramp}
  Color depth(double value) => GiRamp.of(value, brightness: brightness);

  /// Depth 0. The ground everything else sits on.
  Color get surface => depth(0);

  /// Depth 0.30. Inset groups, sheets over the ground.
  Color get surfaceRaised => depth(.30);

  /// Depth 0.60. A row under a finger.
  Color get surfacePressed => depth(.60);

  /// Depth 1. Hairlines between rows.
  Color get separator => depth(1);
}
