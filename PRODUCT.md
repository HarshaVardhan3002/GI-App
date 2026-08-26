# PRODUCT.md - GI Daily

## What it is

A daily learning app for German gastroenterologists. One endoscopic image per
day, one Facharzt-level multiple-choice question about it, and a reveal whose
explanation traces back to a numbered recommendation in a DGVS clinical
guideline.

Instagram, not Duolingo: a single post per day, image-dominant, unbingeable. You
come back tomorrow because there is a new one.

**The image is the hook. The guideline recommendation is the payoff.**

## Who it is for

Gastroenterologists in and past Facharzt training. Fluent German, fluent
Fachsprache. They read endoscopic images all day; they do not need an
interface explaining what a polyp is. They are the opposite of a gamified
learner: condescension is the fastest way to lose them.

## The use scene

Ninety seconds, once a day. Standing between cases, phone in one hand, often in
an endoscopy suite where the room lights are down and the screens are bright.
That scene picks the appearance: **dark, always.** A white interface next to a
dark endoscopy monitor is a flashlight in the face.

## What success looks like

A physician answers, is wrong, reads why, and remembers the recommendation
number. Not a streak. Not a score.

## The three question types

`diagnosis` - what is this? · `finding` - what do we see endoscopically? ·
`treatment` - what is the right strategy from here?

## Hard constraints

1. **No patient data.** Images only from open, de-identified CC BY 4.0 datasets
 (HyperKvasir, GastroVision). Attribution renders on screen.
2. **Guideline text is cited, never redistributed.** Max 400 characters quoted,
 always with its citation. Copyright is the AWMF author collective's; shipping
 needs a separate rights agreement.
3. **Nothing unreviewed reaches a user.** Generated content is `draft` until a
 physician approves it. Only `approved` renders.
4. **German UI, German content, Fachsprache.** No mascots, no confetti, no
 gamification aesthetic. English exists only as a developer debug locale.

## Platform

Flutter, shipping to Android and iOS, built on a fork of an existing Instagram
client. The fork's motion, scroll physics and polish are the quality bar and are
kept; its identity is removed. Development happens on Windows, so builds are
verified on the Android emulator and anything about iOS gesture feel remains
unverified until someone runs it on a Mac.

Both light and dark appearances ship, following the system.

## Context

DGVS Hackathon 2026, Viszeralmedizin congress, Hamburg, 17-18 September. Team of
three developers and two physicians. The deliverable is a working prototype
demoed to a jury in roughly ten minutes - not a shipped product.

## Architecture

Content is data, not code. The app reads JSON from its own bundle; no widget
knows what is in it. `pipeline/src/lib/schema.ts` is the contract, and content is
edited by physicians and teammates as JSON - never by editing Dart.

There is no backend, and every seam where one would attach is a clean interface
with a local implementation behind it. See `docs/COMPONENT-MAP.md` §5.

## Assumptions

Recorded because they were inferred from the brief rather than answered in an
interview:

- Ninety-second, once-daily use in a low-light clinical setting.
- The jury sees the app on a phone or a projected phone screen, not a tablet.
- Sound is off. Nothing may depend on audio.
