import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_offline_first_clone/app/routes/routes.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:flutter_instagram_offline_first_clone/media/media.dart';
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
      itemBuilder: (context, index) =>
          GiImageView(image: widget.images[index]),
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
                  // The active dot is the tint. It is the one place on the
                  // card where tint marks position rather than an action, and
                  // the screen mockups set it that way: at 5dp it reads as a
                  // mark, not as something to press.
                  color: i == active
                      ? colors.tint
                      : colors.label.withValues(alpha: .3),
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
        // Depth 0.45, not 0.30. The card under this one is not a raised
        // surface, it is a further-away one, and the mockups place it a stop
        // deeper than a sheet.
        color: context.gi.depth(.45),
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
/// The wordmark, and the name of the screen you are on.
///
/// The image runs full bleed to the top, so this is not an app bar above the
/// content: it is the Normal material floating over it, and the image stays
/// visible underneath. It is here because an endoscopic image can be bright at
/// its top edge and white text on it would be unreadable exactly when the
/// image is at its best.
///
/// **The right slot names the screen.** An earlier pass dropped it, reasoning
/// that the date already appears in the card's meta line. That was a
/// misreading of the mockup: the right slot carries *Heute*, the destination,
/// not the date, and with three tab destinations the top bar is where you are
/// told which one you are in.
/// {@endtemplate}
class HeuteHeader extends StatelessWidget {
  /// {@macro heute_header}
  const HeuteHeader({super.key});

  /// The row the wordmark sits in, above the status bar's inset. 44 is the
  /// minimum target in `DESIGN.md` section 6 and the height of a navigation
  /// bar on iOS.
  static const double barHeight = 44;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: GiMaterial(
        edge: VerticalDirection.up,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: barHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppLogo(),
                      Text(
                        context.l10n.todayNavBarItemLabel,
                        style: GiText.subhead.copyWith(
                          // Present without competing with the wordmark. The
                          // label colour at 70%, rather than
                          // `labelSecondary`, because it sits on a material
                          // over the image and has to hold against whatever
                          // is behind it.
                          color: context.gi.label.withValues(alpha: .7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // The material's own fade tail. Section 4 rule 3: no hairline
            // where chrome ends.
            const SizedBox(height: GiMaterial.fadeExtent),
          ],
        ),
      ),
    );
  }
}
