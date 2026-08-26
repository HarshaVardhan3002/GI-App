# UX walkthrough

Gletscherspalte, set in Fira Sans with Newsreader, rendered as diffusing glass.
This is every token, every material, every curve, and what the reader sees at
each moment.

**The clone is the executable ground truth.** Nothing here is written from
scratch that the fork already ships working.

**References:** Apple's material and vibrancy system, and the Tesla iOS app,
where the vehicle is rendered large and the interface dissolves around it. Our
equivalent is the endoscopic image. Both share the same discipline: deep ground,
content as the only bright thing, chrome that fades rather than ends.

---

## 1. Colour is a ramp, not three tokens

Hard-set tokens produce a visible step wherever two of them meet. The ground is a
continuous ramp of glacier-biased near-blacks, and a component asks for a
**depth between 0 and 1** rather than a named colour. Named stops are positions
on the ramp, not separate decisions.

| Depth | Dark | Light | Named |
|---|---|---|---|
| 0.00 | `#000000` | `#FFFFFF` | `surface` |
| 0.15 | `#04080B` | `#F7FAFC` | |
| 0.30 | `#080F14` | `#F1F5F9` | `surfaceRaised` |
| 0.45 | `#0C161D` | `#E9F0F6` | |
| 0.60 | `#122029` | `#E0EAF2` | `surfacePressed` |
| 0.80 | `#182A35` | `#D6E2EC` | |
| 1.00 | `#1E3542` | `#C9D8E4` | `separator` |

**No surface is neutral grey.** Every depth carries a trace of the tint hue, so
the ground reads as one material lit at different depths rather than as separate
greys stacked on each other. That is the mixture.

Text holds 12.55:1 or better at every depth on the ramp; secondary label on the
deepest surface is 6.98 dark and 5.85 light.

| Semantic | Light | Dark |
|---|---|---|
| `label` | `#0B1620` | `#FFFFFF` |
| `labelSecondary` | `#485A69` | `#9BAAB6` |
| `labelTertiary` | `#7A8B99` | `#6B7A86` |
| `tint` | `#0B6BB5` | `#3FA9F5` |
| `correct` | `#2E7D4F` | `#30D158` |
| `incorrect` | `#C0392B` | `#FF453A` |
| `warning` | `#B26A00` | `#FF9F0A` |

## 2. The material system

**The difference between glass and frost is not the blur. It is saturation.**

Flutter's `BackdropFilter` desaturates what sits behind it, which is why default
glass looks like fog. Apple's materials blur and push saturation back up, so
light appears to pass through rather than stop.

Native, no package required. `ColorFilter implements ImageFilter`, so:

```
BackdropFilter(
  filter: ImageFilter.compose(
    outer: ColorFilter.matrix(saturation(1.8)),
    inner: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
  ),
  child: ...,
)
```

| Material | Blur | Saturation | Tint | Where |
|---|---|---|---|---|
| Ultradünn | 18 | 1.8 | depth 0.30 at 24% | Over media: counter pill, placeholder badge |
| Normal | 26 | 1.8 | depth 0.30, graded 58% to 16% | App bar, bottom navigation |
| Dick | 40 | 1.5 | depth 0.15 at 88% | Sheets |

**Four rules that keep it a material and not decoration.**

1. **Bars and sheets only.** Glass means "floating over moving content". Never on
   cards, rows, badges sitting on a flat ground.
2. **No grain, no noise.** Film grain over blur is what makes frost read as
   dirty. The surface is clean or it is wrong.
3. **Fade, never stop.** Every material's trailing edge is masked to transparent
   over roughly 36dp. No hairline marks where chrome ends and content begins.
4. **Edges are light, not shadow.** A 1px inset highlight at 16% white on the
   leading edge, a 1px inset shade below. No cast shadows anywhere in the app.
   Elevation is carried by blur radius and edge light.

**Reduced transparency** collapses each material to an opaque surface at the same
depth. Nothing is lost but the effect.

**Cost, solved.** `BackdropFilter` forces a save-layer and reads back the
framebuffer, and it is still the most expensive thing we draw. Three things make
it shippable: `BackdropGroup` with `BackdropFilter.grouped` collapses every
material on a route into **one** shared backdrop pass; the `enabled` flag turns
the effect off with identical layout, so there is no second code path; and the
blurred area is bar-height, roughly 11% of the viewport, never full screen.
Never inside a list item. Measured before merge. Full treatment in
`docs/MATERIAL-IMPLEMENTATION.md`.

