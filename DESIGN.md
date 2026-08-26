# DESIGN.md - GI Daily

Durable visual decisions. Mode: **Operate** - the reader completes a task
(answer, understand, leave). Scanability and native expectation outrank
expression; the brand lives in precision.

The chassis is the forked Instagram app. Its motion, scroll physics and polish
are the quality bar and are **kept**. Its identity is **removed**. Those are two
different jobs and neither substitutes for the other.

---

## 1. The world

**A clinical instrument that behaves like a social feed.**

The endoscopic image is the only saturated thing on screen. Everything else
recedes so it can lead. The interface's job is to disappear while you look, and
to be exact when you read.

Three rules everything derives from:

1. **The image is the only colour.** Endoscopy is red, wet and lit. Chrome that
 competes loses. No coloured cards, no gradients, no decorative fills. Colour
 appears in four places only: the tint on interactive elements, green and red
 on a verdict, orange on a placeholder warning, and the image itself.
2. **Space is the luxury signal.** A Facharzt reading between cases needs one
 thing at a time. Sections separate by 32-40, not 16.
3. **Nothing celebrates.** A correct answer at Facharzt level is the expected
 outcome, not an achievement. No confetti, no streaks, no score, no mascot.

## 2. Name and wordmark

**GI Daily.**

Set in **Newsreader at 20 / 24, weight 400**, tracking -0.2, sentence case -
*GI Daily*, never all-caps and never a logotype pretending to be a signature
script. It is the first of the three places this product uses a serif, alongside
the question and the guideline quote (§5).

Newsreader carries an optical-size axis, so `opsz` is pinned to 20 at the
wordmark. Left at the font's default of 18 the letterforms are drawn with
slightly too much contrast for the size.

It replaces `AppLogo`, which rendered an SVG. A vector scales into any box; text
does not, so the widget keeps the SVG's `fit` / `width` / `height` contract and
scales the wordmark into a box when a caller gives it one. No call site had to
change.

No icon-plus-name lockup. The name alone, because at 20pt in a header a mark and
a word compete and the word wins.

## 3. Colour is a ramp

Hard-set tokens produce a visible step wherever two meet. The ground is a
continuous ramp of glacier-biased near-blacks, and a component asks for a
**depth between 0 and 1** rather than a named colour. Named stops are positions
on the ramp.

| Depth | Dark | Light | Named |
|---|---|---|---|
| 0.00 | `#000000` | `#FFFFFF` | `surface` |
| 0.15 | `#04080B` | `#F7FAFC` | |
| 0.30 | `#080F14` | `#F1F5F9` | `surfaceRaised` |
| 0.45 | `#0C161D` | `#E9F0F6` | |
| 0.60 | `#122029` | `#E0EAF2` | `surfacePressed` |
| 0.80 | `#182A35` | `#D6E2EC` | |
| 1.00 | `#1E3542` | `#C9D8E4` | `separator` |

**No surface is neutral grey.** Every depth carries a trace of the tint, so the
ground reads as one material lit at different depths rather than separate greys
stacked on each other.

| Semantic | Light | Dark |
|---|---|---|
| `label` | `#0B1620` | `#FFFFFF` |
| `labelSecondary` | `#485A69` | `#9BAAB6` |
| `labelTertiary` | `#7A8B99` | `#6B7A86` |
| `tint` | `#0B6BB5` | `#3FA9F5` |
| `correct` | `#2E7D4F` | `#30D158` |
| `incorrect` | `#C0392B` | `#FF453A` |
| `warning` | `#B26A00` | `#FF9F0A` |

Text holds 12.55:1 or better at every depth. Green and red never appear on
anything that is not a verdict.

Both appearances ship, following the system.

## 4. Material

**The difference between glass and frost is saturation, not blur.** Flutter's
`BackdropFilter` desaturates what sits behind it, which is why default glass
reads as fog on a window. Apple's materials blur and push saturation back up, so
light appears to pass through the surface rather than stop at it.

Native, no package: `ColorFilter implements ImageFilter`, so
`ImageFilter.compose` takes a saturation filter outside a blur.

| Material | Blur | Saturation | Tint | Where |
|---|---|---|---|---|
| Ultradünn | 18 | 1.8 | depth 0.30 at 24% | Over media |
| Normal | 26 | 1.8 | depth 0.30, graded 58% to 16% | Bars |
| Dick | 40 | 1.5 | depth 0.15 at 88% | Sheets |

