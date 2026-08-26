# Component map

The point of this file: when a component is touched, its blast radius is already
known. One hop, no hunting.

Read the two tables in §2 together. The first says *what a thing needs*; the
second says *what needs it*. A change is safe when the second column is empty
and dangerous in proportion to how long it is.

Scouted from the fork at commit `48f5dac`. 206 Dart files in `app/lib`, plus 22
local packages.

---

## 1. How the app is put together

```
main_local.dart no Firebase, no PowerSync
 └── bootstrap_local.dart error handler, bloc observer, hydrated storage,
 │ portrait lock
 └── App RepositoryProviders + AppBloc, LocaleBloc,
 │ ThemeModeBloc, FeedBloc
 └── AppView MaterialApp.router + theme
 └── AppRouter go_router, redirects on auth state
 └── HomePage / HomeView
 ├── PageView ← horizontal: chats | home | create-media
 └── StatefulNavigationShell
 ├── branch 0 FeedPage ← the product
 ├── branch 1 TimelinePage (search grid)
 ├── branch 2 CreateMedia
 ├── branch 3 ReelsPage
 └── branch 4 UserProfilePage
 └── BottomNavBar
```

### The feed, in detail

```
FeedPage
 └── FeedView AppScaffold + NestedScrollView
 ├── FeedAppBar ← AppLogo (Instagram wordmark) + chat icon
 └── FeedBody RefreshIndicator + InViewNotifierCustomScrollView
 ├── StoriesCarousel ← "Your story" row
 └── FeedPageListView SliverList of InstaBlocks
 └── _buildBlock() switch on block type
 ├── PostLargeBlock → PostView → PostLargeView → PostLarge
 ├── PostSponsoredBlock → sponsored variant
 ├── DividerHorizontalBlock
 ├── SectionHeaderBlock
 └── unknown → Text('Unknown block type')
```

`PostLarge` (in `packages/instagram_blocks_ui`) is composed of:

| Part | What it renders | Keep? |
|---|---|---|
| `PostHeader` | avatar, username, verified tick, options menu | Rework - it is the case's date/type line |
| `PostMedia` | the media carousel + dot indicator | **Keep.** This is the hook |
| `PostFooter` | like, comment, share, bookmark, likes count, comments count | **Hide.** No engagement in this product |
| `PostCaption` | author + caption text | Rework - it is the question |

---

## 2. Dependency tables

### 2.1 What each feature needs

| Feature | Imports | Local packages it leans on |
|---|---|---|
| `app` | auth, chats, feed, home, reels, search, selector, stories, timeline, user_profile | app_ui, shared, user_repository, all repositories |
| `auth` | app | form_fields, app_ui, user_repository |
| `chats` | app, home, stories | chats_repository, shared |
| `comments` | app, stories | posts_repository, shared |
| `feed` | app, comments, home, stories, user_profile | instagram_blocks_ui, posts_repository, shared, app_ui |
| `home` | chats, feed, navigation, stories, user_profile | app_ui, user_repository |
| `navigation` | app, feed, home | app_ui |
| `reels` | app, comments, feed, stories | instagram_blocks_ui, posts_repository |
| `search` | app, stories | search_repository |
| `selector` | - | app_ui |
| `stories` | app | stories_repository, stories_editor |
| `timeline` | feed, search | search_repository, instagram_blocks_ui |
| `user_profile` | app, feed, home, selector, stories | user_repository, posts_repository |
| `network_error` | - | app_ui |

### 2.2 What depends on each feature - the blast radius

Sorted most dangerous first. This is the column that matters before touching
anything.

| Feature | Depended on by | Risk of changing it |
|---|---|---|
| `app` | auth, chats, comments, feed, navigation, reels, search, stories, user_profile - **9** | **Highest.** Routes, AppBloc and theme live here. Touch surgically |
| `feed` | app, home, navigation, reels, timeline, user_profile - **6** | **High.** The product's own screen, and four others reuse its widgets |
| `stories` | app, chats, comments, feed, reels, search, user_profile - **7** | **High**, and it is on the removal list. Hide render sites only |
| `home` | app, chats, feed, navigation, user_profile - **5** | High. Owns the shell and the horizontal PageView |
| `user_profile` | app, feed, home - **3** | Medium |
| `comments` | feed, reels - **2** | Low. Both call sites are known |
| `search` | app, timeline - **2** | Low |
| `chats` | app, home - **2** | Low |
| `selector` | app, user_profile - **2** | Low |
| `navigation` | home - **1** | Low |
| `auth` | app - **1** | Low. Unreachable once login is bypassed |
| `reels` | app - **1** | Low |
| `timeline` | app - **1** | Low |
| `network_error` | - | None |

### 2.3 Local packages, by how much the app leans on them

