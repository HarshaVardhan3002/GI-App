# Phase 1 - Identity

Scope: remove every mark that identifies someone else's product, and put *GI
Daily* in its place. Licensing depends on this (`ATTRIBUTION.md`), not taste.

**Status: planned, not implemented.**

---

## What the scout found that the build plan did not

`docs/BUILD-PLAN.md` §1 called this "1 file, 4 cosmetic call sites". Reading the
actual tree corrects that in four places.

### 1. There is a second identity, and it is not Instagram's

`android/app/src/main/res/mipmap-*/ic_launcher.png` and
`drawable/ic_launch_image.xml` are a line-drawn unicorn - the upstream author's
own mark, carried in the fork. Not an Instagram asset, so not a licensing
problem, but it is somebody else's identity shipping under our app label and it
is the first thing the jury sees. Nothing in the plan listed it.

### 2. `AppLogo` is not a text swap

The widget renders an SVG with a `fit`, `width` and `height` contract that its
call sites use:

| Call site | Passes | Effective size |
|---|---|---|
| `feed_app_bar.dart:17` | nothing | 50 x 17.9 (viewBox 800:286, contain in 50) |
| `post_preview.dart:29` | nothing | same |
| `login_page.dart:38` | `height: 64, width: infinity, fitHeight` | 64 tall |
| `sign_up_page.dart:49` | `fit: fitHeight` | 50 tall, overflows its 50 box |

An SVG scales to any box. A `Text` does not. Dropping a `Text` in makes `fit`,
`width` and `height` silently dead and the two auth screens render a 20pt string
where a 64dp mark stood.

**The fix keeps the contract instead of the call sites:** the widget renders
`Text` at the DESIGN size when no dimension is given, and wraps it in
`SizedBox` + `FittedBox(fit: fit)` when one is. Scaling behaviour is then
identical to the SVG's and no call site is edited.

Auth screens are unreachable in this build - `app_router.dart:486` redirects to
the feed whenever `AppStatus.authenticated`, and `LocalAuthenticationClient`
returns a fixed reader, so it always is. They must still compile and must still
look right for whoever reaches them later.

### 3. The typeface for the wordmark was not decided

`DESIGN.md` contradicted itself. §2 said Inter 700, written before the typeface
selection. §5's table said **Newsreader 20 / 24, weight 400**, written after.

**Decided: Newsreader 20 / 24, weight 400.** §5 is the later decision and the app
bar becomes the first of the three Newsreader moments, alongside the question and
the quote. §2 is wrong and gets rewritten in D7.

**Neither Newsreader nor Fira Sans is in the repository.** `app_ui` bundles Inter
and Montserrat only. So this pulls font bundling out of Phase 6 and into Phase 1
as D6, which is now mandatory rather than conditional.

### 4. iOS cannot be verified here

`Info.plist` reads `$(FLAVOR_APP_NAME)`, which is defined **eight times in
`ios/Runner.xcodeproj/project.pbxproj`**, not in the plist. It is editable from
Windows and it will not be verified from Windows. Per `CLAUDE.md` §9 it ships
reported as unverified.

---

## Deliverables

### D1 - Wordmark
`packages/app_ui/lib/src/widgets/app_logo.dart`. Text, with the SVG's scaling
contract preserved as above. Doc comment stops describing Instagram. No call
site edited. `instagram_text_logo.svg` stays on disk, unreferenced, recorded for
the later sweep.

**Touches** 1 file · **Blast radius** 4 call sites, none edited.

### D2 - App label
- `android/app/build.gradle:85,90,95` - three `manifestPlaceholders`:
  *GI Daily* / *[STG] GI Daily* / *[DEV] GI Daily*.
- `ios/Runner.xcodeproj/project.pbxproj` - eight `FLAVOR_APP_NAME` lines, same
  three strings.

Out of scope and stated so: `applicationId`
(`com.emilzulufov.flutter_instagram_offline_first_clone`) and the Dart package
name. Both are repo-wide churn with nothing jury-visible to show, and changing
the applicationId forces a fresh install and a new signing identity.

