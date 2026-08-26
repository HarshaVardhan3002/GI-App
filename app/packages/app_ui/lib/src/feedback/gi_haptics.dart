import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// {@template gi_haptics}
/// Every haptic in the app, in one place.
///
/// Two reasons this is not `HapticFeedback` called at each site. It keeps the
/// vocabulary small, so a tap always feels the same wherever it happens. And it
/// gives the whole app one switch: a reader who has asked the system to reduce
/// motion has asked for less, and buzzing at them is not less.
///
/// Each method takes a [BuildContext] so it can read that preference. A haptic
/// fired outside a build context is a haptic nobody agreed to.
/// {@endtemplate}
abstract final class GiHaptics {
  static bool _wanted(BuildContext context) =>
      !MediaQuery.maybeOf(context)!.disableAnimations;

  /// Choosing one of the answers. The lightest thing the platform offers,
  /// because selecting is not committing.
  static void selection(BuildContext context) {
    if (_wanted(context)) HapticFeedback.selectionClick();
  }

  /// Committing to an answer, and arriving at a new case. The moment the
  /// screen changes under the reader.
  static void commit(BuildContext context) {
    if (_wanted(context)) HapticFeedback.lightImpact();
  }

  /// The reveal, and only the reveal.
  ///
  /// **Correct and incorrect feel the same.** At Facharzt level a right answer
  /// is the expected outcome rather than an achievement, and a different buzz
  /// for wrong would be the app having an opinion about the reader.
  static void reveal(BuildContext context) {
    if (_wanted(context)) HapticFeedback.mediumImpact();
  }
}
