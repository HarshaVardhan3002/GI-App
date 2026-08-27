# HANDOFF

Written 27 August 2026, at the end of a session that went in the wrong
direction and was stopped by the owner. Read this before touching anything.

The short version: **the Heute screen was built as a scrim, and the owner asked
for glass.** Four passes of layout work fixed the wrong problem. A Sonnet agent
walked the build against Apple's own material standard and found no glass
anywhere in the app, in either appearance, measured rather than eyeballed.
There is also a verification failure underneath that finding which matters more
than the finding itself, and it is in section 5.

Nothing is broken and nothing is lost. Every phase is on its own branch.

---

## 1. Where the code is

| Branch | Commit | What it is |
|---|---|---|
| `phase-8b-bleed` | `1fdb7ca` | **Current. Checked out.** The full GI design system and the four screens: Heute, Fall, Archiv, Mehr |
| `phase-9-clone` | `7b192e7` | The plain Instagram clone, rolled back to `a2df739`, identity strip kept. Parked, not deleted |
| `main` | `d552a73` era | Untouched. Nothing merges here without the owner |

`phase-9-clone` exists because the owner asked for a rollback mid-session and
then, in the next message, asked to switch back to the implementation and plan
first. **Leave `phase-9-clone` alone.** It is a clean base for the feature work
in section 8, whenever that starts.

`a2df739` is the rollback point if it is ever needed again: the plain clone,
with the Instagram wordmark, name and launch mark already removed. That removal
is a licensing obligation under `ATTRIBUTION.md` and never rolls back.

### The screen this is all about

`app/lib/heute/widgets/tageskarte.dart` builds Heute's card. As of `1fdb7ca`:

- A `Stack` filling the viewport.
- `GiAmbient` at the bottom of the stack, ground black, lighting whatever the
  picture does not cover.
- `TageskarteImages` full screen. Each frame is a `_CaseFrame`
  (`tageskarte_parts.dart`) which uses `BoxFit.cover` when at least 85% of the
  frame's long axis survives the screen, and `BoxFit.contain` otherwise.
- A bottom-aligned `GiThinMaterial` with `radius: 0`, `showEdge: false`,
  `fadeExtent: 96`, holding the attribution, the dots, the date and type line,
  the two-line question, `Fall öffnen`, the peek and the tab bar inset.

Supporting files, all currently on `phase-8b-bleed`:

- `app/lib/media/widgets/gi_ambient.dart`: 48px source, blur 24, saturation
  1.2, overscan 1.4, ramp that strengthens downward and dies over `navInset`.
- `app/packages/app_ui/lib/src/material/gi_material.dart`: `GiMaterial`,
  `GiSheetMaterial`, `GiThinMaterial`, and `_GradedTint`, the `CustomPainter`
  that grades the thin material's tint from `gradedTopAlpha` through
  `gradedBodyAlpha` at the end of the fade to `gradedFootAlpha` at the foot.
- `app/packages/app_ui/lib/src/colors/gi_colors.dart`: the ramp and the tokens.
  Light `warning` was darkened from `0xFFB26A00` to `0xFF995700` this session
  for measured contrast. **See section 8: the owner has since banned orange,
  yellow and gold text outright, so this token is going to change again.**
- `app/lib/media/widgets/gi_image_view.dart`: gained a `fit` parameter.

---

## 2. What the owner actually asked for

Four messages govern. They are quoted rather than summarised because every
previous summary of them lost the part that mattered.

### Message A

> "AM i getting something wrong you haven't fixed this shit expect this from
> the design doc [mock] look what your implementation looks."

An annotated screenshot circling a large empty region under the text pane.

### Message B

> "there is still white space at the bottom the rounded edges at the bottom are
> sitting on a sharp edge that's creating corner black space ... if the image is
> in odd dimension just fill top part and the bottom part with the gradient
> flow ... only the images that's not in the right aspect they sit at the center
> center of the image boundery and the remaining unfilled spaces has this glass
> like bleed from the image on top of diffusion"

### Message C, the geometry that is currently implemented

> "the image stays as it is you don't play or overlay anything over the image,
> the image is at full resoltion and it's forced to cover the image section of
> the screen ... the image occupies the entire screen as that's the context, the
> Title and other stuff sit on top of the full screen seemless image on a
> diffused glass like layer for better visiablity the glass/pannle mus not be
> uniformly shaded, it should be tinted black for the darkmode and lighty
> translucent white for the Hell ... Stretch if the image can survive the screen
> cover, if not keep the image fill the top and bottom with black bars and add
> mild colour diffusion on the blackedout region only the image must not be
> toughed and must on bleed on top of the image, use the ramping, less nearer
> the image stronger as we move down and the strongest near the navigation bar,
> that has no background bleed (the nav bar region)."

