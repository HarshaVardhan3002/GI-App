# CLAUDE.md - build guidelines for GI-App

These are the standing rules for this repository. They come from the project
owner and they override any default habit, any earlier decision in this repo,
and any instinct to do it a faster way. When something here conflicts with a
skill's advice, this file wins.

---

## 1. What we are building

**A frontend. Nothing else.**

The Instagram fork is the chassis. Its look, its motion, its smoothness and its
working feel are the target - that quality bar is the point of forking it.
Everything behind the UI is scaffolding to be replaced later.

- **The backend is scrapped.** No Supabase, no PowerSync, no Firebase. What
 exists today is local stand-ins behind the app's own interfaces.
- **Every backend seam stays open.** A real backend arrives later. Work must
 leave clean interfaces to plug into, never assumptions baked into widgets.
- **Content is provisional.** Every string, question, explanation and label is a
 placeholder for physicians and teammates to review and rewrite. Build so that
 content can be edited without touching code.

## 2. Instagram identity comes out. The Instagram feel stays in.

Two different things, and they are not negotiable in either direction.

**Remove entirely:** the wordmark, the logo, the name, the brand colours, any
asset carrying Instagram identity. This is a licensing obligation, not taste.
See `ATTRIBUTION.md`.

**Keep and match:** scroll physics, transition timing, gesture response, the
feel of a tap, the way media loads, the polish. If the rebuilt screen feels
worse than the fork did, it is wrong.

## 3. Comment out. Do not delete.

Features this product does not need - stories, likes, shares, comments, reels,
chat, follow - are **removed from the UI only**, by commenting out their render
sites.

- Comment out where they render. Leave the widget, the bloc, the repository
 method and the model in place.
- Every commented block carries a one-line reason.
- Do not delete files. Do not delete dependencies. Do not "clean up" what a
 comment already handles.

**Why:** deleting breaks dependencies in places that are not obvious, and this
product may want some of it back. Reversible beats tidy.

## 4. Plan before code

No implementation without a plan that answers what, where, why and what it
touches.

Before writing code for a screen or component, the following must already be
written down: what it does, which components it depends on, which components
depend on it, what breaks if it changes, and what the design decision is.

Dependency knowledge is **mapped in advance, not searched for mid-task**. When a
component is touched, its blast radius is already known - one hop, no hunting.

## 5. Delegate verification to a small agent, tightly scoped

Whenever a component is implemented, removed, or changed in a way that is
**UI/UX-critical or system-critical**, verification is delegated to a small
subagent (Sonnet).

The subagent's job is to execute and report. Nothing else.

- **It gets exact instructions:** which build, which screen, which taps, in what
 order, what to look for, what to report.
- **It gets no freedom to explore.** No wandering the codebase, no reading files
 it was not pointed at, no deciding what to test.
- **It runs the live app** - build, install, launch, tap through the flow, take
 screenshots - and reports back what happened.
- **It burns the minimum tokens possible.** The main thread does the thinking;
 the subagent does the clicking. If the instructions are vague enough that the
 agent has to explore, the instructions are wrong.

## 6. Every design decision goes through `impeccable`

All UI work follows the `impeccable` skill and its directives - the craft floor,
the mode, the committed visual world. `PRODUCT.md` and `DESIGN.md` hold the
durable decisions; they are read before designing and updated when a decision
changes.

`impeccable` also audits for AI-generated slop in design: templated layouts,
default palettes, card-grid scaffolds, decoration standing in for content. That
audit is part of the work, not an optional pass.

## 7. Every string goes through `humanizer`

Any text that lands in the app, in content, or in user-facing documentation is
checked with the `humanizer` skill for AI-writing tells before it ships.

This applies to German and English alike, and to content already in the
repository - the existing placeholder strings are in scope and have not been
checked yet.

## 8. Copy and content tells

Checked alongside `humanizer`. These come from the `design-taste-frontend`
skill's AI-tells catalogue, which is a web skill and is otherwise out of scope
here (see the note at the end of this section).

**Punctuation**

- **No em-dash (`—`) in English text.** Anywhere: headings, labels, buttons,
  body, commit messages, documentation. Restructure into two sentences, a comma,
  a colon, or parentheses. It is the single most reliable tell that a machine
  wrote the sentence.
- **German keeps its Gedankenstrich.** The spaced en dash (`–`) is correct German
  orthography and stays in German strings. Do not "fix" it into a hyphen.
- Number and date ranges use a plain hyphen: `17-18 September`, `400-800`.
- The middle dot (`·`) is rationed to one per line. It is a separator, not a
  texture.

**Content**

- No invented precision. A number is real, or it is labelled as a placeholder.
  Fake specificity (`92%`, `4.1x`) reads as authority the product has not earned,
  and in a clinical product it is worse than sloppy.
- No decorative status dots, version stamps, build numbers, scroll cues, or
  locale and time strips. None of them carry information here.
- No section-number labels (`01 / Befund`). The screen's position already says
  where you are.
- Labels name the thing plainly. No performative-craftsman headings
  ("Aus der Praxis", "Feldnotizen") standing in for a functional label.
- Placeholder names must read as placeholders, never as plausible people.

**Before shipping any screen, re-read every visible string.** Any string that is
grammatically broken, has an unclear referent, or is cute rather than clear gets
rewritten. Boring and correct beats clever and wrong, and in a medical product
the gap is not stylistic.

**Scope note.** `design-taste-frontend` is a web skill (React, Tailwind, Motion,
`backdrop-filter`) and declares native mobile out of scope. Only its
medium-agnostic tells are adopted above. Layout, stack and design-system rules
come from `impeccable` and from platform convention, not from that skill.

## 9. Report honestly

State what was verified and how. If something was not tested, say so. If a
screenshot shows a defect, name it before the user has to. Never describe work
as done because it compiled.

---

## Standing constraints (from the product, not negotiable)

1. **No patient data.** Open, de-identified CC BY 4.0 datasets only, attribution
 on screen.
2. **Guideline text is cited, never redistributed.** 400 characters maximum,
 always with citation.
3. **Nothing unreviewed reaches a user.** `draft` until a physician approves it;
 only `approved` renders.
4. **German UI, German content, Fachsprache.** No mascots, no confetti, no
 gamification. English exists only as a developer debug locale.

## Environment

- Flutter 3.35.7 at `C:\src\flutter`, JDK 17, Android SDK 36, AVD
 `pixel8_api36`.
- Run: `cd app && flutter run -t lib/main_local.dart --flavor development`
- **No iOS Simulator on Windows.** Anything about iOS gesture feel or posture is
 unverified until someone runs it on a Mac, and must be reported that way.
