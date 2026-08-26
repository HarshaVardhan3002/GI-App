# Phases 2 to 12

The whole remaining build, ordered so that each phase leaves a running app and
nothing later depends on a decision not yet made. Supersedes `docs/BUILD-PLAN.md`
from Phase 2 onward; that file stays as the record of what was planned before the
app was scouted properly.

`CLAUDE.md` governs how the work is done. `DESIGN.md` and `docs/SCREENS.md` hold
what it should look like. `docs/COMPONENT-MAP.md` holds blast radius.

**Definition of done for a phase:** it builds, the scoped subagent's checks pass
on `pixel8_api36`, the report names anything it could not verify, and it is
committed and pushed on its own.

---

## What scouting the tree changed about this plan

Four things, found by reading the code rather than assuming it.

1. **There is no German locale.** `lib/l10n/arb/` holds `app_en.arb` and
   `app_ru.arb`, 173 keys. `LocaleBloc` defaults to `Locale('en', 'US')`.
   Constraint 4 says German UI. That is a phase, not a content detail, and it
   has to land before screens are written or every new screen bakes in English.

2. **Hiding the chat icon does not hide chat.** `home_page.dart` builds a
   horizontal `PageView` of three pages: camera, the app, chats. Removing the
   icon leaves both reachable by swipe. The physics have to be pinned as well.

3. **The detail screen needs a seam that does not exist.** `LocalDatabaseClient`
   has `caseOf(postId)`, carrying the quiz and provenance. The abstract
   `DatabaseClient` does not, and `PostsRepository` cannot reach it. A narrow
   interface has to be introduced rather than a cast.

4. **Archiv needs to remember answers.** `docs/SCREENS.md` puts a marker on
   answered cases. The earlier note that quiz state is screen-local was written
   before that. Resolved in Phase 6, deliberately.

---

## Phase 2 - Subtract

Comment out render sites. Nothing is deleted, every block carries its reason.

| Target | File | Note |
|---|---|---|
| Action row and counts | `packages/instagram_blocks_ui/lib/src/post_large/post_footer.dart` | **Highest blast radius in the plan.** Renders on every post surface. Comment the *rendering*; the seven callbacks from `PostLargeView` stay in the signature |
| Stories carousel | `lib/feed/view/feed_page.dart` | `StoriesCarousel` and the divider under it |
| Chat entry | `lib/feed/widgets/feed_app_bar.dart` | The action, and the `HomeProvider().animateToPage(2)` it calls |
| Camera and chat by swipe | `lib/home/view/home_page.dart` | Pin `physics` to `NeverScrollableScrollPhysics`. Without this the icon is gone and the pages are not |
| Five tabs to three | `packages/app_ui/lib/src/constants/data.dart`, `lib/navigation/view/bottom_nav_bar.dart` | **Map, never renumber.** `goBranch` is positional: Heute 0, Archiv 1, Mehr 4 |

No strings change here. Tab labels are tooltips and are not drawn.

> **Brief 2.** Build, install, launch. (a) Screenshot the feed: confirm no story
> row, no like/comment/share/bookmark row, no chat icon. (b) Swipe left, then
> right, from the feed; screenshot after each and report whether anything other
> than the feed appears. (c) Tap each of the three tabs and screenshot each.
> (d) Scroll the feed to the bottom and back; report smooth or stutters.

---

## Phase 3 - Foundations

Nothing new on screen. This is the vocabulary every later phase spends, and it
is the phase most likely to be skipped and most expensive to skip.

- **Fira Sans** bundled beside Newsreader, SIL OFL, recorded in
  `ATTRIBUTION.md`.
- **The ramp.** `DESIGN.md` §3 is a continuous ramp, so the API is
  `depth(double)` interpolating the seven stops per theme, not seven named
  constants. Semantic tokens on top: `label`, `labelSecondary`, `labelTertiary`,
  `tint`, `correct`, `incorrect`, `warning`.
- **The type scale.** The eight roles from `DESIGN.md` §5, with `opsz` wired to
  the rendered size wherever Newsreader is used.
- **German.** `app_de.arb`, and `LocaleBloc` defaults to `Locale('de', 'DE')`.
  Keys that belong to hidden features stay English and are listed in
  `lib/l10n/untranslated_messages.json` rather than machine-translated, because
  an unreviewed German string in a medical product is worse than an English one
  nobody sees.