Seven binding points: image is the whole screen; text sits on glass over it;
the glass is not uniformly shaded; `cover` when the frame survives it, black
bars when it does not; diffusion only on the bars, never on the picture; the
diffusion ramps weakest at the frame to strongest at the bar; the nav bar band
gets no bleed.

**All seven are implemented at `1fdb7ca`.** That is why this is so important to
understand: the geometry is right and the material is wrong, and no amount of
further layout work would have found that.

### Message D, the correction

> "This app neither looks premium nor useable ... I asked for a glass slab, but,
> again, you painted some, uh, diffusion type of shit, and I asked for the dark
> aesthetic. You didn't give me that. And the light version is being ignored
> heavily."

> "I want Instagram for GI data consumption, with Instagram turned into a
> Ambient reflective/refractive/diffusing piece of software"

> "Instagram on iOS has native glassmorphism and, uh, all the liquid glass type
> of components. But on Android, Instagram is playing that simple app. So I want
> Instagram on iOS level on all the devices. So glassmorphism is the main
> differentiator."

Plus, in the same message:

- No yellow, orange, gold or any similar colour for text. Anywhere.
- Every time a dimension or a placement changes: screenshot, check placement,
  check dimensions. "everything must be perfect."
- The reference image the owner attached is a yoga and meditation app concept:
  layered translucent cards over a green ambient field, a floating pill tab bar
  with circular glass buttons, soft rounded rectangles with lit edges, real
  depth between the layers.

---

## 3. What the agent found

A Sonnet agent was told to research Apple's material standard on the public web
and then walk the running build against it, harshly, without ever touching the
source. Its screenshots are in `docs/handoff/`.

### Its verdict

> "No, this does not read as a finished consumer product at native iOS
> standard. The single biggest reason: the entire app is built in a flat, solid
> fill visual language with zero glass or translucency material anywhere, no
> blur, no specular edge highlight, no elevation shadow, on any surface, in
> either light or dark mode."

### The standard it established, from Apple's HIG and the Liquid Glass material

1. **Lensing and refraction** of what is behind, not flat blur. Glass bends and
   concentrates light.
2. **Specular highlights on the edge**, which respond to device motion.
3. **Adaptive tint**: the glass shifts colour, brightness and saturation based
   on what is underneath it.
4. **Elevation shadow** cast onto the content below, which is what proves the
   physical separation.
5. **Container-concentric corner radius**: the glass radius nests with its
   container's.
6. **Glass is a fixed navigation layer**, and content scrolls independently
   beneath and through it.
7. **Legibility guaranteed dynamically** at 4.5:1 minimum, with an opaque
   fallback rather than plain text on an arbitrary photograph.

### The amateur failures it named, which are checkable in a screenshot

1. Flat uniform scrim with no edge treatment.
2. Blur with no shadow, so the panel has no elevation and reads as painted on.
3. Text or scrim over a full-bleed photo with no adaptive-contrast mechanism.
4. Corner radius mismatched between the glass and its container.
5. No specular highlight, so the material has no visible beginning or end.
6. Static blur or opacity that ignores the appearance.
7. Text directly on a photograph with no scrim at all.

### What it measured in this build

- **No edge on any panel.** In `11_light_mehr.png` the first settings panel
  steps from page background `(255,255,255)` to panel fill `(241,245,249)` in a
  single pixel at y≈353, x≈44. `08_dark_mehr.png` does the same, `(0,0,0)` to
  `(8,15,20)`, one pixel. No rim, no gradient, no highlight stroke.
- **No elevation.** No shadow falloff pixels exist outside any panel edge, in
  either appearance.
- **Corner radius is two unrelated conventions.** Mehr's settings rows measure
  a real 16px radius. Heute's card, its image, the Archiv tiles and the answer
  card on Fall are square, edge to edge. Nothing is concentric with anything.
- **The ambient band ignores the appearance.** In `09_light_heute.png`, y≈200
  to 630 and y≈1330 to 1420 stay near-black inside an otherwise light page,
  identical to dark. A hard black rectangle in a white page, with no blend and
  no transition. This is the owner's "the light version is being ignored
  heavily", independently measured.
