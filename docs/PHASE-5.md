# Phase 5, as built

Fall, in both its states, and the Herkunft sheet. Three of the nine screens in
the design artifact. The fork's post preview is gone from the route; it is one
commented line from coming back.

## Two states, one route

`FallPage` reads `CaseSource.caseOf(id)` and renders either the question or the
reveal. They are one screen because they are one act. **You do not navigate
away from a question to be told whether you were right**, and the reveal
*replaces* the answers rather than appearing below them, so the reader is never
looking at a verdict and a choice at the same time.

The reveal has no image. The reader has already seen it twice, on the card and
above the question; what is on trial at that point is the recommendation, and
an image at the top would be the screen still asking something it has settled.

## Where the answer lives

In `_FallViewState`, and nowhere else. Answers are **not persisted**. Archiv
marks a case as answered, and that needs a store the backend seam does not have
yet. When it does, this state moves behind `CaseSource` and the widget stops
holding it. Nothing above it has to change.

This is named here rather than left to be discovered: today, backing out of a
case and opening it again forgets the answer.

## The image is 40%, not 1.25

Heute gives the image its full aspect because that screen is for looking. This
one is for reading: the reader has already seen the image at its largest, and
here it is context for a question that has to fit. The dissolve shortens with
it, 96 rather than 150.

## What is in a group belongs together

`GiGroup`, `GiGroupHeader` and `GiRow` are new in `app_ui`, and every list in
the app is built from them: the answers, the recommendation, the provenance
sheet, and the settings list that Phase 7 will need.

The quote, the Konsensstärke, the citation and *Quelle* are rows of **one**
group. Constraint 2 says guideline text is cited and never redistributed, and
putting the citation in the same group as the quote is how a later layout
change is stopped from separating them. It is a structural guarantee rather
than a thing to remember.

Group headers are Fira Sans in caps. The screen mockups set them in Fira Mono,
and `DESIGN.md` section 5 permits exactly three uses of a second face - the
wordmark, the question and the guideline quote - none of which is a group
header. Caps and letter-spacing do the same job without a fourth font in the
bundle. **This is a deliberate departure from the mockup and is flagged rather
than buried.**

## The button is quiet before it is tinted

*Antwort bestätigen* sits at depth 0.30 with tertiary text until an answer is
chosen. A tinted button that does nothing when pressed teaches a reader to
distrust tint, and tint is the only signal this app has for what to do next.

## Herkunft is the constraints made inspectable

Dick material, grabber, drag to dismiss. When any part of the case is a
stand-in, the warning is the **first** thing on the sheet, before the credits
it would otherwise appear to lend weight to.

Then the image's dataset, class, licence and rights holder; the guideline's
AWMF number, the recommendation number, and the guideline's own rights note
quoted in full rather than summarised; and who approved the content. Each of
those is one of the product's standing constraints, and a constraint nobody can
check is worth nothing.

The row that leaves the app says so before it does.

## Two defects the compiler could not have found

Both were found by walking the build, and both crashed the reveal.

**`LocalCase.options` handed out the wrong runtime type.**
`.map(_LocalOption.new).toList()` infers `List<_LocalOption>`, and the declared
`List<GiOption>` return type accepts it by covariance while the runtime list
stays the private one. `firstWhere`'s `orElse` reads its signature off that
runtime type, so the reveal threw:

```
type '() => GiOption' is not a subtype of type '(() => _LocalOption)?' of 'orElse'
```

The seam now maps to the interface type. **A seam has to hand out the interface,
not a list that merely satisfies it.** The reveal also stopped using
`firstWhere(orElse:)`, which is a trap for any list crossing an interface.

**`levelOfEvidence` is optional and was read as required.**
`GiRecommendation` documents it as "where the guideline gives one", and an
Expertenkonsens gives none. `platzhalter-r-6.12` - today's case - omits it, and
the hard cast threw `type 'Null' is not a subtype of type 'String'`. It reads
as empty now, and the screen draws no row for it.

Every other field on that reader stays a hard cast on purpose. A recommendation
with no quote or no citation is a constraint-2 violation, and failing loudly is
the point.

## Three corrections to Heute

Found by reading the mockup's own stylesheet rather than remembering it:

- the active carousel dot is the **tint**, not the label colour, and the
  inactive ones are white at 30%
- the peek is depth **0.45**, not 0.30
- the Herkunft sheet drew two grabbers, because the theme turns Material's own
  on for every sheet and this one draws its own inside the material

## Verified

On `emulator-5554`, by walking it: card, case, selection, confirm, reveal,
Herkunft. Both crashes above were caught this way and are fixed in this branch.

**Not verified:** the light appearance, and anything about iOS feel. There is
no iOS Simulator on this machine.

## What is still the fork's

Archiv and Mehr. Phases 6 and 7.
