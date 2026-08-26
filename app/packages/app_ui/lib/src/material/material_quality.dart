import 'package:flutter/widgets.dart';

/// {@template material_quality}
/// Whether the materials on this route actually blur.
///
/// **One inherited value drives every material in the app.** `DESIGN.md`
/// section 4: "Reduced transparency collapses each material to an opaque
/// surface at the same depth." That is one flag, read in one place, and no
/// branch anywhere else: a disabled [BackdropFilter] keeps its widget, its
/// layout and every dimension, and skips the filter. There is no second layout
/// and no untested code path.
///
/// It is false when the platform asks for it, and it can be forced false while
/// measuring, which is how the two halves of the frame-time comparison are
/// produced from one build.
/// {@endtemplate}
@immutable
class MaterialQuality extends InheritedWidget {
  /// {@macro material_quality}
  const MaterialQuality({
    required this.blurEnabled,
    required super.child,
    super.key,
  });

  /// Whether the blur runs.
  final bool blurEnabled;

  /// What every material reads. Defaults to blurring when nobody has said
  /// otherwise, so a widget dropped in a test still looks like itself.
  static bool blurOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MaterialQuality>()
          ?.blurEnabled ??
      true;

  /// Forces every material opaque for a measurement run.
  ///
  /// `--dart-define=GI_NO_BLUR=true`. It exists so the two halves of the
  /// frame-time comparison in `docs/MATERIAL-IMPLEMENTATION.md` section 6 come
  /// out of the same source, rather than out of a build with the material
  /// commented out, which would measure a different app.
  static const bool forceOpaque = bool.fromEnvironment('GI_NO_BLUR');

  /// What the platform is asking for.
  ///
  /// Flutter's [MediaQueryData] has no reduce-transparency flag, so this reads
  /// the two settings that mean the same thing to a person: Android's *Remove
  /// animations* and iOS's *Increase Contrast*, which is the switch Apple
  /// pairs with Reduce Transparency. Someone who has turned either on has said
  /// they do not want the screen doing work behind their content.
  static bool platformWantsBlur(BuildContext context) {
    if (forceOpaque) return false;
    final media = MediaQuery.of(context);
    return !media.disableAnimations && !media.highContrast;
  }

  @override
  bool updateShouldNotify(MaterialQuality oldWidget) =>
      oldWidget.blurEnabled != blurEnabled;
}

/// {@template gi_backdrop_group}
/// The one backdrop pass a route gets.
///
/// **This is the answer to the whole cost problem**, and the reason the design
/// can afford more than one material on a screen. A [BackdropFilter] forces a
/// save-layer, reads the framebuffer back, blurs it and composites, every frame
/// the content beneath it changes. Two bars would be two of those. Inside a
/// [BackdropGroup], every [BackdropFilter.grouped] shares a single backdrop
/// input with its siblings, so a screen with a top bar, a bottom bar and a
/// floating control costs one pass rather than three.
///
/// **One per route.** It wraps the route's stack, above the scaffold and below
/// the scrolling content, so what it samples is the content.
///
/// It also resolves [MaterialQuality] for everything under it, so a route gets
/// its shared pass and its kill switch from the same widget and cannot have
/// one without the other.
/// {@endtemplate}
class GiBackdropGroup extends StatelessWidget {
  /// {@macro gi_backdrop_group}
  const GiBackdropGroup({required this.child, this.blurEnabled, super.key});

  /// The route's content.
  final Widget child;

  /// Forces the kill switch. Null asks the platform, which is what every
  /// screen does; a measurement harness passes false.
  final bool? blurEnabled;

  @override
  Widget build(BuildContext context) {
    return MaterialQuality(
      blurEnabled: blurEnabled ?? MaterialQuality.platformWantsBlur(context),
      child: BackdropGroup(child: child),
    );
  }
}