- **`Fall öffnen` does not respond to a direct tap.** Seven coordinate pairs,
  three attempts, both `input tap` and `input touchscreen tap`, no navigation.
  In the same session a tab tap and an Archiv tile tap both navigated on the
  first try, which isolates the defect to that control.
- **The back label is wrong.** Reached from an Archiv tile, the case screen's
  back affordance reads "‹ Heute" and returns to Archiv.
- **No pressed or selected feedback anywhere.** No ripple, no highlight, in any
  screenshot after any tap.

### Its comparison

The iOS 26 tab bar, and the same bar in Apple Music, Maps and Photos: a
blurred, refractive pill that floats, has a lit top edge, casts a shadow onto
content scrolling underneath it, and shrinks or hides on scroll down. Ours is a
flat opaque bar pinned to the screen edge, with content stopping above it
rather than passing beneath it.

---

## 4. What was wrong in the direction taken

Set against the standard in section 3, point by point.

| Standard | What this build does |
|---|---|
| Specular highlight on the edge | Deliberately switched off. `GiThinMaterial(showEdge: false)`, and the doc comment argues for it |
| Elevation shadow under the glass | None anywhere. `DESIGN.md` section 4 rule 4 says "edges are light, not shadow", which was read as "no shadow", so nothing floats |
| Lensing and refraction | A Gaussian blur plus a flat tint. That is a scrim. It is exactly what the owner called "diffusion type of shit" |
| Adaptive tint | Fixed alphas per appearance. Nothing reacts to what is underneath |
| Concentric radius | Full-bleed `radius: 0` panels against 16px cards elsewhere |
| Glass as a fixed layer with content passing beneath | The panel is pinned to a static image. Nothing scrolls through anything |
| Legibility with an opaque fallback | Contrast was chased by thickening the tint until the glass was nearly opaque. In Hell the body alpha reached 0.86 and the foot 0.96, which is not glass, it is a panel |

The deeper mistake: **four passes treated this as a layout problem.** The
owner's Messages A, B and C are about geometry, and the geometry was genuinely
wrong, so each pass found something real to fix and shipped it. None of them
asked whether the material itself was the thing being rejected. Message D says
it plainly, and it was true from Message A onward.

---

## 5. The verification failure, which is the most important item here

The agent reports **zero blur in the app**. There are `BackdropFilter`s in
`GiMaterial`, `GiSheetMaterial` and `GiThinMaterial`, and they are gated behind
`MaterialQuality.blurOf(context)`.

The emulator `pixel8_api36` runs **software GL** (`swiftshader_indirect`).

**Nobody has verified that blur was actually rasterising in any screenshot
taken on this machine.** Every material number recorded in `docs/PHASE-8.md`
and in this session's commit messages was measured off that emulator. If the
quality switch was disabling blur, or if the software rasteriser was dropping
it, then those numbers describe a build with the material switched off, and the
whole Phase 8 material record is unverified rather than wrong.

**First task of the next session, before any design work:**

1. Read `MaterialQuality` and find every condition under which
   `MaterialQuality.blurOf` returns false.
2. Determine whether any of them are true on `emulator-5554`.
3. Prove blur is rasterising with a pixel measurement, not by reading the code:
   put a known hard edge behind a material and measure the gradient across it
   in the screenshot. A blurred edge spreads over tens of pixels. An unblurred
   one steps in one, which is precisely what the agent measured on every panel
   it sampled.
4. If blur is off on this emulator, **stop using it to judge material work** and
   say so in every report. Get a hardware Android device, or run with a real GPU
   backend, or both.

Do not skip this to get to the interesting part. Every hour spent tuning alphas
against a renderer that is discarding the blur is an hour spent inventing
numbers.

---

## 6. What has to be built, and in what order

**No code until this plan is agreed with the owner.** CLAUDE.md section 4.

### Step 0: prove the renderer (blocking)

Section 5. Nothing below is meaningful until this is settled.

### Step 1: fix the defects the agent found, which are not design work

These are bugs and they are cheap.

- `Fall öffnen` does not respond to a tap. Suspect the `IgnorePointer` on
  `HeuteHeader`, the `Tappable.faded` hit area, or a `Stack` child above it
  eating the gesture. Reproduce first, per CLAUDE.md section 5: a subagent
  finding is a lead, not a fact.
