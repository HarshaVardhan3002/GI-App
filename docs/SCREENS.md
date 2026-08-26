# Screens and placement

Every screen, what it contains, where each element sits, and the rule that makes
overlap structurally impossible rather than something to check by eye.

Placements are density-independent pixels against a 390x844 reference, verified
against 360x640 as the small case.

Visual reference:
<https://claude.ai/code/artifact/ae6c6466-eb8f-444a-a3a1-5cec0c8b23bb>

---

## 1. The anchoring rule

**The image is top-anchored. The text block is bottom-anchored. Neither knows
about the other.**

- Image: top 0, full width, height = width x 1.25. Never cropped by layout.
- Text block: bottom-anchored above `bottomBar + peek + margin`, height bounded
  because the question is capped at two lines.

Because they are anchored to opposite edges, neither can push the other off
screen. Where they meet, they meet inside the dissolve.

| Device | Screen | Image 4:5 | Text top | Overlap | Result |
|---|---|---|---|---|---|
| Small Android | 360x640 | 450 | 354 | **96** | Text on the dissolve |
| iPhone 14 | 390x844 | 488 | 558 | 0 | Text on open ground |
| Pixel 8 | 412x915 | 515 | 629 | 0 | Text on open ground |
| 15 Pro Max | 430x932 | 538 | 646 | 0 | Text on open ground |

**The dissolve is the collision-absorption mechanism, not decoration.** Worst
overlap is 96dp against a 150dp dissolve, 54dp spare. Shortening it below 96
breaks the small-device layout, so its height is a constraint rather than a
taste.

**The two-line cap on the question is what makes this provable.** An uncapped
headline makes the text block unbounded and collision undecidable at design time.

### A bug this arithmetic caught

The attribution was specced onto the image's lower edge. On 360x640 the text
block is also there, so they would have collided on the smallest device we
target. **The attribution moves into the text block as its last line** - still
directly beneath the image, still unambiguously about it, and now impossible to
collide with.

## 2. Layers

Only the image and its dissolve may enter a chrome zone. **Text never does.**

| z | Layer | Note |
|---|---|---|
| 5 | System status bar, home indicator | OS |
| 4 | Material bars, top and bottom | Content passes under |
| 3 | Peek, 10dp of yesterday | Above the bottom bar |
| 2 | Text block | Bottom anchored |
| 1 | Image and dissolve | Top anchored, full bleed |
| 0 | Ground, depth 0.00 | Everywhere |

## 3. Screens

### Heute
Wordmark and day in the top bar. Image full-bleed under it. Text block bottom
anchored: carousel dots, `25. AUGUST · THERAPIESTRATEGIE`, the question in
Newsreader 26, *Fall öffnen* as the only tinted element, attribution last. Peek
above the bottom bar. Three tabs.

### Fall, before answering
Back to the day it came from, date on the right. Image at 40% with a shorter
dissolve, since this screen is for reading rather than looking. Meta, question in
full, answers as one inset group, *Antwort bestätigen* full width. Content
scrolls; the button scrolls with it.

### Fall, revealed
Verdict on one line. `BEGRÜNDUNG` group header, explanation in Fira. Then
`EMPFEHLUNG 6.12 · GRAD EK` and one inset group holding the quote in Newsreader,
Konsensstärke, the citation line, and *Quelle* as a disclosure row. The quote and
its citation are rows of the same group so they cannot be separated by a later
layout change.

### Herkunft, sheet
Dick material, grabber, drag to dismiss. Placeholder warning first when it
applies. Then Bildnachweis per image, Leitlinie, and Freigabe. The guideline URL
says it leaves the app before it does.

### Archiv
Inline title with a case count. Two-column contact sheet at 4:5 with 2dp gutters
and a sticky month header. Each cell carries its date over a scrim and a small
`correct` dot when answered. Tapping opens the same detail screen.

### Mehr
Three groups. **Darstellung**: Erscheinungsbild, Sprache. **Herkunft der
Inhalte**: Bildquellen, Leitlinien und Rechte, Inhaltsstatus. **Über**: Über GI
Daily, Impressum, Version.

No tinted element: a settings list has no single next action.

### Erscheinungsbild
System, Hell, Dunkel, with a checkmark. A footnote states that dark is designed
for viewing endoscopic images and light is available but not the default.

### Inhaltsstatus
Counts of approved, draft and rejected, then how many images and recommendations
are still placeholders. **This is the constraint made inspectable**: a claim that
only approved content renders is worth nothing if nobody can check it.

### Leerzustand
Wordmark, one line explaining that nothing is released yet. No illustration, no
button, no retry. The tab bar stays so the reader is not stranded.

## 4. Two naming decisions

**Profil becomes Mehr.** There is no account, so there is no profile. A tab
called Profil promises a person and delivers settings, which is the kind of small
lie that makes an app feel borrowed rather than built.

**Impressum is not optional.** A German product published to an app store needs
one. It is a legal obligation, not a page we chose, and it sits under Über with
the version.

## 5. Rules every screen obeys

1. **Scrollable content clears the bars.** Bottom padding equals bar height plus
   safe area, so the last row scrolls clear. Content passes under the material;
   it never ends beneath it.
2. **Grouped lists, never cards.** Settings, provenance and answers use the same
   inset group at depth 0.30 with hairlines. One shape means a new screen needs
   no new decision.
3. **One tinted element per screen**, marking the single next action. Mehr has
   none.
4. **Titles inline, not large.** A collapsing large title would fight the
   wordmark and cost vertical space on the screen with least to spare.
5. **Every sub-screen is one push deep.** Mehr is the only screen that pushes,
   and it never pushes twice.
6. **Numbers are tabular.** Counts, dates, AWMF register numbers and versions,
   so columns line up and a citation never looks sloppy.
7. **Nothing is more than two steps from today.**