- **Haptics.** One helper, so feedback is consistent and can be switched off in
  one place.

> **Brief 3.** Build, install, launch in German. Screenshot the feed and each
> tab. Report: the exact background colour of the feed sampled at three points,
> whether any visible string is still English, and any text that is clipped,
> overlapping, or unreadable against its background.

---

## Phase 4 - Heute, the Tageskarte

The home screen becomes one case per screen, swiped vertically.

- Vertical `PageView`, native, one `TageskarteView` per case.
- Image top-anchored, full width, height = width x 1.25, never cropped by
  layout. Dissolve beneath it.
- Text block bottom-anchored above `bottomBar + peek + margin`: carousel dots,
  meta line, the question in Newsreader 26 capped at two lines, *Fall öffnen* as
  the only tinted element, attribution as the last line.
- 10dp peek of the next card above the bottom bar.
- The old `FeedBody` scroll view is commented out, not deleted.

**The collision arithmetic in `docs/SCREENS.md` is the acceptance test, not a
sketch.** Worst case is 96dp of overlap on a 360x640 against a 150dp dissolve.

> **Brief 4.** Build, install. Then: (a) screenshot Heute; (b) swipe up three
> times, screenshot each; (c) run `adb shell wm size 360x640` and
> `wm density 240`, relaunch, screenshot, and report whether any text touches or
> overlaps the image edge or the bottom bar; (d) restore with `wm size reset`
> and `wm density reset`. Report the two-line cap holding or breaking.

---

## Phase 5 - Fall, the case

The product's payoff, and the phase that gets the most attention.

- **The seam first.** A narrow `CaseSource` interface exposing `caseOf`,
  implemented by `LocalDatabaseClient`, provided in `main_local.dart`. No casts,
  no reaching through `PostsRepository` into a concrete class.
- Route: the fork's existing `/posts/:id`. No new navigation.
- Before answering: image at 40% with a shorter dissolve, meta, the question in
  full, four answers as one inset group, *Antwort bestätigen* full width.
- After: verdict on one line, `BEGRÜNDUNG` and the explanation, then
  `EMPFEHLUNG x.y · GRAD` and one inset group holding the quote in Newsreader,
  the Konsensstärke, the citation, and *Quelle* as a disclosure row. Quote and
  citation are rows of the same group so no later layout change can separate
  them.
- **Herkunft** as a sheet: placeholder warning first when it applies, then
  Bildnachweis per image, Leitlinie, Freigabe. The guideline link says it leaves
  the app before it does.
- Quiz state is screen-local. What is remembered lives in Phase 6.

> **Brief 5.** Build, install. Tap the first card. (a) Screenshot. (b) Tap the
> second answer, screenshot. (c) Tap confirm, screenshot. (d) Scroll to the
> bottom of the revealed screen, screenshot. (e) Tap *Quelle*, screenshot, then
> drag the sheet down. (f) Press back and confirm you land on Heute. Report any
> frame drop, clipped text, or element that moved when it should not have.

---

## Phase 6 - Archiv

- Branch 1's timeline page is replaced by a two-column contact sheet at 4:5,
  2dp gutters, sticky month header, date over a scrim per cell.
- Tapping a cell opens the Phase 5 screen.

**Decision, taken deliberately.** `docs/SCREENS.md` marks answered cases, which
needs memory, and Phase 5 says quiz state is not persisted. Both can be true: an
`AnswersBloc` on `hydrated_bloc` stores `{postId: optionId}` **on the device
only**. Nothing about a reader is sent anywhere, because there is nowhere to send
it. It is local convenience, not a user record, and it goes with the app. This is
written down here rather than discovered later in a diff.

> **Brief 6.** Build, install. (a) Screenshot Archiv. (b) Tap the second cell,
> screenshot what opens, answer it, press back, screenshot Archiv again and
> report whether that cell now shows a marker. (c) Force-stop, relaunch, open
> Archiv, report whether the marker survived.

---

## Phase 7 - Mehr

Branch 4's profile is replaced. Three groups, no tinted element, every
sub-screen exactly one push deep.

