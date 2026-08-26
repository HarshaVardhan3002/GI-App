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

  /// The row of labels, above the home indicator's inset. 49 is the height a
  /// tab bar has on iOS, and a 49dp row makes each label a target well past
  /// the 44 minimum in `DESIGN.md` section 6.
  static const double barHeight = 49;

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
    // so nothing in `app_ui` had to change. The labels are what the bar draws,
    // and they have their own keys rather than borrowing Instagram's: calling
    // Archiv `searchNavBarItemLabel` would have been a lie in the source. The
    // icons are carried but unused, since `NavBarItem` requires one.
    final navigationBarItems = <NavBarItem>[
      NavBarItem(
        icon: Icons.home_filled,
        label: context.l10n.todayNavBarItemLabel,
      ),
      NavBarItem(
        icon: Icons.grid_on_outlined,
        label: context.l10n.archiveNavBarItemLabel,
      ),
      NavBarItem(
        icon: Icons.more_horiz,
        label: context.l10n.moreNavBarItemLabel,
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

    void onTabTapped(int tab) {
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

      GiHaptics.selection(context);
    }

    return GiMaterial(
      edge: VerticalDirection.down,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: BottomNavBar.barHeight,
          child: Row(
            children: [
              for (var tab = 0; tab < navigationBarItems.length; tab++)
                Expanded(
                  child: _NavBarLabel(
                    label: navigationBarItems[tab].label ?? '',
                    isCurrent: tab == (currentTab == -1 ? 0 : currentTab),
                    onTap: () => onTabTapped(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// {@template nav_bar_label}
/// One tab: its name, and whether you are on it.
///
/// **A word, not a pictogram.** Three destinations named in Fachsprache do not
/// need icons to tell them apart, and the fork's icons were a house, a grid and
/// an ellipsis borrowed from an app about photographs. Weight carries the
/// selection, the way `docs/SCREENS.md` draws it.
/// {@endtemplate}
class _NavBarLabel extends StatelessWidget {
  const _NavBarLabel({
    required this.label,
    required this.isCurrent,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.gi;
    return Tappable.faded(
      onTap: onTap,
      backgroundColor: Colors.transparent,
      child: Center(
        child: Text(
          label,
          style: GiText.caption.copyWith(
            color: isCurrent ? colors.label : colors.labelTertiary,
            fontWeight: isCurrent ? AppFontWeight.semiBold : null,
          ),
        ),
      ),
    );
  }
}