## 3. Motion

Everything eases. Nothing snaps. The Tesla app's weight comes from long, low
tension curves rather than from bounce.

| Moment | Curve | Duration |
|---|---|---|
| Feed to detail | `OpenContainer` fadeThrough | 420ms |
| Reveal rise | `easeOutExpo`, 24dp | 420ms, 60ms stagger |
| Answer selection | `easeOut` | 160ms |
| Sheet present | spring, low stiffness, high damping | ~500ms settle |
| Bar material fade on scroll | linear against scroll offset | continuous |
| Press feedback | `Tappable` scale to 0.97 | 120ms |

**No bounce anywhere.** An overshoot reads as playful, and nothing in this
product is playful.

**Haptics**, because half of what makes an Apple app feel expensive is felt
rather than seen:

| Event | Feedback |
|---|---|
| Answer selected | `HapticFeedback.selectionClick()` |
| Confirm pressed | `HapticFeedback.lightImpact()` |
| Reveal lands | nothing. The verdict is information, not an event |
| Sheet dismissed | `HapticFeedback.selectionClick()` |
| Pull to refresh triggers | `HapticFeedback.mediumImpact()` |

Deliberately no haptic on a correct answer. A buzz of congratulation is the
gamification the brief rules out, delivered through the one channel that cannot
be ignored.

`prefers-reduced-motion` collapses the reveal rise to a crossfade and the
container transform to a fade.

## 4. Injection: two files, then thirty-two sites

`packages/app_ui/lib/src/colors/app_colors.dart` holds 20 constants.
`packages/app_ui/lib/src/theme/app_theme.dart` builds both themes from them
through `FlexThemeData`, and `AppDarkTheme` already overrides the colour getters.
Add the ramp and the semantics to `AppColors`, point the two theme classes at
them, and **all 81 files importing `app_ui` inherit the palette untouched**,
because widgets read through `context.adaptiveColor`,
`context.customReversedAdaptiveColor` and `Theme.of(context)`.

277 hardcoded colour references exist, but they cluster in `reels`, `chats`,
`comments` and `share_post`, all hidden. **On shipped surfaces: 32.** That is
`feed/widgets` 9, `post_large` 8, `app_ui/widgets` 12, `timeline` 3.

Known offenders: `CarouselDotIndicator` hardcodes `Colors.blue.shade500` and
`Colors.grey`; `feed_loading_block` hardcodes its shimmer colours.

## 5. Splash

### The bug that ships today

`values-night/styles.xml` sets `Theme.Black.NoTitleBar` but points
`windowBackground` at `@drawable/launch_background`, hardcoded to
`@android:color/white`. **Every cold start on a dark-mode phone flashes white.**
Inherited, real, and visible on a projector.

### The sequence

1. **Frame zero, OS window.** Ground only, depth 0.00. No wordmark. This is on
   screen before Flutter exists.
2. **Wordmark.** *GI Daily* in Newsreader 400 at 28, `label`, optically centred
   and sitting at 46% of height rather than 50%, because centred text reads low.
3. **Flutter's first frame paints the same ground**, so the handover is
   invisible. The native splash colour and the app's depth 0.00 must be the same
   value in each mode or there is a seam.
4. **Feed fades up over 280ms.** The wordmark does not move to the app bar. A
   hero transition from splash to bar is the kind of flourish that looks
   expensive once and slow every time after.

Fix: add `drawable-night/launch_background.xml`.

**No animated splash.** Content loads from the bundle in under a frame budget,
so animation would pad a wait that does not exist.

## 6. Home: the Tageskarte

**Final: Tageskarte with diffused edges.** Today's case fills the viewport, its
lower edge dissolves, and there is nothing below it.

Zones on a 390x844 reference, top to bottom:

| Zone | Height | What |
|---|---|---|
| Status bar | 38 | System. Material passes under it, content does not |
| Top bar | 94 incl. safe area | Wordmark left, day right. Normal material, transparent at rest |
| Image | 66% of height | Full bleed, both edges, running under the status bar |
| Dissolve | 150 | Transparent to depth 0.00. Text sits **on** the dissolve |
| Meta and question | auto | 12 caps, then Newsreader 26, two lines maximum |
| Action | 44 target | *Fall öffnen*, the only tinted element on the screen |
| Peek | 10 | The top edge of yesterday, static |
| Bottom bar | 70 incl. safe area | Heute, Archiv, Profil. Normal material |

