# Phase 8b - Bleed, and a defect in Phase 8

Branch `phase-8b-bleed`, off `phase-8-material`.

Not a planned phase. The owner looked at the running app against the design
artifact and named three things: the card was boxed where the artifact was full
bleed, the layout was the same rectangle whatever image it was carrying, and the
bleed-and-fade the artifact shows had never been built.

They are right on all three. This branch fixes them, and while verifying the fix
in the light appearance it turned up a real defect in Phase 8 that Phase 8's own
verification missed.

---

## 1. The card is shaped by its image

`lib/heute/widgets/tageskarte.dart`.

Two earlier passes were wrong the same way.

| Pass | What it did | Why it was wrong |
|---|---|---|
| Phase 4 | image pinned to a fixed 1.25 aspect | true of exactly one image shape; a portrait was cropped |
| Phase 7 fixes | image given everything the text left, contained inside it | stopped the cropping, and produced a 1356x520 strip floating in the middle of a black field |

The second is the one in the owner's screenshot, and the complaint is exact:
**the layout was the same rectangle whatever it was carrying.**

Now the image field is `GiImage.aspectRatio` tall at full width, anchored to the
top, bounded at both ends:

| | |
|---|---|
| Height | `width / aspectRatio` |
| Ceiling | 62% of the card, so a 527x675 portrait cannot push the question off |
| Floor | 34% of the card, so a 2.6:1 strip is not a postage stamp |
| Anchor | top, so the image runs full bleed under the wordmark |

Nothing is cropped and nothing is stretched. Where a clamp bites, the image is
contained and the margin shows the ambient rather than black.

### No scroll view, and why

The first attempt put a `SingleChildScrollView` around the card so an enlarged
text scale could not overflow. It handed the `Column` unbounded height, which
contradicts the `Expanded` inside it, and the card rendered as **nothing at
all**: `RenderFlex children have non-zero flex but incoming height constraints
are unbounded`, then a cascade of `hasSize` failures.

It was also solving a problem `Expanded` already solves. When the text block
grows, the image field is what yields. The card gives way at the image rather
than at the question, which is the right order for this screen. A second
scrollable inside the vertical pager would also have taken the drag off it.

## 2. The ground is lit by the image

`lib/media/widgets/gi_ambient.dart`, and `DESIGN.md` section 4a.

An endoscopic frame is not the shape of a phone. So a frame leaves space, and
the space was flat black, which is not neutrality: it is a second design
decision made by default.

The space now carries the frame's own light. The asset is decoded at **48 pixels
wide**, scaled 1.4x past the box, saturated 1.2 and blurred 24. At that size
nothing survives but colour and where the colour sits.

**It is cheap on purpose.** The texture is smaller than an icon and the upscale
does the work; a full-resolution frame under a sigma-60 blur would have been the
most expensive thing on the screen.

A placeholder draws nothing. A drawing has no light to spill.

### Two tunings, both from looking at it

**Full alpha was wrong.** The first build ran the light at 100% under the frame
and the card read as glowing rather than lit: a ground as saturated as the
endoscopic image, and the tint on *Fall öffnen* sitting on red. `DESIGN.md`
section 1 rule 1 is not suspended by this feature, it is the constraint the
numbers are set against. Now 55% at its strongest, decaying to 30% just past the
frame and 20% at the card's foot.

**Light needed its own numbers.** On black, compositing the frame adds and the
result is light. On white it subtracts, and the same alpha does not read as
light at all, it reads as a stain on paper. Light runs 24% / 13% / 9%.

Both sets were tuned again after the pane moved; see the adversary round below.

### The frame bleeds into it

The image's bottom edge feathers over 32dp, so the frame ends in its own light
instead of at a cut.

**This is the one place in the app where image pixels are deliberately
hidden.** It is defensible only because an endoscopic frame's bottom edge is the
dark periphery of the lumen rather than the finding, and because Fall shows the
same image whole and unfeathered. Anyone who disagrees should set `bleedExtent`
to zero; the light still fills the space.

## 3. Ultradünn, built, because a screen finally needs it

`GiThinMaterial` in `packages/app_ui/lib/src/material/gi_material.dart`.

Phase 8 deliberately did not build the Ultradünn material because it had no
site. Its declared site in section 4 is "over media", and Heute's text now reads
off a pane laid over the image's ambient light, which is that site exactly.

Blur 18, saturation 1.8, tint at depth 0.30, rounded top, 1px inset highlight.
Thin is the point: a sheet at 88% would put the light out, and the reason the
pane is there is that the light carries on underneath it.

The tint started at section 4's 24% and is now 55%. The adversary round below
has the measurement and the argument.

## 4. Fall

The frame on Fall gets the ambient as its own ground, so a clamped shape shows
the image's light in the margin instead of flat ramp.

