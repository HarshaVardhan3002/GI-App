# Phase 4, as built

Heute. One case per screen, swiped vertically.

## The seam moved forward, on purpose

The plan put `CaseSource` in Phase 5. The card carries the image's attribution
line, and attribution lives on the case rather than on the feed's `Post`, so the
seam had to exist before the card could be honest. **Building the card against
the feed's model and adding attribution later would have meant shipping a screen
that could not show where its image came from**, which is constraint 1.

`packages/database_client/lib/src/case_source.dart` now holds `CaseSource` and
five interfaces: `GiCase`, `GiOption`, `GiImage`, `GiRecommendation`,
`GiGuideline`. It sits beside `DatabaseClient` rather than on it, because it is
this product's own shape rather than a gap in the fork's.

`LocalDatabaseClient implements CaseSource`, and `LocalCase` and four small
wrappers implement the rest, so the raw JSON maps stop leaking upward. The seam
is provided above the router in `main_local.dart`, so any route can read it and
none of them knows it is four JSON files.

## The layout, as specified and as verified

The image is top-anchored, full width, height = width x 1.25, never cropped by
layout. The text block is bottom-anchored above `peek + margin`. **Neither knows
the other exists**, which is what makes overlap structurally impossible instead
of something to check by eye.

Verified by forcing the emulator to the smallest device we target:

```
adb shell wm size 360x640 && adb shell wm density 160
```

The prediction was 96dp of overlap absorbed by a 150dp dissolve. What the device
shows is the meta line and the question sitting on the dissolve, nothing
clipped, nothing touching the bottom bar, and the question truncating at two
lines. **The dissolve is doing the job the arithmetic assigned it.**

The last case draws no peek, so the reader can see they have reached the end
without being told.

> **Two of the three "corrections" below were wrong, and were reversed in
> phase 4b.** The question-type label and the top bar's right slot are both
> restored to what the design documents and the screen mockups specified. The
> section is kept as written rather than edited, because the reasoning that
> produced the mistake is worth reading. See `docs/PHASE-4B.md`.

## Three corrections to the design documents

**Question types were guessed.** `DESIGN.md` and `docs/SCREENS.md` used
`THERAPIESTRATEGIE` and `KLASSIFIKATION`. `pipeline/src/lib/schema.ts` declares
the enum as `diagnosis | finding | treatment`, and the schema is the source of
truth. The labels are now BEFUND, DIAGNOSE and THERAPIE. Before this the card
rendered a raw `TREATMENT` in English, because the switch fell through.

**The wordmark had nowhere to go.** With the image running full bleed to the top
of the screen there is no app bar to put it in, so it sits over the image on a
scrim. The scrim is not decoration: an endoscopic image can be bright at its top
edge, and white text on it would become unreadable exactly when the image is at
its best. Phase 8 replaces the scrim with the Normal material; the wordmark does
not move when it does.

**The date is not repeated in the header.** `docs/SCREENS.md` put it in the top
bar as well as in the card's meta line. On one screen that is the same fact
printed twice. The card keeps it, because there it belongs to a case rather than
to the app. **This is a deliberate departure from the spec and is flagged for
review rather than buried.**

## What is still the fork's

Tapping *Fall öffnen* opens the fork's post preview screen. Phase 5 replaces it
with the case screen. Archiv and Mehr are untouched.

`FeedPage`, `FeedBloc` and the whole feed remain wired and unrendered, one
commented line in `app_router.dart` from coming back.
