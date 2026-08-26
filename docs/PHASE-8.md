# Phase 8 - Material

Branch `phase-8-material`, off `phase-7-mehr`.

The materials were already drawn to `DESIGN.md` section 4's dimensions in
Phase 4. This phase makes them cost what the design assumed they cost, and
gives them the switch that turns them off without changing a pixel of layout.

---

## What was built

### One backdrop pass per route

`GiBackdropGroup` (`packages/app_ui/lib/src/material/material_quality.dart`)
wraps a route's stack in Flutter's `BackdropGroup`, and every material inside
it uses `BackdropFilter.grouped` instead of the plain constructor.

A `BackdropFilter` forces a save-layer, reads the framebuffer back, blurs it
and composites, **every frame the content beneath it changes**. Two bars on a
screen used to be two of those. Inside a group they share a single backdrop
input, so the tab shell's top bar plus its tab bar is one pass, not two.

Where the groups are:

| Route | Materials inside it |
|---|---|
| `HomeView`'s scaffold | the tab bar, and whichever tab's top bar is showing |
| `FallView` | the case screen's top bar |
| `MehrScaffold` | each Mehr sub-page's top bar, pushed with the page |

The group wraps the scaffold rather than sitting inside it, so what it samples
is the content underneath the bars. `RepaintBoundary` wraps the navigation
shell so the scrolling content's repaints do not invalidate the material's
cached layer.

### The kill switch

`MaterialQuality` is one inherited boolean. `MaterialQuality.blurOf(context)`
is read in exactly two places (`GiMaterial`, `GiSheetMaterial`) and nowhere
else. When it is false, `BackdropFilter.grouped(enabled: false)` keeps the
widget, the layout and every dimension, and skips the filter; the tint paints
opaque at the same depth instead.

**There is no second layout and no branch in any widget.** Section 4: "Reduced
transparency collapses each material to an opaque surface at the same depth."

It is false when:

- `MediaQuery.disableAnimations` is set (Android's *Remove animations*), or
- `MediaQuery.highContrast` is set (iOS's *Increase Contrast*, the switch Apple
  pairs with Reduce Transparency). Flutter's `MediaQueryData` has no
  reduce-transparency flag, so these two stand in for it. Someone who has
  turned either on has said they do not want the screen doing work behind
  their content.
- `--dart-define=GI_NO_BLUR=true`, which exists so both halves of the
  measurement below come out of the same source rather than out of a build
  with the material commented out.

### The measurement harness

`lib/app/view/frame_log.dart`, off unless `--dart-define=GI_FRAME_LOG=true`.

It exists because **`adb shell dumpsys gfxinfo` reports nothing for this app**:
Flutter draws through Impeller, not HWUI, so every HWUI counter is zero. The
numbers are in `SchedulerBinding.addTimingsCallback`.

---

## The numbers

Profile build, `emulator-5554` (Android 16, 1080x2400, software GL), same
source, one `--dart-define` apart. Twelve full-height swipes up and down on
Heute, images loaded, after a 20-second settle.

| | material on | material off |
|---|---|---|
| frames sampled | 600 | 840 |
| build p50 | 1.4 ms | 1.5 ms |
| build p90 | 3.4 ms | 3.6 ms |
| build p99 | 7.3 ms | 8.1 ms |
| **raster p50** | **6.2 ms** | **5.0 ms** |
| **raster p90** | **14.8 ms** | **12.8 ms** |
| raster p99 | 29.7 ms | 24.2 ms |
| raster max | 112.1 ms | 64.8 ms |
| raster over 16.7 ms | 6.8% | 5.4% |

**The material costs about 1.2 ms of raster at p50 and 2 ms at p90.** Build is
unchanged, which is what a backdrop filter should do: it is a raster cost and
nothing else.

### Against the acceptance bar

`docs/MATERIAL-IMPLEMENTATION.md` section 6 sets the bar at "the feed holds the
same frame times with the material on as without it". **It does not quite, and
this is not a pass.** 6.8% of frames over budget against 5.4%, and a worst
frame of 112 ms against 65 ms.

What is not being claimed:

- These are software-GL emulator numbers. The absolute values mean nothing
  about a phone; a real GPU blurs an 88dp bar without noticing. **The
  comparison is valid, the absolutes are not.**
- The acceptance test is therefore **not passed and not failed**. It is
  unrun on the hardware it was written for.

Sigma stays at 26, which is `DESIGN.md`'s number. The doc's remedy is to bring
it to 18 if the bar is missed, and 26 to 18 is nearly invisible. Doing that on
emulator evidence would be tuning a real design decision against a fake
measurement.

**What has to happen before anyone calls this passed:** run the same two builds
on a physical Android device and compare the same rows. That is one command
each and ten minutes, and it cannot be done on this machine.

---

## Not built, and why

**Ultradünn (blur 18, saturation 1.8, depth 0.30 at 24%, "over media") has no
site in this app.** Section 4 rule 1 restricts materials to bars and sheets,
and section 5 of `MATERIAL-IMPLEMENTATION.md` forbids a blur inside a list
item outright. The only floating-over-media surfaces in the nine screens are
bars, which take Normal, and the archive cell's date scrim, which is a list
item.

Building it now would be a widget nothing calls. It goes in when a screen needs
it, and the dimensions are recorded in `DESIGN.md` until then.

---

## Verified

- `flutter analyze` over `lib` and `packages/app_ui`: no issues.
- Debug build installed and walked: Heute with both bars, the carousel across
  three aspects, Fall, Archiv, and the Mehr tree. Grouped filters render the
  same as the ungrouped ones did. No visual regression.
- The two profile builds above, measured as described.
- **The collapse, on screen.** `animator_duration_scale 0` on the emulator,
  which is what Android's *Remove animations* sets and what Flutter reports as
  `disableAnimations`. Both bars go opaque at the same depth, in the same
  place, at the same size; the layout does not move by a pixel. The rolling
  heading falls back to its ellipsis in the same pass, which is the other half
  of that flag doing its job.

## Not verified

- iOS. No simulator on this machine, and `highContrast` standing in for Reduce
  Transparency is an assumption that has never run on an Apple device.
- Physical Android hardware, per the acceptance section above.
