# Branding

Name, analogy, palette candidates and wordmark for GI Daily.

Palette is **decided: Gletscherspalte**. Typeface selection is open. The comparison board
with live swatches is at
<https://claude.ai/code/artifact/741addc8-8f7b-4baa-8d6f-3a001a5bb29b>.

---

## 1. The analogy

**The app is a light box, not a feed.**

A light box holds a neutral, known light behind the thing being read and adds
nothing to it. A viewing surface that tints what sits on it makes the reading
wrong.

That single image decides the colour strategy more firmly than any taste
argument could:

- the chrome recedes rather than competes,
- the accent is a seam, not a field,
- the only saturation on screen belongs to the mucosa,
- and "anonymous" is a compliment, not a failure.

It also decides what the product is *not*. A feed is somewhere you stay. A light
box is somewhere you look at one thing and then leave, which is what one case a
day means.

## 2. The restriction that eliminates most palettes

Endoscopic mucosa has a mean hue of **4 degrees** and runs roughly **340 to 30
degrees**: red, pink, coral, salmon, wet flesh.

Anything drawing surfaces or accent from that arc reads as tissue and competes
with the finding. That removes the whole warm-nature family at a stroke: autumn,
terracotta, clay, rust, sandstone, coral reef. It is also, not coincidentally,
the palette family that generative tools reach for by default on anything
described as premium or artisan.

A second exclusion comes from the product: **green and red carry the verdict**,
so an accent in either collides with meaning that must stay unambiguous.

What survives is cold, mineral, achromatic nature.

## 3. The five candidates

All five pass WCAG AA for text and accent in both appearances. Ratios are
computed, not estimated. Hue separation is measured against a mucosal sample set
of `#C1524E`, `#D97B72`, `#A8342F`, `#E39B92`.

| Palette | Natural instance | Tint (dark) | Hue | vs mucosa | vs verdict-green |
|---|---|---|---|---|---|
| **Gletscherspalte** | Light down a glacier crevasse | `#3FA9F5` | 205 | 157 | 70 |
| **Basalt nach Regen** | Volcanic rock while still wet | `#6FA8C7` | 201 | 161 | 66 |
| **Birke im Winter** | Bark, charcoal scars, snow shadow | `#7FB2CC` | 200 | 162 | 65 |
| **Moorlandgewitter** | Wet heather as the light drops | `#9A96E0` | 243 | 119 | 108 |
| **Tiefsee** | Water below the light | `#35C6D4` | 185 | 177 | 50 |

### Chosen: Gletscherspalte

Ice reads blue because water absorbs the red end of the spectrum before the
light returns. The medium removes red, which is exactly what this interface is
asked to do. The analogy is not decorative; it is the mechanism.

It is recommended **because it is the least interesting one.** In a product whose
whole job is to get out of the way of an image, anonymity is the correct
ambition, and the identity should be carried by typography, spacing and
restraint. Its cost is real and worth stating: every second medical product in
the room is this colour.

### The two live alternatives

- **Moorlandgewitter** if the app should be recognisable across a congress hall.
  Widest separation on every axis. Its risk is that violet currently reads as
  consumer AI software, and a Facharzt audience may hear that.
- **Basalt** if it should disappear further than Gletscher does. Near-monochrome
  puts the entire identity on the typography, which is expensive restraint done
  well and unfinished work done badly.

### Ruled out: Tiefsee

Visually the strongest of the five, and the one to leave. 185 degrees is
narrow-band imaging territory: NBI renders mucosa in this exact blue-green, so
the tint can read as part of the image rather than as a control. It also sits
only 50 degrees from the green that means *richtig*. Both objections are
clinical rather than aesthetic.

## 4. Fixed regardless of palette

Semantic colours do not change between palettes, and no palette may borrow these
hues for its accent. Their scarcity is what makes them readable.

| Role | Value | Appears |
|---|---|---|
| Richtig | `#30D158` | Verdict only |
| Nicht richtig | `#FF453A` | Verdict only |
| Platzhalter | `#FF9F0A` | Placeholder marking only |

## 5. Typeface

Six candidates, each rendering the same real German screen on Gletscherspalte:
<https://claude.ai/code/artifact/a06fbbed-3fe0-4496-aa4d-5c16e5d49bcd>

The test is not how a face looks in a headline. It is whether
`Zylinderepithelmetaplasie` fits on a 360dp phone, which leaves 328dp of line.
German does not break compounds and Flutter does not hyphenate, so the word fits
or it hangs off the screen.

Recommendation: **Fira Sans**, narrower than the alternatives, drawn for small
screens by someone solving for German, and it ships a matching mono for AWMF
register numbers. IBM Plex Sans is the close second. Inter is free and not wrong,
only anonymous.

## 6. Wordmark

**GI Daily**, 700 weight, tracking -0.02em, sentence case. Not all-caps,
and not a logotype pretending to be a signature.

It replaces `AppLogo` at the optical weight the Instagram wordmark held, so the
app bar's rhythm survives the swap. Four call sites pick it up unchanged.

**No icon-and-name lockup.** At 20pt in a header, a mark and a word compete and
the word wins. The app icon is a separate problem and is not solved by shrinking
the wordmark into a square.

## 7. Voice

German, Fachsprache, plain. The reader is a specialist between cases, not a
learner being encouraged.

- Labels name the thing. No performative headings.
- No praise on a correct answer. It was expected.
- Uncertainty is stated, never smoothed over. If content is a placeholder, it
  says so on screen.
- English exists only as a developer debug locale.

## 8. Open

- **Typeface.** Blocks Phase 1 together with the wordmark.
- **App icon.** Not designed. A wordmark does not shrink into an icon, and the
  obvious move, a stylised lumen or scope circle, risks reading as a generic
  medical roundel. Worth a separate pass.
- **Whether the wordmark should be German.** *GI Daily* is English in a German
  product. Defensible as a name rather than a phrase, but the physicians on the
  team should get a say before it is on screen at a DGVS congress.
