# Phase 4b, as built

A compliance pass. No new screen. It answers an adversarial audit of the
running build and two of the owner's own findings.

## The theme was still the fork's

`GiColors` was added in Phase 3 **beside** the fork's `AppColors` rather than in
place of it. `gi_colors.dart` matches `DESIGN.md` section 3 stop for stop, and
the Heute screen spends it correctly, so the palette itself was never wrong.
What was wrong is that nothing else did.

`AppTheme` built `ThemeData` from `AppColors`: 24 references in that one file,
132 across `lib/`. Every Material component that falls back to a theme colour -
a ripple, a default indicator, a divider, a text field - therefore drew from
Instagram's palette. That is the mechanism behind three separate findings:

- the carousel indicator on the fork's post screen sampled `#2196F3`, Flutter's
  stock `Colors.blue[500]`, on a screen that never asked for a colour at all
- the Archiv search field sampled `#424242`, `AppColors.darkGrey`
- the profile buttons sampled `#282525`, `AppColors.emphasizeDarkGrey`

None of those hexes is a stop on the ramp, and section 11 names a flat neutral
grey surface as a wrongness tell.

> **Correction.** As first written, this section implied all three were fixed
> by the repaint. **They were not.** A re-audit of the running build found the
> Archiv search field still sampling `#424242`, because that widget sets its
> own colour rather than reading the theme, and a theme repaint cannot reach a
> hardcoded one. The stock-blue indicator and the profile buttons were
> genuinely fixed by it. The search field went with the fork's Archiv when
> Phase 6 replaced that screen, which is a different fix from the one claimed
> here. Recorded rather than quietly edited: a phase report that overstates
> what shipped is worse than one that admits a gap.

`AppTheme` and `AppDarkTheme` now derive everything from `GiColors`, and the
two share one `_build` so they cannot drift. The `ColorScheme` is overwritten
with ramp stops rather than trusted, because Flex derives its surface tones by
blending and those blends are not on the ramp.

**`primary` is the tint, not the label colour.** Material spends `primary` on
what it decides is actionable. On a screen this product has not rebuilt yet,
that is where the one accent belongs, and it is what keeps stock blue off a
screen nobody has touched.

## Instagram identity that was still rendering

The profile screen drew Instagram's verified badge, in full colour, next to the
account name. Its shape and its blue are Instagram's identity, and
`ATTRIBUTION.md` obliges us to remove that. It is commented out at its render
site, per rule 3.

The same screen carried a posts/followers/following row and Edit profile,
Share profile and Follow buttons: an account and a social graph this product
does not have, rendered in English. Also commented out.

## The placeholder image is drawn now, not shipped

Five baked `.webp` files stood in for endoscopic images, and they were the most
frequently seen surface in the build. Their ground sampled `#1D1E22`, their body
text `#C6CACF`, their accent word `#B1783E`. None of those is on the ramp.

`GiImageView` replaces them. It reads the ramp, so it is correct in both
appearances by construction and stays correct if a stop moves, which a baked
asset can never do. The word *PLATZHALTER* carries `warning`, because that is
what orange is for here: a reader is owed the knowledge that this is not a real
case before they read the question next to it.

The `.webp` files stay in the repository. Nothing renders them.

The placeholder no longer prints `image.className`. That field carries the
dataset's own label, `polyp` or `oesophagitis-a`, which is an English developer
token in a German interface.

## Light appearance was unreachable

`ThemeModeBloc` was hard-coded to `ThemeMode.dark`, so the light ramp could not
be produced on a device at all and the audit could not confirm it works.
`DESIGN.md` section 3 says both appearances ship, following the system. It
follows the system now. Erscheinungsbild, in Phase 7, lets a reader override it.

## Two reversals of Phase 4

**The question type is `THERAPIESTRATEGIE` again.** Phase 4 shortened it to
THERAPIE, reasoning that `pipeline/src/lib/schema.ts` declares the enum as
`diagnosis | finding | treatment` and the schema is the source of truth. The
schema is the source of truth **for the data key**. The label is a display
string, and `DESIGN.md` and the screen mockups both spell it
`THERAPIESTRATEGIE`. A decided label was overwritten with a schema token, and
the mistake was written up as a correction to the spec.

**The top bar's right slot is back.** Phase 4 dropped it, reasoning that the
date already appears in the card's meta line and the header would be printing
the same fact twice. The mockup's right slot does not carry the date. It
carries *Heute*, the destination. With three tabs, that is the screen telling
you which one you are in.

## The bars are material

`GiMaterial` implements the Normal bar from section 4: blur 26, saturation 1.8,
tint at depth 0.30 graded 58% at the screen edge to 16% inward, masked to
transparent over the last 36dp so there is no hairline where chrome ends.

Saturation is the point. `BackdropFilter` on its own desaturates what sits
behind it, which is why default glass reads as fog on a window. `ColorFilter`
implements `ImageFilter`, so `ImageFilter.compose` puts a saturation matrix
outside the blur and pushes the colour back up.

The top bar and the tab bar both use it, and the card runs underneath both:
`extendBody: true`, `top: false`, `bottom: false`, with each bar carrying its
own inset. **Phase 8 still owns the rest**: Ultradünn, Dick, the shared
`BackdropGroup` pass, and the reduced-transparency collapse. The dimensions
here are the ones it will keep.

Two layout bugs came out of that change and are fixed:

- the card's text block ran under the tab bar, because the bar no longer
  shortens the body
- then it cleared the bar by 49dp too much, because with `extendBody` a
  Scaffold already reports the bar's height in the body's bottom padding, and
  adding `BottomNavBar.barHeight` counted it twice

Verified on `emulator-5554` by sampling the screenshot: the peek band is
`#080F14`, 26px tall, its lower edge exactly at the bar's upper edge; the bar's
tint reaches 58% of `#080F14` at the screen edge.

## The tab bar is words

Three text labels, active in semibold, matching the mockup. The fork's icons
were a house, a grid and an ellipsis borrowed from an app about photographs,
and three destinations named in Fachsprache do not need pictograms to tell them
apart.

## What is still the fork's

Everything reached from Heute. *Fall öffnen* still opens the fork's post
preview; Archiv and Mehr are still its screens, now painted from the ramp
rather than from Instagram's palette. Phases 5 to 7 replace them.

Light appearance is reachable but **was not visually verified** in this phase.