**The image has no bottom edge.** That is the whole diffused decision: image and
page are one surface, and nothing announces where the case stops.

**The attribution sits on the image**, white at 60% over the dissolve, never
collapsed or scrolled away, because it is a licence obligation rather than a
caption.

**Vertical swipe moves one day, snapped.** Native `PageView` with
`scrollDirection: Axis.vertical`; no package needed. It stops at today even when
tomorrow is approved and sitting in the bundle.

### Teaching the swipe without baiting it

1. **The peek**: 10dp of yesterday, permanent and static. Evidence, not
   invitation.
2. **One drift, once**: first launch only, the card rises 12dp and settles back
   over 600ms. Shown physically one time, then never.
3. **Archiv** reaches everything with no gesture at all.

No bouncing arrow, no "scroll" label, no pulsing chevron.

### Answered state

`hydrated_bloc`, already wired in the fork's bootstrap. One fact per case:
answered or not. No score, no streak, no history, nothing leaving the device. An
answered card reads *Auflösung ansehen* and opens straight to the reveal.

### Every tappable element

| Element | Gesture | Result |
|---|---|---|
| Anywhere on the card | tap | Detail, container transform from the image |
| *Fall öffnen* | tap | The same. It labels the gesture, it is not a second route |
| The image | swipe sideways | Next view of the same case. Opens nothing |
| The card | swipe up | Previous day, snapped |
| The card | swipe down | Later day, never past today |
| Wordmark | none | Identity, not a control |
| Heute | tap | Returns to today from any day |
| Archiv | tap | Contact sheet of every published day |
| Profil | tap | Appearance, language, attribution, rights, content status |

**One tinted thing per screen.** On the card it is *Fall öffnen*, and the tap
target is the whole lower half rather than the words.

## 7. Detail screen

**Entry.** `OpenContainer` from the feed card. The image is continuous through
the transition, so the reader never loses the thing they tapped. 420ms.

**Media, full width, pinch-zoomable** via `pinch_zoom_release_unzoom`. For an
endoscopic image this is expected, not a nicety: a Facharzt will want to look
closer at a pit pattern. On release it settles back with the same spring as the
sheet.

**Below it:** date and type at 13, then the question in **Newsreader at 26**,
`label`, tracking -0.02em. 26 rather than 22 because Newsreader is measurably
narrower than Fira Sans and the compound test allows it.

**Answers.** One inset grouped container at depth 0.30, hairline separators
inset to the text's leading edge. Not four cards. Rows 56 tall, minimum 44 touch
target, text in Fira Sans at 17/24.

- Idle: depth 0.30, `label`.
- Selected: depth 0.60, `tint` checkmark, 160ms ease, `selectionClick`.
- The container's corners are continuous, and only the first and last rows carry
  them, so the group reads as one pane rather than four.

**Confirm.** Full width, 50 tall, `tint` fill, `#FFFFFF` label, Fira Sans 17
semibold. Disabled until a selection exists; disabled dims the label rather than
removing the fill, so the control still says what it would do.

It sits **below the answers in the content flow, not pinned to the viewport**. A
pinned button covers the image on a small screen, and the reader passes the
answers to reach it anyway.

## 8. The reveal

The app's one authored motion moment. `flutter_animate` drives it, `sprung`
supplies the curve.

On confirm, in sequence, 60ms apart, each rising 24dp on `easeOutExpo`:

1. **Answers lock.** The correct row is marked `correct` whether or not it was
   chosen; a wrong choice is marked `incorrect`; every other row drops to
   `labelSecondary`. No row moves or resizes.
2. **Verdict.** One line: *Richtig* or *Nicht richtig*, Fira Sans 17 semibold in
   `correct` or `incorrect`. Nothing else on the line. No icon larger than 22.
3. **Begründung.** Fira Sans 17/24, `label`.
4. **The recommendation.** A grouped container at depth 0.30: the quote in
   **Newsreader 17/26**, then Konsensstärke, then the citation, then a source
   row. One container, so the quote can never be separated from its citation by
   a later layout change.

The quote's serif is the point at which our prose stops and the guideline's
begins, marked by the face rather than by quotation marks.