**It stops at the frame there.** Heute is for looking, so the light fills the
card. Fall is for reading four options and a question, and coloured light under
body text is a contrast problem dressed as atmosphere.

---

## The defect in Phase 8

**`BackdropFilter.grouped` was drawing the wrong backdrop, and Phase 8 shipped
it.**

Found by sampling pixels in the light appearance, where the tab bar came back
salmon over a near-white ground. It is not the ambient: the ambient under the
bar measures 4%.

Same frame, same build, one constructor apart, `emulator-5554`, dark:

| | top bar | bottom bar | ground directly under the bottom bar |
|---|---|---|---|
| `BackdropFilter.grouped` | (134,51,36) | **(123,40,28)** | (27,8,9) |
| `BackdropFilter` | (107,58,51) | **(19,10,10)** | (27,8,9) |

Grouped, the bottom bar samples the top bar's slice of the endoscopic image,
1400px away. Ungrouped, it samples what is beneath it. The same held in light
and on all three cards.

Both bars use Normal, so they carry an identical filter, which is the case
`BackdropGroup` is meant to optimise hardest and the case that fails.

**Why Phase 8 missed it.** Phase 8 verified the grouping by frame timings and by
walking the app in dark. In dark, over a red endoscopic image, a bar showing the
wrong red still looks like a bar. Nothing about it read as broken until a
near-white ground put a salmon bar next to a white one. **Frame timings cannot
tell you a filter is sampling the wrong pixels**, and "no visual regression" was
an eye check that this defect was well shaped to survive.

### What was done

All three materials use the plain `BackdropFilter`. `GiBackdropGroup` stays in
the tree because it also carries `MaterialQuality`, which is load-bearing; only
the sharing is off.

**The cost is Phase 8's entire measured saving**, about 1.2ms of raster at p50
on this emulator. A bar that shows the wrong part of the screen is not worth
1.2ms. The mechanism goes back on when it draws correctly, and
`docs/PHASE-8.md` and `DESIGN.md` section 4 now say so rather than claiming a
shared pass the app does not have.

---

## Verified

- `flutter analyze` over `lib` and `packages/app_ui`: no issues.
- Built, installed and walked on `emulator-5554` (1080x2400, Android 16).
- **Dark**: three cards across three image shapes, plus the placeholder card.
  Full bleed to the top edge on all of them, no black field, no warping, the
  question and the tint legible on the pane.
- **Light**: the same first card and the placeholder card. The wash reads as
  light rather than as a stain, and the pane holds its text.
- The placeholder card draws no ambient, which is the intended behaviour and
  looks like it.
- Fall, opened from the card: image full bleed to the top, dissolving into the
  reading area, question and four options legible.
- Zero framework exceptions in `logcat` after the fix, against three on the
  first attempt.

## Not verified

- iOS. No simulator on this machine.
- Physical Android hardware. The grouping defect is a correctness result and
  holds regardless, but the frame-time cost of dropping it is unmeasured on a
  real GPU.
- Whether an enlarged system text scale overflows the card. The image field
  yields first by construction, and the extreme end of the scale was not run.

## Named, not fixed

- **The card heading rolls through a clinical vignette, not a heading.** The
  `question` field in `posts.json` carries the whole vignette plus the
  interrogative, so the card's rolling line reads mid-sentence at rest. That is
  a content problem and belongs to the content phase, not to layout.
- **A wide image leaves a large lit gap** between the frame and the text pane.
  It is lit rather than black, which is the fix that was asked for, but it is
  still a lot of screen. Whether the pane should ride up under short frames is
  a design question worth the owner's eye.

---

# Adversary round

A Sonnet subagent was given the running build, the design docs, an exact walk,
and instructions to find what is wrong. It raised nine findings. Three were
confirmed and fixed, two were confirmed and led somewhere else, one did not
reproduce, and the rest were already named.

## Confirmed and fixed

### 1. The screen name was unreadable over a bright frame

*Heute*, top right, measured **1.10:1** against a pale mucosal wall on card 2.
Not a polish gap. A clinical product that cannot tell the reader which screen
they are on has failed its most basic obligation, and it failed on real content.

**Cause: two mechanisms doing one job.** `GiMaterial` masks itself to
transparent over its last 36dp *and* graded its tint from 58% down to 16% across
the bar's whole height. So the tint was near its weakest exactly where the label
sits, and a bright frame came through almost unattenuated.

The tint is now held at 58% and the mask carries the fade, which is where
section 4 rule 3 always said the fade lived. The right-hand label also went from
70% to 85% alpha, because at 70% it still missed 4.5:1 even over the fixed bar.

| | before | after |
|---|---|---|
| *Heute* over a pale frame (card 2) | 1.10:1 | **7.74:1** |
| *Heute*, cards 1 and 3 | not measured | 10.60:1, 11.65:1 |
| wordmark, worst case | 2.82:1 | **9.82:1** |
| *Heute* in light, two cards | not measured | 6.99:1, 8.65:1 |