- **Darstellung:** Erscheinungsbild, Sprache
- **Herkunft der Inhalte:** Bildquellen, Leitlinien und Rechte, Inhaltsstatus
- **Über:** Über GI Daily, Impressum, Version

**Inhaltsstatus** counts approved, draft and rejected, and how many images and
recommendations are still placeholders, read from `LocalContentSource`. It is
the honesty constraint made inspectable in ten seconds.

**Impressum** is a legal obligation for a German app-store product, not a page
we chose. It ships with the team's details as clearly marked blanks, because
inventing them would be worse than leaving them empty.

> **Brief 7.** Build, install. Screenshot Mehr. Tap every row in turn; after
> each, screenshot what opens and press back. Report any row that opens the
> wrong screen, opens nothing, or pushes more than one level.

---

## Phase 8 - Material

Structure first, glass second, per `docs/MATERIAL-IMPLEMENTATION.md`.

- One `BackdropGroup` per route; `BackdropFilter.grouped` on the top and bottom
  bars only.
- `ImageFilter.compose(outer: saturation ColorFilter, inner: blur)`. The
  saturation is what separates glass from frost.
- A `MaterialQuality` inherited value drives an `enabled` flag on every filter.
  False keeps the layout identical and paints the tint opaque instead.
- Never inside a list item. The image itself is never filtered, anywhere.

> **Brief 8.** Build `--profile`. Scroll Heute continuously for ten seconds and
> report worst frame time and count of frames over 16ms. Repeat with the kill
> switch off. Report both side by side, and the device and GPU mode.

**Acceptance:** with the material on, frame times match the fork with it off. If
not, sigma comes down before anything else is touched.

---

## Phase 9 - Motion and edges

- The reveal is the app's one authored motion moment.
- Page transitions, the peek's one-time 12dp drift on first launch, haptics at
  selection and reveal.
- `MediaQuery.disableAnimations` respected everywhere.

> **Brief 9.** Build. Record the reveal and one Heute swipe as GIFs. Report any
> stutter, any animation that plays twice, and whether anything still animates
> after enabling *Remove animations* in accessibility settings.

---

## Phase 10 - Identity, finished

- **The app icon.** Phase 1 proved this is not optional: from Android 12 the
  launcher icon is the launch screen. Adaptive icon, every mipmap density, and
  the iOS asset set. It will be built to `DESIGN.md`, and it is the one thing in
  this stack the team may simply want different. It is reversible in one commit.
- Remaining unreferenced upstream assets are recorded, not deleted.

> **Brief 10.** Build, install. Screenshot the launcher showing the icon and its
> label, and a cold start in both themes.

---

## Phase 11 - Content and strings

- Every visible string, German and English, through `humanizer`.
- Every string in `assets/content/*.json` likewise. **The existing placeholder
  content has never been checked and is known to contain AI-writing tells.**
- `CLAUDE.md` §8 enforced: no em-dash in English, German Gedankenstrich kept, no
  invented precision, placeholders that read as placeholders.

> **Brief 11.** Build, install. Screenshot every screen and transcribe every
> visible string exactly. Report any string that is clipped, grammatically
> broken, still English, or still reads as though a machine wrote it.

---

## Phase 12 - The adversary

A Sonnet subagent walks the whole app as a hostile reviewer: every screen, every
interaction, looking for what is wrong rather than confirming what is right. It
gets the screen list and the interaction map, and it is told to find defects, not
to be fair.

Then one fix round on what it finds, then one re-check. Two rounds, not a loop.

---

## Autonomy, since this runs unattended

**Decided without waking anyone:** file and class names, widget composition,
curves and durations within `DESIGN.md`, German wording (then checked by
`humanizer`), the icon's direction, and small local blocs where a screen needs
memory.

**Not decided. Left undone and reported:**

- Real HyperKvasir and GastroVision images. The dataset is not on this machine.
- Real AWMF recommendation text. Extraction is untested against a real PDF and
  the rights position is unchanged.
- Physician approval. Nothing moves from `draft` to `approved` without one.
- Anything on iOS. There is no Simulator on Windows and there will not be one by
  morning.

**Rules while unattended:** one commit per phase, pushed, so any phase can be
read or reverted on its own. Nothing is deleted. If a phase cannot be finished
honestly, it is left incomplete and said so rather than reported as done.