**Nothing bounces. Nothing celebrates. No haptic.** A correct answer at Facharzt
level is expected.

## 9. Source sheet

Presented as a sheet in Dick material, dragged from the source row, with the
screen behind scaling back and dimming to depth 0.15. Detent at 92% height.

Contents, in grouped containers: image credit per view, dataset, class, source
file, licence, holder; then guideline, publisher, AWMF register, version,
recommendation number, citation, URL; then the rights note; then who approved it
and when.

**This is where constraints 1 and 2 stop being claims.** A licence you cannot
inspect is a licence nobody should believe.

## 10. Archive and Profile

**Archive.** The `timeline` grid re-pointed at earlier cases, newest first,
excluding today's. Cells are 4:5 crops at depth 0.00 with 2dp gutters, so the
grid reads as a contact sheet rather than as tiles. Tapping opens the same
detail screen through the same container transform.

**Profile.** Not social. Appearance, language, and the screens the constraints
oblige: dataset attribution, guideline rights note, and the review status of the
content set. This is where `ATTRIBUTION.md` becomes visible in the product.

## 11. German text, measured

Content carries 26-character compounds. On a 360dp phone with 16dp gutters there
are 328dp of line, German does not break compounds, and Flutter does not
hyphenate.

Measured against the real font files:

| Face | `Argon-Plasma-Koagulation` at 22 | Ceiling |
|---|---|---|
| Newsreader | 256px | **29** |
| Fira Sans | 268px | 26 |

- **The question is 26, not 34.** A large-title treatment breaks on
  `Argon-Plasma-Koagulation`.
- **Nothing is centred.** Ragged-right on long compounds is legible; centred
  compounds produce visibly uneven rag.
- **Answer rows grow to two lines.** The longest current option is 62
  characters. A row that grows is correct; a row that ellipsises an answer is
  not, because the reader cannot choose what they cannot read.
- **Ellipsis only on the feed caption**, where truncation is intentional.
- **Soft hyphens** belong in the content, not in widgets. A schema concern.
- **Newsreader's optical size axis must be driven** through `FontVariation`, or
  the 26 question renders with the contrast of a 12 caption and looks brittle.

## 12. Everything is already in the tree

| Moment | Package | Already used by |
|---|---|---|
| Feed to detail | `animations` | in `pubspec.yaml` |
| Reveal | `flutter_animate` | `instagram_blocks_ui` |
| Curves | `sprung` | `instagram_blocks_ui` |
| Skeletons | `shimmer` | `app_ui` |
| Progressive image | `flutter_blurhash`, `octo_image` | `instagram_blocks_ui` |
| Carousel and dots | `carousel_slider`, `smooth_page_indicator` | `instagram_blocks_ui` |
| Pinch zoom | `pinch_zoom_release_unzoom` | `instagram_blocks_ui` |
| Scroll awareness | `visibility_detector`, `inview_notifier_list` | `FeedBody` |
| Archive grid | `flutter_staggered_grid_view`, `sliver_tools` | `timeline` |
| Press feedback | `Tappable` | `app_ui` |
| Material | `dart:ui` `ImageFilter.compose`, `BackdropGroup` | native |
| Haptics | `HapticFeedback` | native |
| Day paging | `PageView(scrollDirection: Axis.vertical)` | native |
| Answered state | `hydrated_bloc` | already in `bootstrap_local` |

**Nothing new is installed.**

## 13. Reuse ledger

| Surface | Source |
|---|---|
| Splash | Existing Android splash, recoloured, plus a night drawable |
| Home | `FeedPage` restructured to a vertical `PageView`, three render sites commented |
| Post | `PostLarge` kept whole; header content changed, footer hidden |
| Media, carousel, zoom | Existing widgets, re-pointed |
| Detail screen | **New composition** of existing widgets on the fork's post route |
| Answers, confirm | New widgets from `app_ui` primitives |
| Reveal | **New composition**, `flutter_animate` |
| Material | New, ~40 lines, `dart:ui` |
| Source sheet | New composition, existing sheet mechanics |
| Archive | `timeline` grid, re-pointed |
| Profile | `user_profile` scaffold, content replaced |
| Bottom nav | Existing, three items, indices mapped |
| Theme | Two files edited |

The only genuinely new code is the detail screen composition, the reveal, and
the material. Everything else is re-pointing something that already works.
