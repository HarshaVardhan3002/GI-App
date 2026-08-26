import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
// HomeProvider, used only by the commented-out chat action below.
// ignore: unused_import
import 'package:flutter_instagram_offline_first_clone/home/home.dart';

class FeedAppBar extends StatelessWidget {
  const FeedAppBar({required this.innerBoxIsScrolled, super.key});

  final bool innerBoxIsScrolled;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      sliver: SliverAppBar(
        centerTitle: false,
        forceElevated: innerBoxIsScrolled,
        title: const AppLogo(),
        floating: true,
        snap: true,
        // Chat is not part of this product. Removing the icon is not enough on
        // its own: the page it opened is a sibling in `HomePage`'s horizontal
        // PageView and stays reachable by swipe, so the physics are pinned
        // there in the same pass.
        // actions: [
        //   Tappable.scaled(
        //     onTap: () => HomeProvider().animateToPage(2),
        //     child: Assets.icons.chatCircle.svg(
        //       height: AppSize.iconSize,
        //       width: AppSize.iconSize,
        //       colorFilter: ColorFilter.mode(
        //         context.adaptiveColor,
        //         BlendMode.srcIn,
        //       ),
        //     ),
        //   ),
        // ],
      ),
    );
  }
}