| Package | Files importing it | Verdict |
|---|---|---|
| `shared` | 83 | Load-bearing. Models, extensions, utilities |
| `app_ui` | 81 | Load-bearing. **The design system - where the visual rebrand happens** |
| `user_repository` | 40 | Load-bearing |
| `instagram_blocks_ui` | 32 | Load-bearing. Post anatomy lives here |
| `posts_repository` | 22 | Load-bearing |
| `stories_repository` | 15 | Backed by local stubs |
| `chats_repository` | 9 | Backed by local stubs |
| `search_repository` | 7 | Backed by local stubs |
| `notifications_repository` | 7 | Local stand-in |
| `powersync_repository` | 6 | **Dead weight.** Still imported for types only |
| `firebase_remote_config_repository` | 6 | Local stand-in |
| `form_fields` | 4 | Auth only |
| `env` | 3 | **Dead.** Only the old entrypoints read it |
| `database_client` | 3 | Interface only - the seam |
| `stories_editor` | 2 | Removal list |
| `local_content_client` | 1 | **Ours.** The whole local backend |
| `insta_blocks` | 1 | Block models |
| `image_picker_plus`, `gallery_media_picker` | 0 | Transitive only |

---

## 3. Where the Instagram identity actually lives

Every site, so the rebrand is one pass and not a hunt.

| Location | What it is |
|---|---|
| `packages/app_ui/assets/images/instagram_text_logo.svg` | The wordmark asset |
| `packages/app_ui/lib/src/widgets/app_logo.dart` | `AppLogo`, which renders it |
| `lib/feed/widgets/feed_app_bar.dart:17` | Wordmark in the feed header |
| `lib/feed/post/widgets/post_preview.dart:29` | Wordmark in post preview |
| `lib/auth/login/view/login_page.dart:38` | Wordmark on login |
| `lib/auth/sign_up/view/sign_up_page.dart:49` | Wordmark on sign-up |
| `packages/app_ui/assets/icons/instagram-reel.svg` | Reel icon |
| `android/app/build.gradle:85,90,95` | `appName` per flavor |
| `android/app/build.gradle:53` | `applicationId com.emilzulufov.…` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` |
| `packages/app_ui/lib/src/generated/assets.gen.dart` | Generated refs to the above |

Package name `flutter_instagram_offline_first_clone` appears in **every** file's
imports. Renaming it is a repo-wide edit and is deliberately **out of scope for
the demo** - it is churn with no visible benefit and a large regression surface.
The user-facing name, the wordmark and the app label are what matter.

---

## 4. What gets hidden, and exactly where

Per `CLAUDE.md` §3: comment out the render site, keep the widget, the bloc, the
repository method and the model.

| Feature | Render sites to comment | Blast radius if done wrong |
|---|---|---|
| Stories carousel | `lib/feed/view/feed_page.dart:135` | Feed only. `StoriesCarousel` stays intact |
| Like / comment / share / bookmark | `packages/instagram_blocks_ui/lib/src/post_large/post_footer.dart:56-150` | **Every post everywhere** - feed, reels, timeline. Highest-touch edit in the plan |
| Comments count line | same file, ~line 141 | As above |
| Bottom nav: search, create, reels, profile | `packages/app_ui/lib/src/constants/data.dart:14-18` and `lib/navigation/view/bottom_nav_bar.dart` | The router's `StatefulNavigationShell` has 5 branches; hiding items must not renumber branch indices |
| Chat icon in app bar | `lib/feed/widgets/feed_app_bar.dart:21` | Feed only |
| Horizontal PageView (chats / create) | `lib/home/view/home_page.dart` | `HomeProvider().animateToPage(2)` is called from the app bar - remove the caller in the same pass |

**The one to be careful with:** `PostFooter`. It is a single file that renders on
every post surface in the app, and `PostLargeView` passes it seven callbacks
(`likePost`, `isLiked`, `commentsCount`, `onCommentsTap`, `onPostShareTap`, …).
Commenting out the row is fine; deleting the parameters would break `PostLarge`'s
constructor and every call site in feed, reels and timeline.

---

## 5. Seams left open for a real backend

The whole reason the app runs with no network. A backend arrives by implementing
these, not by editing screens.

| Seam | Interface | Local implementation |
|---|---|---|
| Data | `DatabaseClient` (abstract, ~49 members) | `LocalDatabaseClient` |
| Auth | `AuthenticationClient` (8 members) | `LocalAuthenticationClient` |
| Feature flags | `FirebaseRemoteConfigRepository` | `LocalRemoteConfigRepository` |
| Push | `NotificationsRepository` | `LocalNotificationsRepository` |
| Content | `assets/content/*.json` | `LocalContentSource` |

Swapping to a real backend is one edit in `lib/main_local.dart`. Nothing above
the data layer changes. **Do not let widget code reach around these.**

---

## 6. Known dead weight

Not to be deleted - recorded so nobody mistakes it for load-bearing.

- `packages/powersync_repository` - imported for types only; no PowerSync runs.
- `packages/env` - read only by `main_development/staging/production.dart`,
 which this product does not use.
- `main_development.dart`, `main_staging.dart`, `main_production.dart` - the
 upstream entrypoints. They still require Firebase and Supabase and will not
 boot. `main_local.dart` is the one that runs.
- `lib/feed/view/feed_test_page.dart` - upstream scratch file.
