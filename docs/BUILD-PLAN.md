# Build plan

Ordered so that each step is verifiable on its own and nothing later depends on
a decision not yet made. Read `docs/COMPONENT-MAP.md` for blast radius and
`DESIGN.md` for the visual decisions. `CLAUDE.md` governs how the work is done.

**Nothing in this file has been implemented.** This is the plan.

---

## Ground rules for every step

1. Touch the render site, not the widget. Comment out with a one-line reason.
2. Never delete a file, a parameter, a bloc or a repository method.
3. After each step, a **scoped subagent** verifies on the live emulator. The
   brief is written before the step starts — it is in each step below.
4. Any string that reaches a user goes through `humanizer` first.
5. Any visual decision comes from `DESIGN.md`, not from taste in the moment.

**Definition of done for a step:** it builds, the subagent's checks pass on the
emulator, no regression in scroll feel, and the report names anything it could
not verify.

---

## Phase 1 — Identity

Licensing depends on this, not just looks. See `ATTRIBUTION.md`.

### 1.1 Replace the wordmark
`packages/app_ui/lib/src/widgets/app_logo.dart` renders *GI Daily* as text
instead of the SVG. Four call sites pick it up unchanged: feed app bar, post
preview, login, sign-up.

- **Touches:** 1 file. **Blast radius:** 4 known call sites, all cosmetic.
- **Delete `instagram_text_logo.svg`?** No — remove the reference; the asset goes
  in a later sweep once nothing points at it.

### 1.2 App label and identifiers
`android/app/build.gradle` `manifestPlaceholders` (3 flavors) and
`ios/Runner/Info.plist` `CFBundleDisplayName` → *GI Daily* / *[DEV] GI Daily*.

- **Not in scope:** the Dart package name `flutter_instagram_offline_first_clone`.
  It appears in every import in the repo; renaming is repo-wide churn with a
  large regression surface and nothing visible to show for it.
- **applicationId:** left alone for the demo. Changing it is a fresh install and
  a new signing identity for no jury-visible benefit.

### 1.3 Remaining marks
`instagram-reel.svg` unreferenced once reels are hidden. Record, sweep later.

> **Subagent brief 1:** Build `flutter build apk --debug --flavor development -t
> lib/main_local.dart`, install, launch. Screenshot the feed. Report: (a) does
> the header read "GI Daily" with no Instagram wordmark, (b) app label under the
> icon in the launcher, (c) any layout shift in the header versus the previous
> screenshot. Do not read source files. Do not fix anything.

---

## Phase 2 — Hide what this product does not have

Per `CLAUDE.md` §3, all of this is commenting out render sites.

### 2.1 Post footer — the dangerous one
`packages/instagram_blocks_ui/lib/src/post_large/post_footer.dart`, the action
row and the counts.

- **Blast radius: every post surface in the app** — feed, reels, timeline,
  post detail. This is the highest-touch edit in the plan.
- **Keep the constructor intact.** `PostLargeView` passes seven callbacks
  (`isLiked`, `likePost`, `commentsCount`, `onCommentsTap`, `onPostShareTap`, …).
  Comment the *rendering*, not the parameters. Removing a parameter breaks
  `PostLarge`'s signature and every call site.
- `PostBloc` keeps running and keeps returning zeros from the local client. That
  is fine and is the cheapest way to keep it reversible.

### 2.2 Stories carousel
`lib/feed/view/feed_page.dart:135`. Feed only. `StoriesCarousel` untouched.

### 2.3 Chat entry point
`lib/feed/widgets/feed_app_bar.dart:21`. Remove the caller and the
`HomeProvider().animateToPage(2)` it triggers in the same pass, or the
horizontal `PageView` becomes reachable with no way back.

### 2.4 Bottom navigation → three tabs
`packages/app_ui/lib/src/constants/data.dart` and
`lib/navigation/view/bottom_nav_bar.dart`.

- **The trap:** the router's `StatefulShellBranch` list has five branches and
  `navigationShell.goBranch(index)` is positional. Hiding items must **map** the
  visible index to the original branch index, never renumber the branches.
- Feed → branch 0, Archive → branch 1 (timeline), Profile → branch 4.

