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
| `surfaceRaised` | `#F5F5F7` | `#1C1C1E` | Cards, grouped containers, sheets |
| `surfacePressed` | `#EBEBEF` | `#2C2C2E` | Selected and pressed rows |
| `separator` | `#DCDCE0` | `#38383A` | Hairlines |
| `label` | `#000000` | `#FFFFFF` | Primary text |
| `labelSecondary` | `#5C5C61` | `rgba(235,235,245,.60)` | Supporting text |
| `labelTertiary` | `#8E8E93` | `rgba(235,235,245,.30)` | Metadata, timestamps |
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

**Inter**, already bundled in `app_ui`. Apple's text-style metrics, because they
are tuned for exactly this reading distance.

| Style | Size / line | Weight | Use |
|---|---|---|---|
| Large title | 34 / 41 | 700 | Screen titles |
| Title | 22 / 28 | 700 | The question |
| Headline | 17 / 22 | 600 | Card titles, verdict |
| Body | 17 / 24 | 400 | Explanation, answers |
| Callout | 16 / 21 | 400 | Quoted guideline text |
| Subhead | 15 / 20 | 400 | Supporting |
| Footnote | 13 / 18 | 400 | Attribution, citation |
| Caption | 12 / 16 | 500 | Group headers, metadata |

Tracking tightens as size grows: −0.4 at large title, −0.2 at title, 0 at body.
Group headers are the only uppercase in the app.

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
