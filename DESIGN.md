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

Set in Inter, weight 700, tracking −0.02em, sentence case - *GI Daily*, never
all-caps and never a logotype pretending to be a signature script. It replaces
`AppLogo` at the same size and optical weight the Instagram wordmark had, so the
app bar's rhythm survives the swap.

No icon-plus-name lockup. The name alone, because at 20pt in a header a mark and
a word compete and the word wins.

## 3. Appearance - both, and both real

The fork ships `AppTheme` (light) and `AppDarkTheme` (true black). Both stay, and
both are decided rather than inherited.

Tokens are named for **role**, never hue, so a screen is written once and reads
correctly in both. Any widget that hardcodes a hex value is a defect.

| Token | Light | Dark | Role |
|---|---|---|---|
| `surface` | `#FFFFFF` | `#000000` | Page ground. Dark is true black - the image floats and OLED disappears |
| `surfaceRaised` | `#F1F5F9` | `#101A22` | Cards, grouped containers, sheets |
| `surfacePressed` | `#E4EBF2` | `#18242E` | Selected and pressed rows |
| `separator` | `#D5DDE6` | `#26333D` | Hairlines |
| `label` | `#0B1620` | `#FFFFFF` | Primary text |
| `labelSecondary` | `#485A69` | `#9BAAB6` | Supporting text |
| `labelTertiary` | `#7A8B99` | `#6B7A86` | Metadata, timestamps |
| `tint` | `#0A6FD8` | `#0A84FF` | **Every** interactive element |
| `correct` | `#2E7D4F` | `#30D158` | Verdict only |
| `incorrect` | `#C0392B` | `#FF453A` | Verdict only |
| `warning` | `#B26A00` | `#FF9F0A` | Placeholder marking only |

Light values are darkened from their dark counterparts to hold 4.5:1 on white.
The same token, contrast-correct in both, not the same hex twice.

**Green and red never appear on anything that is not a verdict.** No green
buttons, no red borders, no coloured badges. Their scarcity is what makes them
readable.

## 4. Glass - as a material, not a decoration

Translucency is used where the chassis already earns it: **bars over moving
content**. The app bar sits over a scrolling feed, and the reveal sheet sits over
the case. In both, the blur communicates depth and keeps text legible over
whatever scrolls beneath.

Rendered with `liquid_glass_renderer` (shader-based refraction), falling back to
`BackdropFilter` if the shader misbehaves on a device.

**Where glass is allowed:** the feed app bar, the bottom navigation bar, the
reveal sheet, the source sheet.

**Where it is banned:** cards, list rows, buttons, badges, empty states, and
anything that is not floating above something else. Frosted panels sitting on a
flat background are the single most common way glass reads as decoration, and it
is not used that way here.

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

**Three tabs.** Feed, Archive, Profile.

- **Feed** - today's case, and earlier cases below it. The scroll is the product.
- **Archive** - the grid the fork uses for search results, reused as earlier
 cases. Proves the content set has depth.
- **Profile** - not a social profile. Settings, language, and the licence,
 attribution and rights screens that constraints 1 and 2 oblige us to show.

**Answering happens on a pushed detail screen.** Tapping a post opens it: image,
question, four answers, reveal, guideline. The feed stays a feed; the payoff gets
room. The fork already has a post route, so this is the existing navigation, not
a new one.

## 9. Motion

**Inherited, not invented.** The fork's scroll physics, page transitions, image
loading and tap response are the quality bar. Nothing replaces them.

One authored moment is added: **the reveal**. Verdict first, then reasoning, then
the recommendation, rising 24 with an exponential ease-out over ~420ms. Nothing
bounces. Reduce Motion crossfades.

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
- An interface that feels slower or less smooth than the fork did.