> **Subagent brief 2:** Build, install, launch. Then: (a) screenshot the feed and
> confirm no story row, no like/comment/share/bookmark row, no chat icon; (b) tap
> each of the three bottom tabs in turn and screenshot each, confirming the tab
> that opens matches its label; (c) scroll the feed to the bottom and back and
> report whether scrolling is smooth or stutters. Report exactly what you saw.
> Do not read source files. Do not fix anything.

---

## Phase 3 — The case detail screen

The product's actual payoff. Tapping a post opens it.

- Reuse the fork's existing post route (`AppRoutes.post`, `/posts/:id`) rather
  than adding navigation.
- Screen order, from `DESIGN.md` §7 and §9: image carousel → date and question
  type → question → four answers → confirm → reveal (verdict, reasoning,
  recommendation) → source sheet.
- Answers are an inset grouped list, not four cards.
- The reveal is the app's one authored motion moment.
- The quiz state (`selected`, `revealed`) is screen-local. It is not persisted,
  because nothing about a reader is stored anywhere.

**Data need:** `LocalDatabaseClient.caseOf(postId)` already returns the quiz and
provenance the feed's `Post` model does not carry. The seam exists; the screen
consumes it.

> **Subagent brief 3:** Build, install, launch. Tap the first post in the feed.
> Then: (a) screenshot the detail screen; (b) tap the second answer, screenshot;
> (c) tap confirm, screenshot the reveal; (d) tap "Quelle", screenshot the sheet;
> (e) press back twice and confirm you land on the feed. Report each screenshot
> and any frame drop or visual glitch. Do not read source files.

---

## Phase 4 — Archive and Profile

- **Archive:** reuse the timeline grid as earlier cases, newest first, excluding
  today's. Tapping a cell opens the same detail screen from Phase 3.
- **Profile:** not social. Language, appearance, and the screens constraints 1
  and 2 oblige — dataset attribution, guideline rights note, review status of the
  content set. This is where `ATTRIBUTION.md` becomes visible in the product.

> **Subagent brief 4:** Written when the screens exist, in the same shape as
> briefs 1–3.

---

## Phase 5 — Glass and polish

Only after structure is right. Glass on an unfinished screen hides problems.

- App bar and bottom nav become translucent over scrolling content
  (`liquid_glass_renderer`, `BackdropFilter` fallback).
- Sheets get the same material.
- **Nowhere else** — see `DESIGN.md` §4.
- Re-add `liquid_glass_renderer`, `flutter_animate` and `gap` to `app/pubspec.yaml`
  (they were added to the abandoned second app, not this one).

> **Subagent brief 5:** Build on a physical-GPU emulator. Scroll the feed
> continuously for ten seconds with the app bar over moving media, screenshot
> mid-scroll, and report any shader artefact, banding, or dropped frames. Report
> the device and GPU mode used.

---

## Phase 6 — Content pass

- Every German string in `assets/content/*.json`, plus every UI string, through
  `humanizer`. The existing placeholder content has **not** been checked and is
  known to contain AI-writing tells.
- Replace placeholder images with a real HyperKvasir/GastroVision run once the
  dataset is on disk (`pipeline/scripts/build_image_bank.py`).
- Replace placeholder recommendations with a real AWMF extraction
  (`pipeline/scripts/extract_recommendations.py`, untested against a real PDF).
- Physicians approve through `npm run review`. Nothing renders until they do.

---

## Sequencing, and why

Identity first because it is a **licensing obligation**, not decoration. Hiding
second because it shrinks the surface everything later has to work against.
Detail screen third because it is the product and needs the most attention.
Archive and profile fourth because they are supporting. Glass fifth because
polish applied to unfinished structure hides what is wrong with the structure.
Content last because it depends on physicians and datasets that are not here yet,
and because it is the one phase that does not block a demo.

## Not in scope for the hackathon

Recorded so the decision is deliberate rather than forgotten.

- Renaming the Dart package.
- Deleting hidden features, dead packages, or unreferenced assets.
- A real backend. The seams are open; nothing is built behind them.
- Push notifications, which the daily habit will eventually need.
- iOS verification. There is no Simulator on Windows; anything about iOS gesture
  feel is unverified and must be reported that way.