- The back label on Fall names Heute regardless of where the reader came from.
- No pressed or selected state on any control.

### Step 2: build the material properly, once, in `app_ui`

This is the whole job, and it is one widget, not seven screens.

What a glass surface needs, from section 3, each of which is a real Flutter
mechanism and none of which is exotic:

- **An edge.** A 1px inner stroke that is brighter at the top and fades around
  the shoulder, not a uniform hairline. This is a `ShaderMask` or a
  `CustomPainter` stroking the rounded rect with a sweep gradient.
- **A shadow.** A soft, wide, low-opacity drop shadow under the glass. This is
  what makes it float, and its absence is the single most visible amateur tell
  in the agent's list.
- **Refraction, not just blur.** The mechanism is a displacement of what is
  behind the panel near its edges: sample the backdrop with a warped
  coordinate. In Flutter this is a fragment shader
  (`FragmentProgram`, `.frag` asset, `ui.ImageFilter.shader` or a
  `CustomPainter` over a saved layer). This is the piece that needs research
  before estimating. It is also the piece that turns a scrim into a slab, so it
  is not optional.
- **Adaptive tint.** Sample the backdrop's mean luminance behind the panel and
  drive tint and text colour from it, rather than from a fixed per-appearance
  constant. There are cheap ways to do this: the ambient source is already
  decoded at 48px, so its mean under the panel's rect is nearly free.
- **Concentric radius.** One radius scale, and nested surfaces derive their
  radius from the parent's minus the inset.

Build it as one material with an honest quality ladder: full glass, blur only,
opaque. The ladder already exists in `MaterialQuality` and needs to keep
working.

### Step 3: apply it to the tab bar first, not to Heute

The tab bar is the smallest surface, it is on every screen, it is the exact
element the agent compared against iOS, and it is the one place where getting
it right is immediately obvious. Heute's card is the hardest surface in the app
and the worst place to develop a material.

### Step 4: Heute, with the geometry from Message C kept

The geometry is right. Only the material changes. Keep: image full screen,
`cover` at 85% survival, black bars, ambient on the bars only, ramp toward the
bar, nothing on the picture.

### Step 5: the light appearance, treated as a first-class target

Not a translation of dark. The owner has said twice that Hell is being ignored,
and the agent measured a near-black band sitting inside a white page. Every
number in step 2 gets taken in both appearances, in the same pass, or it does
not count.

### Step 6: the colour ban

No yellow, orange or gold text. `GiColors.warning` is currently
`0xFFFF9F0A` in dark and `0xFF995700` in light, and it renders the rights
notice on Heute, which is the most visible orange in the app. A warning needs
to stay distinguishable from ordinary text without being a warm colour: the
options are a cool desaturated red, a neutral at a heavier weight with an icon,
or a badge rather than coloured type. **This is a `DESIGN.md` decision and needs
the owner.**

---

## 7. Open questions for the owner

1. **Posting.** "it should also support posting" and "don't remove the add
   section. Just comment it out, detach it for now" read as a contradiction. The
   working assumption is: the post model and the feed stay real, the in-app
   create flow goes dark for now. Confirm.
2. **The warning colour.** Section 6, step 6. Orange is banned and the rights
   notice still has to read as a warning.
3. **Refraction cost.** A fragment shader on a full-width panel over a
   photograph, on Android, at 60fps, is a real performance question and this
   machine cannot answer it honestly. It needs measuring on hardware.
4. **Which branch the feature work lands on.** The removals and additions in
   section 8 belong on `phase-9-clone`. The material work belongs on
   `phase-8b-bleed` or its successor. These are two different products of this
   session and they will have to meet somewhere.

---

## 8. The feature queue, recorded and not started

From Message D. This is the clone work, parked on `phase-9-clone`, not started.

1. Remove stories.
2. Remove the search entry page entirely. The home feed stays.
3. Remove comments. In their place, a button that reveals the poll or question
   about the post.
4. Add share.
5. Add like. **No visible count.** The signal feeds topic interest for the feed
   algorithm, it is not a score shown to the reader.
6. Settings stays, and gains saved articles.
7. Keep profile creation.
8. Keep the Instagram layout as it is.
9. Keep a splash screen. GI Daily's, rebranded. Note that `a2df739` blanked the
   launch window to flat black and white deliberately, so this is work, not a
   revert.
10. Comment out the add and create flow. Do not delete it. CLAUDE.md section 3.

