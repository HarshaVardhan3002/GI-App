# Implementing the material without breaking the build

The material is the one decision in this design capable of destroying the thing
that made the fork worth taking: its scroll feel. This is how it ships safely,
and it is treated as a single solved problem rather than a warning attached to
each screen.

---

## 1. What the cost actually is

`BackdropFilter` forces a save-layer, reads the framebuffer back, runs a blur
over the sampled region, then composites. Cost scales with **blurred area times
sigma**, and it repeats **every frame the content beneath changes**, which on a
scrolling feed is every frame.

Three properties follow, and all three are exploitable:

1. Cost scales with **area**, not with how many widgets sit on top of it.
2. Cost scales with **how many separate backdrop passes** exist.
3. Cost is **zero when the filter is disabled**, and disabling it need not change
   layout.

## 2. The solution: one shared pass

Flutter 3.35 ships `BackdropGroup` and `BackdropFilter.grouped`. Backdrop
filters inside a group **share a single backdrop input** with their siblings and
children instead of each taking their own pass.

```
BackdropGroup(
  child: Stack(
    children: [
      content,
      BackdropFilter.grouped(filter: material.normal, child: appBar),
      BackdropFilter.grouped(filter: material.normal, child: bottomNav),
      BackdropFilter.grouped(filter: material.ultraThin, child: counterPill),
    ],
  ),
)
```

Three materials on screen, one blur pass. **This is the answer to the tradeoff.**
The earlier budget of "one backdrop filter on the feed" was a restriction written
before the grouped constructor was accounted for; the real rule is **one
`BackdropGroup` per route**, with as many grouped filters inside it as the design
needs.

Placement: the group wraps the route's `Stack`, above the scaffold and below the
scrolling content, so the backdrop it samples is the content.

## 3. The kill switch that changes nothing

`BackdropFilter` takes an `enabled` flag. False keeps the widget, the layout and
every dimension identical, and skips the filter entirely.

```
BackdropFilter.grouped(
  filter: material.normal,
  enabled: MaterialQuality.of(context).blurEnabled,
  child: ...,
)
```

One inherited value drives every material in the app. It is false when:

- `MediaQuery.of(context).disableAnimations` or the platform reports reduced
  transparency,
- the device is known-slow, or
- a debug flag is set while measuring.

When it is false, the material paints its tint at full opacity at the same depth
instead. **The screen is never missing a surface, only its transparency.** No
second layout, no branch in any widget, no untested code path.

## 4. Keeping the blurred area small

The bars are the only glass, and a bar is 88dp tall on a 780dp screen. The blur
samples roughly 11% of the viewport per bar rather than the whole screen. Nothing
full-screen is ever blurred except a sheet backdrop, which is presented once and
static while it is up.

`RepaintBoundary` wraps the scrolling content so its repaints do not invalidate
the material's cached layer, and the material sits outside the scrollable rather
than inside it.

## 5. Never inside a list item

A blur per card multiplies save-layers by the number of visible cards, and the
count changes while scrolling, so the cost is both high and unstable. This is a
hard rule and it is also a design rule: glass means floating over moving content,
and a card does not float.

## 6. How it gets verified

Not by looking at it. Per `CLAUDE.md` §5, a scoped subagent runs the build and
reports numbers.

> Build, install, launch. Open Flutter DevTools' performance overlay, or run with
> `--profile` and `--trace-skia`. Scroll the feed continuously for ten seconds.
> Report: worst frame time, count of frames over 16ms, and whether any jank is
> visible to the eye. Repeat with the blur kill switch off. Report both numbers
> side by side. Do not change any code.

**The acceptance bar:** with the material on, the feed holds the same frame times
as the fork does with it off. If it does not, the sigma comes down before
anything else is touched, because sigma is the cheapest dial and 26 to 18 is
nearly invisible.

## 7. External packages: assessed and declined, for now

| Package | Version | What it is | Verdict |
|---|---|---|---|
| `real_liquid_glass` | 0.3.0, Jul 2026 | Hosts Apple's native `UIGlassEffect` on iOS 26+, zero deps, adapts to the transparency slider | **Revisit at iOS release.** On Android it falls back to a Flutter-drawn frost, which is the thing we are rejecting, and Android is our only verification platform |
| `liquid_glass_renderer` | 0.2.0-dev.4 | Real refraction and lensing through fragment shaders | **No.** Prerelease, six dependencies, and shader compilation jank on the one surface that must never stutter |
| `glass_kit` | 4.0.2 | Convenience wrappers over `BackdropFilter` | **No.** Wraps what we already write in forty lines, and hides the saturation control that is the whole point |

**Native wins on merit, not on principle.** `ColorFilter implements ImageFilter`,
so `ImageFilter.compose` gives the exact Apple recipe with full control of the
saturation multiplier, which is the single property separating glass from frost.
No package exposes that dial better than `dart:ui` does.

`real_liquid_glass` is worth real consideration for an iOS build, where it hands
over Apple's genuine system material for free and adapts to accessibility
settings we would otherwise implement ourselves. It cannot be evaluated on this
machine, so adopting it now would be adopting something unverified.

## 8. What could still break, and the answer

| Risk | Answer |
|---|---|
| Blur tanks the scroll | One `BackdropGroup`, small areas, `RepaintBoundary`, measured before merge |
| A device renders blur badly | Kill switch, same layout, opaque surface |
| Saturation blows out red mucosa | Saturation applies to the **bar's backdrop**, not the image. The image is never behind a material except at its very top edge |
| The masked edge shows banding on a gradient | Dither the mask, or accept it: the fade is over 36dp on near-black where banding is least visible |
| Impeller regression on an Android version | Kill switch, and the fork's own appearance is the fallback |

The image itself is never filtered. Not once, anywhere. A material that
resaturates an endoscopic image would be a clinical defect, not a visual one.