### 2. A third of the screen doing nothing, and it read as a failed load

Card 1: the frame ended at y≈850 and the pane began at y≈1650. Eight hundred
pixels of nothing, in the middle of the card, worst in light where the wash is
almost flat.

The pane was pinned to the bottom of the card, so every card's empty space
landed in its middle. **The design artifact has it the other way round and the
artifact is right**: the frame, the question directly under it, and whatever is
left at the foot. Space at the bottom of a short card reads as a short card.
Space in the middle of one reads as a mistake.

### 3. The placeholder card wasted 56% of the screen on an empty box

A placeholder has no pixel dimensions, so it fell through to a 1.25 aspect
default, which is a real frame's shape. The field came out at 62% of the card
and held two centred lines of text in a 1170px void.

It takes the floor now, 34%. There is nothing to look at, so it asks for the
least room a field is allowed.

## Confirmed, and the cause was somewhere else

### 4. Tab labels failed contrast

Reported as 3.08:1 with a colour matching no token. The colour claim was wrong:
inactive tabs are `labelTertiary` from the ramp, and 3.08 came from an
antialiased glyph edge. But the substance held, and chasing it found a worse
bug than the one reported.

**`GiMaterial`'s mask fades the material *and the child on it*.** `HeuteHeader`
already knew this and puts a 36dp spacer after its content so the fade lands
below. `BottomNavBar` had no such spacer, so its 49dp label row began inside the
36dp tail and **the labels themselves were drawn at partial alpha.**

The evidence is that the glyphs now render at exactly their tokens:

| | rendered before | rendered after | token |
|---|---|---|---|
| selected, dark | (183,187,192) | **(228,235,242)** | `label` #E4EBF2 |
| unselected, dark | (119,131,139) | **(155,170,182)** | `labelSecondary` #9BAAB6 |
| unselected, light | (106,117,130) | **(72,90,105)** | `labelSecondary` #485A69 |

| | before | after |
|---|---|---|
| selected, dark | 4.94:1 | **15.29:1** |
| unselected, dark | 4.94:1 | **7.78:1** |
| unselected, light | 3.89:1 | **6.37:1** |

**It was diagnosed wrong twice first.** As a colour token, then as a type size,
then as a font weight. Bumping caption to subhead moved light from 3.89 to 4.26.
Adding a weight moved it to 4.22, which is nothing. Two changes that each looked
plausible and neither of which touched the cause; both are reverted, and the
type is what it always was. **A fix that does not move the number is not a fix,
and shipping it would have left the bug in place under a plausible-looking
comment.**

### 5. The pane lost its contrast when it moved

Fixing finding 2 moved the pane up into the ambient's strong zone, and the
question went back to reading off bright olive. Two changes:

- The ambient decays over 20% of the card rather than 16%, and holds more light
  in the slack below the pane, which is where the light is now visible at all.
- **Ultradünn went from 24% to 55%.** 24% was written against an assumption
  about what "over media" meant. The media here is an endoscopic frame lit by a
  xenon source. It is still by far the thinnest of the three and 45% of the
  light still passes.

Measured on the pane, dark: question **13.70:1**, *Fall öffnen* 6.51:1,
attribution 8.74:1, date line 6.71:1.

## Did not reproduce

**The carousel did not lose its position.** Reported as jumping from image 1 to
image 3 across a Fall round-trip. Tested twice on a clean flow: advance to
image 2, open Fall, back. The active dot read tint both before and after
(63,169,245). Tested again on the reviewer's exact path, switching appearance
while inside Fall: still image 2 (11,107,181, the light tint). Their sequence
involved several swipes and an appearance change, and the likeliest explanation
is their own bookkeeping. **Recorded so nobody fixes a bug that is not there.**

## Already named, still true

- **The heading rolls through a clinical vignette.** Confirmed on every card in
  both appearances. It is a content defect: `posts.json` puts the whole vignette
  in the `question` field. The card wants the interrogative only.
- **Dataset provenance stamps burnt into the source photographs** ("1a", "2a")
  collide with the status bar and the screen name at the top edge. Inherent to
  running an image full bleed under chrome, and not fixable in layout without
  cropping, which this app does not do. It goes away when the content set is
  real.

## Method note

Every number here was sampled off a screenshot of the running build with PIL and
converted through the WCAG relative-luminance formula, not estimated.

**One build in this round was never actually built.** A compound command changed
directory to the repo root, `flutter build` failed with `No pubspec.yaml file
found`, and the pipeline still exited 0, so the measurements that followed were
taken against the previous APK and showed no change. It was caught because two
runs produced byte-identical numbers. Every build after that reports its own
exit status.