Four rules keep it a material rather than decoration:

1. **Bars and sheets only.** Glass means floating over moving content. Never on
   cards, rows or badges sitting on a flat ground.
2. **No grain, no noise.** Grain over blur is what makes frost read as dirty.
3. **Fade, never stop.** Trailing edges mask to transparent over ~36dp. No
   hairline marks where chrome ends.
4. **Edges are light, not shadow.** A 1px inset highlight at 16% white, a 1px
   inset shade below. **No cast shadows anywhere in this app.** Elevation is
   blur radius and edge light.

Reduced transparency collapses each material to an opaque surface at the same
depth.

**Cost.** `BackdropFilter` forces a save-layer and reads the framebuffer back.
Solved rather than rationed: `BackdropGroup` with `BackdropFilter.grouped` makes
every material on a route share **one** backdrop pass, and the `enabled` flag
turns the effect off without changing a single dimension. See
`docs/MATERIAL-IMPLEMENTATION.md`. Never inside a list item.

## 5. Type

**Fira Sans and Newsreader.** Two families, one boundary.

### The boundary: read against operate

Newsreader appears at the two moments the reader stops and reads deliberately,
plus the identity. Fira Sans carries everything that is scanned or operated.
That line is the whole discipline of the pairing, and mixing the faces outside
it is what turns an editorial idea into decoration.

| Newsreader, three uses only | Fira Sans, everything else |
|---|---|
| The wordmark | Answers, buttons, controls |
| The question | The explanation |
| The guideline quote | Labels, metadata, dates, citations, navigation |

The quote earns the serif honestly: it is matter published elsewhere, set in a
serif at its source, and the change of face marks where our prose stops and the
guideline's begins. The explanation stays in Fira because it is our own writing
and the longest text on screen, and a serif at that length on a phone costs
legibility for nothing.

### Sizes, bounded by measurement

The compound test was run against the real font files rather than estimated.
On a 360dp phone with 16dp gutters there are 328dp of line, and the widest
compound in the content is `Argon-Plasma-Koagulation`.

| Face | Widest compound at 22 | Largest size that still fits |
|---|---|---|
| Newsreader | 256px | **29** |
| Fira Sans | 268px | 26 |
| Fira Sans Bold | 276px | 26 |

Newsreader is the narrower of the two, which inverts the usual assumption about
serifs and is the practical argument for this pairing: **it buys three points of
question size.** The question runs at 26 with headroom rather than being pinned
at 22.

| Style | Face | Size / line | Weight | Use |
|---|---|---|---|---|
| Wordmark | Newsreader | 20 / 24 | 400 | App bar |
| Question | Newsreader | 26 / 32 | 400 | Detail screen |
| Quote | Newsreader | 17 / 26 | 400 | Guideline recommendation |
| Headline | Fira Sans | 17 / 22 | 600 | Verdict, card titles |
| Body | Fira Sans | 17 / 24 | 400 | Explanation, answers |
| Subhead | Fira Sans | 15 / 20 | 400 | Supporting |
| Footnote | Fira Sans | 13 / 18 | 400 | Attribution, citation |
| Caption | Fira Sans | 12 / 16 | 500 | Group headers, metadata |

**Newsreader is a variable font with an optical-size axis.** Set `opsz` to the
rendered size through `FontVariation`, or the 26 question is drawn with the
contrast of a 12 caption and looks thin and brittle.

Tracking tightens as size grows: -0.02em at the question, 0 at body. No text is
centred; ragged-right on long compounds is legible and centred compounds produce
visibly uneven rag.

### Bundle

Fira Sans at four weights (400/500/600/700) plus Newsreader as a single variable
file. Inter and Montserrat come out: three Inter weights are never called and
Montserrat is referenced only by its own generated constant.

Net change is **-0.07 MB**, so the second family is free. Bundled into `app_ui`
the way Inter is today, never fetched at runtime, because the app has no network.

Newsreader Italic is a separate 0.44 MB file. It would suit the quote, and it is
not worth that weight for one use unless the team asks.

## 6. Space and shape

Base unit 4. Horizontal gutter **16** - the fork's own `AppSpacing.lg`, kept so
the feed's rhythm is unchanged. Vertical: `8` within a group, `16` between
blocks, `32` between sections, `40` before a new idea.

