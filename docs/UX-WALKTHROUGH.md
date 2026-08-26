# UX walkthrough and colour injection

Gletscherspalte is final. This is where every token lands, what the reader sees
at each moment, and which existing package does each job.

The rule throughout: **the clone is the executable ground truth.** Nothing here
is written from scratch that the fork already ships working. Where a component
exists, it is re-pointed, not replaced.

---

## 1. The palette, final

Role-named. A widget that hardcodes a hex is a defect.

| Token | Light | Dark | What it is |
|---|---|---|---|
| `surface` | `#FFFFFF` | `#000000` | Page ground. True black in dark: the image floats, OLED disappears |
| `surfaceRaised` | `#F1F5F9` | `#101A22` | Cards, grouped rows, sheets, app bar fill |
| `surfacePressed` | `#E4EBF2` | `#18242E` | Pressed and selected states |
| `separator` | `#D5DDE6` | `#26333D` | Hairlines |
| `label` | `#0B1620` | `#FFFFFF` | Primary text |
| `labelSecondary` | `#485A69` | `#9BAAB6` | Supporting text |
| `labelTertiary` | `#7A8B99` | `#6B7A86` | Metadata, timestamps, captions |
| `tint` | `#0B6BB5` | `#3FA9F5` | Every interactive element, nothing else |
| `correct` | `#2E7D4F` | `#30D158` | Verdict only |
| `incorrect` | `#C0392B` | `#FF453A` | Verdict only |
| `warning` | `#B26A00` | `#FF9F0A` | Placeholder marking only |

Measured: text 18.26:1 light / 21:1 dark, secondary 7.14 / 8.82, tint 5.55 /
8.21. All clear AA. Tint sits 157 degrees from mucosa and 70 from verdict green.

## 2. Injection: two files, then thirty-two sites

The fork already centralises colour, which is why this is cheap.

**`packages/app_ui/lib/src/colors/app_colors.dart`** holds 20 constants.
**`packages/app_ui/lib/src/theme/app_theme.dart`** builds both themes from them
through `FlexThemeData`, and `AppTheme.primary` / `backgroundColor` are getters
that `AppDarkTheme` already overrides. Add the Gletscherspalte tokens to
`AppColors`, point the two theme classes at them, and **all 81 files that import
`app_ui` inherit the new palette with no edit of their own.**

The reason it propagates: widgets read colour through
`context.adaptiveColor`, `context.customReversedAdaptiveColor(light:, dark:)`
and `Theme.of(context)`, all of which resolve from those two files.

**The remaining work is widgets that bypass the theme.** 277 hardcoded colour
references exist across the app, but they cluster in screens this product hides:

| Area | Hardcoded refs | In scope? |
|---|---|---|
| `reels`, `chats`, `comments`, `share_post` | ~90 | No, hidden |
| `app_colors.dart` + `app_theme.dart` | 60 | Yes, these are the edit |
| **All shipped surfaces combined** | **32** | **Yes** |

Thirty-two sites: `feed/widgets` 9, `post_large` 8, `app_ui/widgets` 12,
`timeline` 3. That is the entire recolour beyond the theme files.

Two known offenders already identified: `CarouselDotIndicator` hardcodes
`Colors.blue.shade500` and `Colors.grey`; `feed_loading_block` hardcodes its
shimmer colours.

## 3. Token to component

Every component on a shipped surface.

| Component | Where | Tokens |
|---|---|---|
| App bar fill | `FeedAppBar` | `surfaceRaised` at 78% opacity, blurred |
| Wordmark | `AppLogo` | `label` |
| Feed ground | `FeedView` / `AppScaffold` | `surface` |
| Post header date | `PostHeader` | `labelTertiary` |
| Post header type pill | `PostHeader` | `surfaceRaised` fill, `labelSecondary` text |
| Media | `PostMedia` | none. The image is the colour |
| Carousel dots | `CarouselDotIndicator` | active `tint`, inactive `labelTertiary` at 40% |
| Image counter pill | `PostMedia` overlay | `#000` at 60%, white text. Fixed, not tokenised: it sits on photography in both modes |
| Attribution line | media overlay | white at 70% over scrim. Same reason |
| Placeholder badge | media overlay | `warning` fill, `surface` text |
| Caption / question | `PostCaption` | `label` |
| Answer row, idle | detail screen | `surfaceRaised` fill, `label` text |
| Answer row, selected | detail screen | `surfacePressed` fill, `tint` checkmark |
| Answer row, correct | after reveal | `correct` mark, `label` text |
| Answer row, wrong choice | after reveal | `incorrect` mark |
| Answer row, not chosen | after reveal | `labelSecondary` text |
| Confirm button, enabled | detail screen | `tint` fill, `#FFFFFF` label |
| Confirm button, disabled | detail screen | `surfaceRaised` fill, `labelTertiary` label |
| Verdict line | reveal | `correct` or `incorrect` |
| Recommendation card | reveal | `surfaceRaised`, `separator` hairlines |
| Quote | reveal | `label` |
| Citation | reveal | `labelTertiary` |
| Source row | reveal | `tint` label, `labelTertiary` chevron |
| Bottom nav, active | `BottomNavBar` | `label` |
| Bottom nav, inactive | `BottomNavBar` | `labelTertiary` |
| Skeletons | `feed_loading_block` | base `surfaceRaised`, highlight `surfacePressed` |

