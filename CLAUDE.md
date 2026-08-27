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

## 5. Subagents walk the app. They never read the code.

**When the owner says "spin up a subagent", they mean one thing: a Sonnet agent
that opens the running app, walks it, and reports what it saw.** There is no
other kind. It is a pair of eyes and a pair of thumbs, not a second engineer.

### What it does

- Builds are already installed; it launches the app and navigates it.
- It takes screenshots at every step and **looks at them**, and it may measure
  them (pixel sampling, contrast arithmetic) to turn an impression into a
  number.
- It reports **exact location and exact behaviour**: which screen, which
  element, what it did, what it should have done, with the coordinate or the
  measurement that proves it.
- It reads `DESIGN.md`, `PRODUCT.md` and `docs/` so it can hold the app against
  what the design says, and it names anything the running app does that those
  documents do not.

### What it must never do

**It does not touch the code. Not to read it, not to search it, not to explain
a defect with it, and never to change it.** No source files, no `flutter
analyze`, no grep, no diffs, no "the cause is probably in". It reports the
symptom and stops. Diagnosis and every edit belong to the main thread, which is
the only agent allowed near the source.

The reason is not tidiness. **An agent that has read the implementation stops
seeing the screen and starts confirming the code**, and the whole value of a
second pair of eyes is that they have not been told what the screen is supposed
to be doing.

### How it is briefed

- **Exact instructions:** which screens, which taps, in what order, in which
  appearance, what to capture, what to report. If the brief is vague enough
  that the agent has to go looking, the brief is wrong.
- **No freedom to explore.** It does not decide what to test.
- **Minimum tokens.** The main thread does the thinking; the subagent does the
  clicking and the looking.
- **Harsh by default.** It is told to find what is wrong. Praise is not output.

### What the main thread owes it back

Findings are **verified before they are believed**. A subagent reporting a
defect is a lead, not a fact: reproduce it, measure it, and if it does not
reproduce, say so in the phase record so nobody fixes a bug that is not there.
A fix that does not move the number is not a fix.

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

## 9. Every phase lands on its own branch

**Nothing is committed to `main` while the owner is away.**

- Each phase is implemented on `phase-N-<name>`, branched from `main`.
- The phase is committed and pushed on that branch and nowhere else.
- `main` moves only when the owner has read the branch and says so. Merging is
 their call, not a step in the work.
- A branch that is not finished honestly stays unmerged and says why in its own
 report.

**Why:** an unattended run that pushes straight to `main` gives the owner a
single pile to accept or reject. Branches give them a phase they can take and a
phase they can leave.

## 10. The goal does not bend. The route does.

The plan will meet things it assumed wrong. That is expected and it is not a
reason to reduce what the app does.

**When an assumption fails, find another way to the same outcome.** The route is
disposable; the outcome is not. This work is not limited to what is already in
this repository: pub.dev, the Flutter source, GitHub, and the wider community
are all in scope. A missing package, an API that turned out different, a widget
that will not do what was assumed - each is a research problem, never a licence
to ship less.

**An alternative is not a pivot.** The distinction is the whole rule:

| | |
|---|---|
| **Alternative** *(proceed, and record it)* | Same outcome, different means. A different package, a different widget, a different layout mechanism, a hand-written version of something a library refused to do, an extra dependency, a different order of work |
| **Pivot** *(stop, do not proceed)* | The outcome itself changes. A screen dropped, a feature reduced, a constraint loosened, a design decision from `DESIGN.md` reversed, a product decision from `PRODUCT.md` reversed, the plan's shape altered |

**On a pivot: stop immediately and ask.** Do not implement a reduced version
first and raise it afterwards. Do not leave a placeholder standing in for the
thing. Do not decide alone that a smaller scope was what was meant. Stop, say
exactly what blocked the route and what the options are, and wait.

The one thing that is neither: work that cannot be done honestly on this
machine, or without a physician, or without a dataset that is not here. That is
left undone, named as undone, and the rest of the phase finishes around it.

## 11. Report honestly

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