Radii: `10` rows, `14` buttons and containers, `20` sheets. Touch targets never
below 44×44; answer rows are 56.

## 7. What each part of the post becomes

The fork's `PostLarge` anatomy is kept. Its content changes.

| Part | Was | Becomes |
|---|---|---|
| `PostHeader` | avatar, username, verified tick, options | Date and question type, as *25. August · Therapiestrategie*. No avatar: there is one publisher, and showing its face on every post is noise |
| `PostMedia` | media carousel + dots | Unchanged. The hook |
| `PostFooter` | like, comment, share, bookmark, counts | **Hidden.** No engagement in this product |
| `PostCaption` | author + caption | The question, truncated, as the tappable invitation to answer |

## 8. Structure

**Tageskarte, diffused.** Final.

Today's case fills the viewport and its lower edge dissolves into the ground over
150dp, so there is no card: there is an image that becomes the page. Bars float
over it as material with the image visible beneath, which is how navigation
survives a layout whose point is that content swallows the screen.

Nothing sits below the case. A vertical swipe moves one day, snapped, and stops
at today even when tomorrow is approved and waiting in the bundle. **The reader
chooses to go back; the scroll is never baited.** This is the one-case-a-day
brief enforced by the layout rather than by a rule.

**Three destinations**, in a bottom bar over the content: Heute, Archiv, Mehr.
Nothing is more than two steps from today.

**Answering happens on a pushed detail screen**, reached by tapping the card,
entering through a container transform from the image so the reader never loses
what they tapped. The card is the invitation; the detail is the work.

### Teaching the swipe without baiting it

A full-screen layout hides the fact that there is more, and the usual fix is a
bouncing arrow, which is the bait this product refuses. Three things instead:

1. **The peek.** 10dp of yesterday's card above the bottom bar, permanently and
   statically. Evidence, not invitation. It never pulses.
2. **One drift, once.** On first launch only, the card rises 12dp and settles
   back over 600ms. The gesture is shown physically one time, then never again.
3. **Archiv reaches everything without a gesture at all.** The swipe is a
   shortcut for adjacent days, never the only route to anything.

### Answered state

Stored locally through `hydrated_bloc`, already wired in the fork's bootstrap.
One fact per case: answered or not. **No score, no streak, no history, nothing
that leaves the device.** An answered card reads *Auflösung ansehen* and opens
straight to the revealed state.

### One tinted thing per screen

The tint marks the single next action and nothing else. On the card that is
*Fall öffnen*; on the detail, *Antwort bestätigen*; after the reveal, *Quelle*.

## 9. Motion

**Inherited, not invented.** The fork's scroll physics, page transitions and tap
response are the quality bar. Anything that feels slower than the fork did is a
regression.

Everything eases; nothing snaps. **No bounce anywhere**, an overshoot reads as
playful and nothing here is playful.

| Moment | Curve | Duration |
|---|---|---|
| Feed to detail | `OpenContainer` | 420ms |
| Reveal rise | `easeOutExpo`, 24dp | 420ms, 60ms stagger |
| Answer selection | `easeOut` | 160ms |
| Sheet present | spring, low stiffness | ~500ms settle |
| Bar material on scroll | against scroll offset | continuous |
| Press | scale 0.97 | 120ms |

**Haptics**, because much of what makes a native app feel expensive is felt:
`selectionClick` on answer select and sheet dismiss, `lightImpact` on confirm,
`mediumImpact` on pull-to-refresh.

**Nothing on the verdict.** A buzz of congratulation is gamification delivered
through the one channel that cannot be ignored.

Reduced motion collapses the reveal to a crossfade and the container transform
to a fade.

## 10. Content is provisional by design

Every string a physician might want to change lives in `assets/content/*.json`,
never in a widget. Teammates edit JSON and rerun the gate; nobody edits Dart to
fix a comma. The review UI in `pipeline/` is where approval happens.

## 11. What would make a polished result feel wrong

- Any celebration on a correct answer.
- A streak, score, XP, or progress ring.
- Colour anywhere near the endoscopic image.
- A quote rendered without its citation.
- Placeholder content that does not announce itself.
- Glass on something that is not floating over content.
- Grain or noise over a blur. That is what makes frost read as dirty.
- A cast shadow. Elevation here is blur radius and edge light.
- A hard edge where a material or the media ends.
- A neutral grey surface. Every depth carries the tint.
- An interface that feels slower or less smooth than the fork did.