**Where the eye goes, by construction.** On the feed the only saturated thing is
the image, so it takes the eye first with nothing competing. On the detail screen
before answering, the only tinted element is the confirm button, so the eye lands
image, question, answers, button in that order without a single arrow or nudge.
After the reveal, `correct` or `incorrect` is the only new colour on screen and
it appears exactly once.

## 4. Splash

### The bug that ships today

`values-night/styles.xml` sets `Theme.Black.NoTitleBar` but points
`windowBackground` at `@drawable/launch_background`, which is hardcoded
`@android:color/white`. **Every cold start on a dark-mode phone flashes white
before the app paints.** It is inherited, it is real, and it would be visible on
a projector.

### What the reader should see

1. **Native window, frame zero.** Ground only: `#FFFFFF` light, `#000000` dark.
   No logo yet. This is the OS window, and it is on screen before Flutter exists.
2. **Wordmark, centred.** *GI Daily* in `label`, optically centred, sitting
   slightly above true centre.
3. **Flutter's first frame paints the same ground**, so the handover is
   invisible. This is the whole trick: the native splash background and the app's
   `surface` token must be the same value in each mode, or there is a flash at
   the seam.

Fix: add `drawable-night/launch_background.xml` with the dark ground, and set
both drawables' colour from the Gletscherspalte `surface` values.

**No animation on the splash.** Content loads from the bundle in well under a
frame budget, so an animated splash would be padding a wait that does not exist.
`lottie` is in the tree if that changes; it should not.

## 5. Feed

What the reader sees, top to bottom, on opening.

**App bar.** *GI Daily* left, nothing right. The chat icon is commented out. The
bar is `surfaceRaised` at 78% with a blur behind it, so the image scrolls under
it rather than stopping at it.

**No story row.** Commented out at `feed_page.dart:135`. Its absence is the first
signal that this is not the app it was forked from.

**The case.** Full-bleed 4:5 media, the widest thing on screen, edge to edge.
Above it a single line: `25. August · Therapiestrategie` in `labelTertiary`. No
avatar, no username, no verified tick. There is one publisher and putting its
face on every post is noise.

**Below the media:** the question as caption, `label`, two lines then ellipsis.
Truncation is deliberate. The full question lives on the detail screen, and a
truncated question is an invitation to open rather than a summary that replaces
it.

**No action row.** No like, comment, share, bookmark, no counts. Commented out in
`post_footer.dart`. This is the largest single visual difference from the fork,
and it is what makes the surface read as clinical rather than social.

**Then the next case, dated a day earlier.** The feed reads backwards in time.
Nothing dated ahead of today appears, even when approved and sitting in the
bundle.

**Bottom nav, three items.** Feed, Archiv, Profil. Active `label`, inactive
`labelTertiary`. No tint on the nav: the tint means "you can act on this", and a
tab you are already on is not an action.

## 6. Detail screen

Reached by tapping the post. `animations` provides `OpenContainer`, so the feed
card physically expands into the screen: the image is continuous through the
transition and the reader never loses the thing they tapped.

**Order down the screen:** media carousel, date and type, question in full,
answers, confirm.

**The image is pinch-zoomable** via `pinch_zoom_release_unzoom`, already in the
tree. For an endoscopic image this is not a nicety; a Facharzt will want to look
closer at a pit pattern, and the gesture is expected.

**Answers** are one inset grouped container with hairline separators, not four
cards. Four stacked cards is the shape every quiz app produces; a set of mutually
exclusive choices is a grouped list. Rows are 56 tall, minimum 44 touch target,
text `label` at 17/24.

**Confirm sits below the answers, full width, 50 tall**, `tint` filled. It is
disabled until a selection exists, and disabled dims the label rather than
removing the fill, so the control still says what it would do.

**Placement rationale:** the button is at the bottom of the content, not pinned
to the viewport. A pinned button would cover the image on a small screen, and the
reader has to pass the answers to reach it anyway.

## 7. The reveal

The app's one authored motion moment. `flutter_animate` drives it; `sprung`
supplies the curve.

**On confirm, in sequence:**