### D3 - Dark splash
`values-night/styles.xml` already selects a dark `LaunchTheme`, but points it at
`drawable/launch_background.xml`, whose first layer is `@android:color/white`.
That is the flash: white window, then the app paints near-black.

Add `res/drawable-night/launch_background.xml` with `@color/launch_background`
(depth 0.00 dark, `#000000`) and add `res/drawable-night-v21/` to match the
existing `drawable-v21` duplicate. The night qualifier outranks the version
qualifier, so day launches are untouched.

### D4 - Launch mark
**Decided: ground only.** The image layer comes out of all four
`launch_background.xml` variants. The splash is one flat colour and the first
thing drawn is the app.

The unicorn is black-filled, so on a dark ground it was invisible regardless. A
splash mark buys nothing at 400ms and costs a second asset that has to track the
wordmark, so it would be text drawn twice in two systems. This matches how
`DESIGN.md` §9 already treats loading.

`ic_launch_image.xml` stays on disk, unreferenced, recorded for the later sweep.

### D5 - Launcher icon
Still unsolved and still blocking nothing, but it now has a name: the icon
currently in the launcher is the upstream author's unicorn. Until it is
replaced, **the demo device must not show the launcher.** Recorded here so the
demo script accounts for it.

### D6 - Font bundling
Mandatory, because D1 renders in a face the repository does not have.

1. Newsreader variable TTF (`wght` and `opsz` axes) into
   `app_ui/assets/fonts/`, with its `OFL.txt` beside it.
2. Declared in `app_ui/pubspec.yaml`. **The asset path needs no prefix; the
   lookup does** - this is the Inter bug from earlier in the project, where a
   package font referenced without `packages/app_ui/` fell back to Roboto in
   silence and nothing reported it.
3. `flutter_gen_runner` regenerates `FontFamily`, which gains `newsreader`.
4. `pub get` at `app/` root as well as in `app_ui`, or the app tree does not see
   the change. That mistake has already cost this project once.

Fira Sans is **not** bundled in this phase. Nothing in Phase 1 renders in it, and
bundling a face with no call site is how an unverified asset gets into the tree.
It lands with the detail screen.

Licence: SIL Open Font Licence 1.1, recorded in `ATTRIBUTION.md`.

**Verification is a screenshot, not a build.** A missing font never fails the
build. It falls back to Roboto and looks approximately right, which is why the
subagent brief asks for the wordmark's shape rather than for a clean build.

### D7 - Documentation
`DESIGN.md` §2 rewritten to agree with §5. `docs/BRANDING.md` §6 likewise.
`ATTRIBUTION.md` gains the font entry if D6 runs.

---

## Order

1. D3 + D4 - resource-only, cannot break Dart.
2. D6 - fonts before anything renders in them.
3. D1 - the one Dart edit.
4. D2 - labels.
5. D7 - docs last, describing what shipped.

Each step builds before the next starts. D1 is the only step that can fail at
compile time.

---

## Verification

> **Subagent brief 1.** Build
> `flutter build apk --debug --flavor development -t lib/main_local.dart`,
> install on `pixel8_api36`, set the device to **dark** mode, launch from a cold
> start. Report:
> (a) the colour of the screen between tap and first frame - white, black, or
>     something else;
> (b) whether the feed header reads *GI Daily* with no other mark, and whether
>     it is set in a **serif** face - if the letterforms have no serifs the font
>     did not load and fell back to Roboto;
> (c) the app label under the icon in the launcher;
> (d) the header's height and the title's left edge, against the previous
>     screenshot.
> Attach the cold-start screenshot and the feed screenshot. Do not read source
> files. Do not fix anything.

Then repeat once in **light** mode for (a) alone, to confirm the night qualifier
did not capture the day launch.

**Done means:** it builds, both launches show the right ground colour, the header
reads *GI Daily* with no shift, and the report names anything it could not check.

**Not verified by this phase, and said so:** iOS labels, iOS launch screen, and
anything about how this looks on a Mac.
