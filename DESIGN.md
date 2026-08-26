# DESIGN.md — gi-daily-app

Durable visual decisions. Mode: **Operate** — the visitor completes a task
(answer, understand, leave). Scanability and native expectation outrank
expression; the brand lives in precision.

## The world

**A clinical instrument, not a clinical app.** Near-black ground, one system
tint, and the endoscopic image carrying every pixel of colour on the screen.
The interface's job is to disappear the moment the image loads and to reappear,
precisely, when there is something to read.

Two rules everything else derives from:

1. **The image is the only saturated thing.** Endoscopy is red, wet and lit.
   Any chrome that competes with it loses, so the chrome does not compete: no
   coloured cards, no gradients, no decorative fills. Colour appears in exactly
   three places — the tint on interactive elements, green and red on the verdict,
   orange on a placeholder warning.
2. **Space is the luxury signal.** A Facharzt reading between cases needs the
   question to be the only thing in the viewport once the image is scrolled past.
   Sections are separated by 32–40pt, not 16.

## Appearance

**Dark only.** Picked from the use scene — an endoscopy suite with the room
lights down — not from category habit. A light mode would mean a second set of
decisions about how images sit against chrome, for a screen nobody will read in
daylight.

## Colour

iOS semantic dark values, used as their semantic role and not as decoration.

| Token | Value | Role |
|---|---|---|
| `background` | `#000000` | systemBackground. True black; the image floats on it. |
| `groupedSurface` | `#1C1C1E` | secondarySystemGroupedBackground. Inset list containers. |
| `raisedSurface` | `#2C2C2E` | tertiarySystemBackground. Selected rows, pills. |
| `separator` | `#38383A` | Hairlines inside grouped lists. |
| `label` | `#FFFFFF` | Primary text. |
| `secondaryLabel` | `rgba(235,235,245,.60)` | Supporting text. |
| `tertiaryLabel` | `rgba(235,235,245,.30)` | Metadata, captions. |
| `tint` | `#0A84FF` | systemBlue dark. **Every** interactive element. |
| `correct` | `#30D158` | systemGreen dark. Verdict only. |
| `incorrect` | `#FF453A` | systemRed dark. Verdict only. |
| `warning` | `#FF9F0A` | systemOrange dark. Placeholder marking only. |

One tint drives interaction; decoration is not its job. Green and red never
appear on anything that is not a verdict — no green buttons, no red borders.

## Type

**Inter**, self-hosted, at Apple's text-style metrics. SF Pro cannot ship off
Apple platforms, and the nearest installed system face would be a fallback
rather than a choice; Inter is a real face with SF-adjacent proportions.

| Style | Size / line | Weight | Use |
|---|---|---|---|
| Large Title | 34 / 41 | 700 | The collapsing screen title. |
| Title 2 | 22 / 28 | 700 | The question. |
| Headline | 17 / 22 | 600 | Card titles, verdict. |
| Body | 17 / 24 | 400 | Explanation, answer options. |
| Callout | 16 / 21 | 400 | Quoted guideline text. |
| Subhead | 15 / 20 | 400 | Supporting. |
| Footnote | 13 / 18 | 400 | Attribution, citation. |
| Caption | 12 / 16 | 500 | Grouped-list headers, metadata. |

Tracking tightens as size grows: −0.4pt at Large Title, −0.2 at Title 2, 0 at
Body. Grouped-list headers are uppercase at +0.5 tracking — the iOS convention,
and the one place uppercase is allowed.

## Shape

**Apple's squircle, not a rounded rectangle.** `ClipRSuperellipse` and
`RSuperellipse` ship in Flutter 3.35 and produce the continuous curvature iOS
actually uses; a circular `BorderRadius` at the same value reads subtly wrong
next to system chrome.

Radii: `10` inset rows · `14` buttons and grouped containers · `20` sheets.

## Space

Base unit 4. Horizontal gutter **20**, which is iOS's inset-grouped margin and
wider than Material's 16. Vertical rhythm: `8` inside a group, `16` between
related blocks, `32` between sections, `40` before a section that starts a new
idea. More space above a heading than below it.

Touch targets never below 44×44. Answer rows are 56 tall.

## Structure

Single screen. No tab bar — there is one case a day and nothing to navigate to,
and a tab bar with one tab is a lie about the product's depth.

`CupertinoSliverNavigationBar` carries the large title "Heute", collapsing to
inline with a system blur as the case scrolls up. The media is full-bleed under
it. The source of a case opens in a `CupertinoSheetRoute` — the real stacked-card
sheet, dismissible by swipe — never a modal.

Answer options are an **inset grouped list**: one squircle container, hairline
separators, a checkmark on the selected row. Not four cards. Cards are the lazy
container and four of them stacked is the shape every AI quiz app produces.

## Motion

**One authored moment: the reveal.** Everything else is state, not animation.

On confirm, the options settle out of interactive appearance and the reveal
rises 24pt with an exponential ease-out over 420ms, the verdict leading. Nothing
bounces, nothing pops, nothing celebrates — a correct answer at Facharzt level is
the expected outcome, not an achievement. Reduce Motion crossfades instead.

## Iconography

`CupertinoIcons` — Apple's own set, one consistent weight. No emoji, no mixed
web icon set.

## What would make a polished result feel wrong

- Any celebration on a correct answer.
- A progress bar, streak counter, XP, or score.
- The interface tinting the endoscopic image, or any colour near it.
- A quote rendered without its citation.
- Placeholder content that does not announce itself.