---

## 9. Known defects carried forward, none of them fixed

- The rights notice's **second line** measures 4.00:1 in Hell against the pane
  it sits on. A footnote needs 4.5. First line is 4.58:1.
- `Fall öffnen` unresponsive to direct taps (agent finding, not yet reproduced
  by the main thread).
- Back label on Fall names the wrong origin (same).
- No pressed or selected feedback on any control (same).
- Source photographs carry the endoscope's **black corner vignette**, baked
  into the pixels. Measured: `test-trichobezoar-001.jpg` at `(0,0)` and `(5,5)`
  is `(17,17,17)`, while `(10% width, 0)` is `(200,88,74)`. Invisible in dark,
  visible in Hell, and reported by the owner as a layout bug. It is not one. The
  only cures are cropping the circular field, which is forbidden for a clinical
  image, or real pre-cropped content.
- Dataset provenance stamps, the "1a" burnt into the corner of the source
  photographs, collide with the app's chrome.
- `posts.json` puts a whole clinical vignette plus the interrogative into the
  `question` field. The card wants the interrogative only. This is content work.
- Every string in the app is still unchecked against `humanizer`. CLAUDE.md
  section 7.
- The Phase 8 material A/B has never run on physical Android hardware.
- **iOS is unverified and unverifiable on this machine.** No simulator on
  Windows. Anything said about iOS gesture feel or posture in any document in
  this repo is an assumption.

---

## 10. Environment

```
Flutter 3.35.7            C:\src\flutter
JAVA_HOME                 C:/Program Files/Microsoft/jdk-17.0.20.101-hotspot
adb (not on PATH)         /c/Users/Von/AppData/Local/Android/Sdk/platform-tools
emulator (not on PATH)    /c/Users/Von/AppData/Local/Android/Sdk/emulator
AVD                       pixel8_api36, 1080x2400, density 2.625, Android 16
Package                   com.emilzulufov.flutter_instagram_offline_first_clone.dev
```

```bash
# build
cd app && flutter build apk --debug --flavor development -t lib/main_local.dart

# install and launch. .MainActivity does not resolve via `am start`
adb install -r build/app/outputs/flutter-apk/app-development-debug.apk
adb shell am force-stop $PKG
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1

# appearance. Only works while the app's own setting is on System
adb shell "cmd uimode night yes"   # dark
adb shell "cmd uimode night no"    # light
# the app's appearance is a persisted ThemeModeBloc. If it is pinned to Hell or
# Dunkel, the system setting does nothing. `adb shell pm clear $PKG` resets it.

# screenshot
adb exec-out screencap -p > shot.png
```

Contrast is measured off the screenshot in Python with PIL: take the 3rd and
97th percentile luminance inside a text row's bounding box and compute the WCAG
ratio between them. Do not eyeball it, and do not trust a ratio taken from a row
whose coordinates were not confirmed against the screenshot first. Two
measurements this session came back as 1.0 because the sampled band was empty.

Emulator start, when it is not already running:

```bash
emulator -avd pixel8_api36 -gpu swiftshader_indirect -no-snapshot-load
```

Note the `-gpu swiftshader_indirect`. See section 5.

---

## 11. The rules that bind, and where they are

`CLAUDE.md` is the authority and it wins over every skill and every habit. The
ones this session tested:

- **Section 4, plan before code.** Four passes of layout work went in without a
  plan that asked what was actually being rejected.
- **Section 5, subagents walk the app and never read the code.** This was
  followed, and it is the reason the agent's report was worth having: it had not
  been told what the screen was supposed to be doing.
- **Section 5 again, findings are verified before they are believed.** Three
  items in section 9 are still leads.
- **Section 10, alternative versus pivot.** Switching the app to shadcn/ui was
  raised and stopped, correctly: shadcn is React, Tailwind and Radix, there is
  no import path into Flutter, and shadcn's house style is flat and bordered,
  which is the opposite of the glass the owner wants. A Flutter port exists
  (`shadcn_ui` by nank1ro) but adopting it would reverse `DESIGN.md` sections 1
  and 4, which is a pivot.
- **Section 11, report honestly.** Section 5 of this document exists because of
  it.
- **No em-dash in English text.** Anywhere, including this file. German keeps
  its spaced en dash.
- Global user instruction: use tokensave for code research rather than Explore
  agents. tokensave reports 0 nodes for this project, so it cannot answer here
  and the fallback applies.
