import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/app/routes/routes.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

/// {@template tageskarte_images}
/// The image, or the images, filling the width.
///
/// Never cropped by layout: the frame follows the image's aspect rather than
/// the image being cut to fit a frame. In an endoscopic image the edge of the
/// lumen is often the finding, and a layout that trims it is a clinical
/// mistake dressed as a design one.
/// {@endtemplate}
class TageskarteImages extends StatefulWidget {
  /// {@macro tageskarte_images}
  const TageskarteImages({required this.images, super.key});

  /// In carousel order.
  final List<GiImage> images;

  @override
  State<TageskarteImages> createState() => _TageskarteImagesState();
}

class _TageskarteImagesState extends State<TageskarteImages> {
  late final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.images.length,
      itemBuilder: (context, index) => Image.asset(
        widget.images[index].assetPath,
        fit: BoxFit.cover,
        // The image is the content, so a failure to load it is worth seeing
        // rather than worth hiding behind an empty box.
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: context.gi.depth(.30),
          child: Center(
            child: Text(
              context.l10n.imageMissingText,
              textAlign: TextAlign.center,
              style: GiText.footnote.copyWith(color: context.gi.warning),
            ),
          ),
        ),
      ),
    );
  }
}

/// {@template tageskarte_dots}
/// How many images this case has, and which one is showing.
///
/// Only drawn when there is more than one, because a single dot is an
/// instruction to do nothing.
/// {@endtemplate}
class TageskarteDots extends StatelessWidget {
  /// {@macro tageskarte_dots}
  const TageskarteDots({required this.count, this.active = 0, super.key});

  /// How many images.
  final int count;

  /// Which one is showing.
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : AppSpacing.xs),
            child: SizedBox(
              width: 5,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == active ? colors.label : colors.labelTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// {@template tageskarte_peek}
/// Ten density-independent pixels of the card underneath.
///
/// **It teaches the gesture without baiting it.** It is static, it never
/// animates on its own, and it does not suggest there is anything endless down
/// there. When this is the last case it simply is not drawn, so the reader can
/// see they have reached the end without being told.
/// {@endtemplate}
class TageskartePeek extends StatelessWidget {
  /// {@macro tageskarte_peek}
  const TageskartePeek({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.gi.depth(.30),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
    );
  }
}

/// {@template fall_oeffnen}
/// The one tinted element on the screen, and therefore the one next action.
/// {@endtemplate}
class FallOeffnen extends StatelessWidget {
  /// {@macro fall_oeffnen}
  const FallOeffnen({required this.postId, super.key});

  /// Which case to open.
  final String postId;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    return Tappable.faded(
      backgroundColor: Colors.transparent,
      onTap: () {
        GiHaptics.commit(context);
        context.pushNamed(
          AppRoutes.post.name,
          pathParameters: {'id': postId},
        );
      },
      child: Padding(
        // Vertical padding rather than a fixed height: the row has to stay a
        // 44dp target even when the text does not need it.
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.openCaseText,
              style: GiText.headline.copyWith(color: colors.tint),
            ),
            const Gap.h(AppSpacing.xs),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.tint),
          ],
        ),
      ),
    );
  }
}

/// {@template heute_header}
/// The wordmark, over the image.
///
/// The day is deliberately not repeated here. `docs/SCREENS.md` put the date in
/// the top bar as well as in the card's meta line, and on one screen that is
/// the same fact printed twice. The card keeps it, because that is where it
/// belongs to a case rather than to the app.
/// {@endtemplate}
class HeuteHeader extends StatelessWidget {
  /// {@macro heute_header}
  const HeuteHeader({super.key});

  /// How far the scrim reaches. Enough to carry the wordmark and its safe area,
  /// and no further: it is there to make text legible, not to darken the image.
  static const double scrimHeight = 140;

  @override
  Widget build(BuildContext context) {
    final surface = context.gi.surface;
    return IgnorePointer(
      child: SizedBox(
        height: scrimHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surface.withValues(alpha: .85),
                surface.withValues(alpha: 0),
              ],
              stops: const [0, 1],
            ),
          ),
          child: const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppLogo(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
