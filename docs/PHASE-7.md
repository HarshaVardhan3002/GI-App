# Phase 7 - Mehr, and where the content came from

Branch `phase-7-mehr`, off `phase-6-archiv`.

This phase builds the last three screens the design artifact promised: **Mehr**,
**Erscheinungsbild** and **Inhaltsstatus**. It also builds the four sub-pages
those screens link to, which the artifact names but does not draw:
Bildquellen, Leitlinien und Rechte, Über GI Daily, Impressum.

With this branch, **all nine screens in the artifact exist and run**.

---

## What was built

### The seam first

Two additions to `CaseSource`, both of them things a widget should be able to
ask rather than compute.

`GiContentStatus`, in `packages/database_client/lib/src/case_source.dart`:

```dart
abstract interface class GiContentStatus {
  int get approvedCount;
  int get draftCount;
  int get rejectedCount;
  int get imageCount;
  int get placeholderImageCount;
  int get recommendationCount;
  int get placeholderRecommendationCount;
}
```

Implemented as `_LocalContentStatus` in `local_content_source.dart`. **The
counts run over the whole post set, before the `status != 'approved'` filter.**
A status screen that counted only what it could already see would be counting
nothing, and would report zero drafts forever.

`bool get isPlaceholder` on `GiGuideline`, implemented as
`title.startsWith('PLATZHALTER')` - the same marker the recommendation quotes
already carry, so there is one convention rather than two.

### The screens

| File | What it is |
|---|---|
| `lib/mehr/widgets/mehr_scaffold.dart` | `MehrScaffold`, the shape every screen under Mehr has, and `MehrNote`, the sentence under a group |
| `lib/mehr/view/mehr_page.dart` | The root: three groups, no tinted row |
| `lib/mehr/view/erscheinungsbild_page.dart` | `ErscheinungsbildPage` and `SprachePage` |
| `lib/mehr/view/inhaltsstatus_page.dart` | Freigabe counts, Platzhalter counts |
| `lib/mehr/view/herkunft_pages.dart` | `BildquellenPage`, `LeitlinienPage`, `UeberPage`, `ImpressumPage` |

`MehrScaffold` exists because a settings tree is exactly where small
inconsistencies accumulate. A new sub-page needs no new layout decision. Same
reason `GiGroup` exists.

### Routing

Seven entries added to `AppRoutes`, and seven `GoRoute`s hung under branch 4
so they push **onto the Mehr tab** rather than the root navigator: the tab bar
stays put and the back label always names where it came from. One transition
helper, `_mehrPage`, for the whole tree - a settings tree that animated three
different ways would read as three different apps.

Branch 4's own route swapped from the fork's `UserProfilePage` to `MehrPage`,
**commented out, not deleted** (CLAUDE.md §3). There is no account in this
product, so there is no profile; a tab called Profil would promise a person and
deliver settings.

### Heute empty state

`HeuteEmpty` gained the wordmark bar the Leerzustand mockup shows. An empty
screen with the chrome stripped off reads as a screen that failed to load
rather than a screen with nothing in it.

---

## Defects found by running it, and fixed

Four of these were found on the emulator, not by the analyzer. None of them
would have failed a build.

1. **`PLACEHOLDER` printed as a dataset name.** Bildquellen rendered the
   schema sentinel as a group header, and `Lizenz: PLACEHOLDER` as a row, in a
   German screen. Now a placeholder image gets `PLATZHALTER` as its header and
   no licence row at all - a placeholder has no licence, and a row whose value
   is a sentinel is noise.
2. **`000-000` printed as an AWMF register number.** Same fix on Leitlinien,
   using the new `GiGuideline.isPlaceholder`.
3. **A dead link offered as a live one.** *Leitlinie öffnen* rendered on a
   placeholder guideline whose URL resolves to nothing. The row and its
   "opens in the browser" note are now hidden for placeholders. A link that
   goes nowhere is worse than no link.
4. **An unclear referent on Über GI Daily.** The pending notice read *"Dieser
   Text ist noch nicht geschrieben"* directly under a paragraph that plainly
   was written, so it read as contradicting the text above it. Rewritten to
   *"Dieser Text ist ein Entwurf. Die endgültige Fassung wird von den
   Projektbeteiligten verfasst und ärztlich geprüft, bevor die Anwendung
   veröffentlicht wird."* CLAUDE.md §8: an unclear referent gets rewritten.
5. **A meaningless `trailing: Text('')`** on the approved row in
   Inhaltsstatus, caught before it ran.

---

## Left undone, and named as undone

**The Impressum has no text.** A German product published to an app store is
legally required to carry one, and its contents are a company name, an address
and a responsible person. Those facts are not on this machine and cannot be
invented honestly (CLAUDE.md §10). The screen exists, it is reachable from
Mehr, and it says exactly what is missing, in `warning`.

**`Über GI Daily` carries one paragraph and a draft notice.** The paragraph is
true of the app today. Everything a real About page would carry - who builds
it, the medical disclaimer, the data position - is content for physicians and
teammates to write.

---

## Verified

Built `flutter build apk --debug --flavor development -t lib/main_local.dart`,
installed on `emulator-5554` (1080x2400), and walked by hand. `flutter analyze`
over `lib`, `packages/database_client` and `packages/local_content_client`:
no issues.

Screens walked and screenshotted, in dark:

- Mehr (root, all three groups, version row)
- Erscheinungsbild, and the selection actually changing the app
- Sprache
- Bildquellen (before and after the placeholder fix)
- Leitlinien und Rechte (before and after)
- Inhaltsstatus (3 freigegeben in `correct`, 1 Entwurf, 0 Abgelehnt, 5 von 5
  and 3 von 3 in `warning`)
- Über GI Daily
- Impressum
- Back out of every one of them

**The light appearance was verified visually for the first time in this
project.** Erscheinungsbild -> Hell, then Heute, then back to Dunkel. The
appearance choice persists across the change and the Mehr row reflects it.

### What light exposed, and did not get fixed here

On Heute in light, the placeholder image region and the card body below it are
near-identical whites: the ramp separates them in dark and barely does in
light, so the image area has no edge. This is a light-ramp weakness, not a
Phase 7 regression, and it belongs to the material phase. **Naming it here
rather than leaving it for someone to find.**

### Not verified

- iOS. There is no iOS Simulator on this machine (CLAUDE.md, Environment).
  Nothing about gesture feel or bar posture on iOS is claimed.
- The external-link path. `openExternal` is wired to `url_launcher` and is only
  reachable from a non-placeholder source, of which this content set has none.
  It has therefore never been tapped.

---

## Notes for later

- `placeholderImageLabelText` is now used for a guideline header too. The key
  name is image-specific and the string is just the word *PLATZHALTER*. Worth
  renaming when the content phase touches the strings.
- `MehrPage.version` is a constant. It should be read from the bundle.
- Two tinted things appear on some Mehr sub-pages: the back label, and (on
  pages that have one) the external-link row. The back control is navigation
  chrome and is tinted throughout the tree by iOS convention; DESIGN.md §8's
  one-tinted-thing rule is about the screen's action, and these pages have at
  most one of those.
