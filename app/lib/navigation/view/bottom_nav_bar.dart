import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
// Both are used only by the commented-out avatar tab below.
// ignore: unused_import
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: unused_import
import 'package:flutter_instagram_offline_first_clone/app/bloc/app_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/feed/feed.dart';
import 'package:flutter_instagram_offline_first_clone/feed/post/video/video.dart';
import 'package:flutter_instagram_offline_first_clone/home/home.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
// UserProfileAvatar, used only by the commented-out avatar tab.
// ignore: unused_import
import 'package:instagram_blocks_ui/instagram_blocks_ui.dart';
// `350.ms`, used only by the commented-out avatar tab.
// ignore: unused_import
import 'package:shared/shared.dart';

/// {@template main_bottom_navigation_bar}
/// Bottom navigation bar of the application. It contains the [navigationShell]
/// that will handle the navigation between the different bottom navigation
/// bars.
/// {@endtemplate}
class BottomNavBar extends StatelessWidget {
  /// {@macro bottom_nav_bar}
  const BottomNavBar({required this.navigationShell, super.key});

  /// Navigation shell that will handle the navigation between the different
  /// bottom navigation bars.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final videoPlayer = VideoPlayerInheritedWidget.of(context);

    // Kept for the commented-out avatar tab below.
    // final user = context.select((AppBloc bloc) => bloc.state.user);

    // This product has three tabs. The router still has five branches, and
    // `goBranch` addresses them by position, so the visible tab is *mapped* to
    // its branch rather than the branches being renumbered. Renumbering would
    // silently repoint every route nested under them.
    //
    // Heute -> branch 0 (feed), Archiv -> branch 1 (timeline),
    // Mehr -> branch 4 (user). Branch 2 (create media) and branch 3 (reels)
    // are still there and are simply never addressed.
    const branchOfTab = <int>[0, 1, 4];

    // The upstream five-item builder is left alone; these three are built here
    // so nothing in `app_ui` had to change. Labels are tooltips only, since
    // both label rows are hidden; Phase 3 gives them German names.
    final navigationBarItems = <NavBarItem>[
      NavBarItem(
        icon: Icons.home_filled,
        label: context.l10n.homeNavBarItemLabel,
      ),
      NavBarItem(
        icon: Icons.grid_on_outlined,
        label: context.l10n.searchNavBarItemLabel,
      ),
      NavBarItem(
        icon: Icons.more_horiz,
        label: context.l10n.profileNavBarItemLabel,
      ),
    ];
    // final navigationBarItems = mainNavigationBarItems(
    //   homeLabel: context.l10n.homeNavBarItemLabel,
    //   searchLabel: context.l10n.searchNavBarItemLabel,
    //   createMediaLabel: context.l10n.createMediaNavBarItemLabel,
    //   reelsLabel: context.l10n.reelsNavBarItemLabel,
    //   userProfileLabel: context.l10n.profileNavBarItemLabel,
    //   userProfileAvatar: AnimatedCrossFade(
    //     firstChild: const Icon(Icons.person),
    //     secondChild: UserProfileAvatar(
    //       avatarUrl: user.avatarUrl,
    //       isLarge: false,
    //       radius: 18,
    //     ),
    //     crossFadeState:
    //         user.avatarUrl == null || (user.avatarUrl?.isEmpty ?? true)
    //         ? CrossFadeState.showFirst
    //         : CrossFadeState.showSecond,
    //     duration: 350.ms,
    //   ),
    // );

    final currentTab = branchOfTab.indexOf(navigationShell.currentIndex);

    return BottomNavigationBar(
      // A branch outside the three (nothing navigates there now, but the
      // branches still exist) would give -1, so it falls back to Heute.
      currentIndex: currentTab == -1 ? 0 : currentTab,
      onTap: (tab) {
        final branch = branchOfTab[tab];
        final isCurrent = branch == navigationShell.currentIndex;

        // The horizontal PageView is pinned in `home_page.dart`; this keeps its
        // state consistent with the tab anyway.
        HomeProvider().togglePageView(enable: branch == 0);

        if (branch case 0) {
          videoPlayer.videoPlayerState.playFeed();
        } else if (branch case 1) {
          videoPlayer.videoPlayerState.playTimeline();
        } else {
          videoPlayer.videoPlayerState.stopAll();
        }

        navigationShell.goBranch(branch, initialLocation: isCurrent);

        // Tapping Heute while already on it returns to the top.
        if (branch == 0 && isCurrent) FeedPageController().scrollToTop();
      },
      iconSize: 28,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      // With both label rows hidden, colour is the only thing saying which tab
      // you are on, and upstream left selected and unselected the same. Phase 3
      // replaces these two with ramp tokens.
      selectedItemColor: context.adaptiveColor,
      unselectedItemColor: context.adaptiveColor.withValues(alpha: 0.4),
      items: navigationBarItems
          .map(
            (e) => BottomNavigationBarItem(
              icon: e.child ?? Icon(e.icon),
              label: e.label,
              tooltip: e.tooltip,
            ),
          )
          .toList(),
    );
  }
}