1. Answers stop being interactive. The correct row is marked `correct` whether or
   not it was chosen; a wrong choice is marked `incorrect`; everything else drops
   to `labelSecondary`.
2. **Verdict**, one line, `correct` or `incorrect`, 17/22 semibold. It says
   *Richtig* or *Nicht richtig* and nothing else.
3. **Begründung**, body text, `label`, 17/24.
4. **The recommendation**, a grouped container: quote, Konsensstärke,
   citation, and a source row, in that order and in one container so the quote
   can never be separated from its citation by a later layout change.

The whole block rises 24 with an exponential ease-out over 420ms, verdict
leading, roughly 60ms between elements. Nothing bounces. Nothing celebrates. A
correct answer at Facharzt level is expected, not an achievement.

`prefers-reduced-motion` collapses the rise to a crossfade.

**Source sheet** opens from the source row: dataset, licence, holder, guideline,
register number, rights note, who approved it. This is where constraints 1 and 2
become inspectable rather than claimed.

## 8. German text, measured

The content is full of compounds: `Zylinderepithelmetaplasie` at 25 characters,
`Los-Angeles-Klassifikation` at 26, `Argon-Plasma-Koagulation` at 24.

**That sets a ceiling on display type, and it is arithmetic rather than taste.**
On a 360dp screen with 16dp gutters there are 328dp of line.

Measured against the real font files, not estimated from an average advance:

| Face | `Argon-Plasma-Koagulation` at 22 | Ceiling |
|---|---|---|
| Newsreader | 256px | **29** |
| Fira Sans | 268px | 26 |

Newsreader is the narrower of the two, which is why the question is set in it at
**26** rather than pinned at 22.

Consequences:

- **The question is set at 26, not 34.** The large-title treatment that suits an
  English product breaks on `Argon-Plasma-Koagulation`.
- **No text is centred.** Ragged-right on long compounds is legible; centred
  compounds produce visibly uneven rag.
- **Answer rows wrap to two lines and are sized for it.** The longest current
  option is 62 characters. A row that grows is correct; a row that ellipsises an
  answer is not, because the reader cannot choose what they cannot read.
- **`softWrap` true, `overflow` visible on answers**, ellipsis only on the feed
  caption where truncation is intentional.
- **Soft hyphens.** Flutter does not hyphenate automatically. Where a compound
  must break, the break belongs in the content as `­`, which is a content
  pipeline concern and a schema note, not a widget concern.

Body text sits at 17/24 with a measure well under 65 characters at phone width,
so the long words never stack into a wall.

## 9. Motion, all of it already in the tree

Nothing new is installed.

| Moment | Package | Already used by |
|---|---|---|
| Feed card to detail | `animations` `OpenContainer` | in `pubspec.yaml` |
| Reveal choreography | `flutter_animate` | `instagram_blocks_ui` |
| Spring curves | `sprung` | `instagram_blocks_ui` |
| Loading skeletons | `shimmer` | `app_ui`, `feed_loading_block` |
| Progressive image load | `flutter_blurhash`, `octo_image` | `instagram_blocks_ui` |
| Media carousel | `carousel_slider` | `MediaCarousel` |
| Carousel dots | `smooth_page_indicator` | `instagram_blocks_ui` |
| Pinch zoom on the image | `pinch_zoom_release_unzoom` | `instagram_blocks_ui` |
| Scroll awareness | `visibility_detector`, `inview_notifier_list` | `FeedBody` |
| Archive grid | `flutter_staggered_grid_view`, `sliver_tools` | `timeline` |
| Press feedback | `Tappable` (scale and fade) | `app_ui` |

**Scroll physics, page transitions, image loading and tap response are
inherited untouched.** They are the reason the fork was worth forking, and any
change that makes a screen feel slower than the fork did is a regression.

## 10. Built from scratch: almost nothing

| Surface | Source |
|---|---|
| Splash | Existing Android splash, recoloured, plus a night drawable |
| Feed | `FeedPage` unchanged, two render sites commented |
| Post | `PostLarge` kept whole; header content changed, footer hidden |
| Media, carousel, dots, zoom | Existing widgets, re-pointed |
| Detail screen | **New composition** of existing widgets on the fork's existing post route |
| Answers, confirm | New widgets, built from `app_ui` primitives |
| Reveal | New composition, `flutter_animate` |
| Source sheet | New composition, existing sheet mechanics |
| Archive | `timeline` grid, re-pointed at cases |
| Profile | `user_profile` scaffold, content replaced |
| Bottom nav | Existing, three items, indices mapped |
| Theme | Two files edited |

The only genuinely new code is the detail screen's composition and the reveal.
Everything else is re-pointing something that already works.

## 11. Open

- **App icon.** Still unsolved.
