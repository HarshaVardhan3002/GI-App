# Phase 6, as built

Archiv, and the answered state the rest of the app was missing.

## Answers needed a seam of their own

`DESIGN.md` section 8 specifies an answered state: stored locally, one fact per
case, **no score, no streak, no history, nothing that leaves the device**, and
an answered card that reads *Auflösung ansehen* and opens straight to the
reveal. None of that existed. Phase 5 kept the answer in a `State` object and
said so.

`AnswerSource` is a second seam beside `CaseSource`, and deliberately not part
of it. **Cases arrive from a publisher; answers are the reader's own** and will
belong to whatever account system exists later. Merging them would mean a
backend implementing one interface on behalf of two different owners.

It is a `Listenable`, so answering a case updates the card behind it and the
cell in Archiv without either screen being rebuilt or reloaded.

`LocalAnswerStore` is the stand-in: one JSON blob through the app's existing
`Storage` interface, read once before the first frame. Reads are synchronous
because a contact sheet asks about every visible cell while it scrolls.

**A case is answered once.** `record` keeps the first answer and ignores a
second. The reveal is not something to retry until it comes out green, and
Archiv would be lying if it were.

`isCorrect` is stored rather than recomputed on read. Content is provisional and
may be corrected after the fact, and a mark in Archiv should say what happened,
not what would happen today.

## Archiv is a contact sheet

Two columns at 4:5 with 2dp between them. **These are images.** A physician
looking for the case they half remember is scanning for a shape and a colour,
not reading a list of dates with thumbnails beside them.

Inline title with the case count, per the mockups' own rule that titles are
inline rather than large. The count is not decoration: it tells a reader
whether there are twelve cases behind this or two hundred before they start
scrolling.

One pinned month header per month, on the ground colour rather than on a
material, because it is part of the sheet rather than chrome over it.

Cases are grouped in the order `CaseSource` gives them and **not re-sorted**. A
content set that arrived in the wrong order should show that, not have it
hidden by the screen.

The date sits over a scrim rather than under a text shadow. Section 11 rules
out cast shadows, and a scrim does the same job as a surface instead of as an
effect.

## One departure from `docs/SCREENS.md`, deliberate

`SCREENS.md` specifies "a small `correct` dot when answered". Taken literally
that puts a **green** mark on a case the reader got wrong. In a product about
clinical reasoning that is not a small inaccuracy.

A correctly answered case gets `correct`. A wrongly answered one gets
`labelTertiary`: present, unmistakably not green, and not red either, because a
grid of red dots is a scoreboard and constraint 4 rules out gamification.

**Flagged for review rather than decided quietly.**

## The placeholder shrinks

A contact-sheet cell cannot carry the full placeholder notice. Below 220dp the
stand-in draws the word *PLATZHALTER* alone: it is the part that has to survive,
because it is the one telling a reader this is not a real case.

## A defect the analyzer passed

`ListenableProvider`, not `RepositoryProvider`. Providing `AnswerSource` as a
plain value compiled and analyzed clean, then threw on the first frame - the
whole app rendered black:

```
Tried to use Provider with a subtype of Listenable/Stream (AnswerSource).
```

`provider` is now a direct dependency. It was already in the tree through
`flutter_bloc`, which re-exports `RepositoryProvider` but not
`ListenableProvider`.

## The re-audit

An adversarial pass over the previous build reported six findings. Two were
real and are fixed here:

- **the answered state was not built at all**, against `DESIGN.md:253`
- **`docs/PHASE-4B.md` overstated what it fixed.** It listed the Archiv search
  field's `#424242` among findings the theme repaint resolved. A repaint cannot
  reach a colour a widget hardcodes, and the field was still grey on the running
  build. That document now carries the correction rather than a quiet edit.

Four were not defects, and are recorded here so they are not re-fixed later:

- **"the selected answer row is lighter, not darker."** It is depth 0.60,
  `surfacePressed`, which is what the mockups and `DESIGN.md` both specify for a
  row under a finger. The audit brief said "darker", and the audit brief was
  wrong.
- **"inactive carousel dots sample `#4C4C4C`, off the ramp."** They are the
  label colour at 30% over depth 0.30, exactly as the mockup sets them. The
  sample is a composite, not a surface.
- **"the Herkunft warning banner samples `#271C0A`, off the ramp."** Same:
  `warning` at 14%, exactly as the mockup sets it.
- **the Mehr avatar is a stock grey asset.** True, and it is Phase 7's screen.

## Verified

On `emulator-5554`: Archiv renders three cases under a pinned `AUGUST 2026`,
titled `Archiv · 3 Fälle`. Answering the first case turns its card's action to
*Auflösung ansehen* and puts a dot on its cell sampling `#30D158`, the `correct`
stop. Re-opening an answered case goes straight to the reveal.

Persistence checked by force-stopping the app and relaunching: the answer
survives, and the reopened case comes back on its reveal.

**Not verified:** the light appearance, and anything about iOS feel.

## What is still the fork's

Mehr. Phase 7.
