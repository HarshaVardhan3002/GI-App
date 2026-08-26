# Phase 3, as built

Nothing new on screen, which was the point. This is the vocabulary the rest of
the build spends.

## What landed

**Fira Sans**, three static cuts (400, 500, 600), SIL OFL, beside Newsreader.
Static rather than variable because only three weights are in the scale and
three static faces are smaller than one variable file.

**The ramp**, `GiRamp.of(depth, brightness:)`, interpolating the seven measured
stops. A component asks for a depth between 0 and 1, not a named colour, so no
two surfaces can produce a visible step where they meet. The stops sit at 0,
.15, .30, .45, .60, .80 and 1: uneven on purpose, because the ramp moves fastest
near the ground where a step would show most.

**`GiColors`**, one appearance of the palette, reached through `context.gi`. It
resolves from the theme's brightness rather than living in an inherited widget,
so it cannot drift out of step with the theme and costs nothing to read.

**`GiText`**, the eight roles and no ninth. `opsz` is pinned to the rendered size
everywhere Newsreader appears.

**German.** `app_de.arb`, `LocaleBloc` defaults to `de_DE`, and `timeago` gets
its German messages registered.

**`GiHaptics`**, three haptics for the whole app, each taking a `BuildContext` so
it can honour reduced motion. Correct and incorrect feel the same, deliberately:
at Facharzt level a right answer is the expected outcome, and a different buzz
for wrong would be the app having an opinion about the reader.

## Two decisions worth recording

**The base face was swapped, not just added.** `UITextStyle` and
`ContentTextStyle` now set Fira Sans instead of Inter. Sizes and weights are left
exactly as upstream had them, so this is a face swap and not a retype: the eight
roles that matter live in `GiText`, and the fork's scales only need to stop being
Inter. Without this the type scale would have existed and nothing would have
spent it.

**Only fourteen strings are German.** The rest fall back to English and are
listed in `lib/l10n/untranslated_messages.json`. Most belong to features that are
commented out or to screens Phases 6 and 7 replace, and **an unreviewed German
string in a medical product is worse than an English one nobody sees.** Phase 11
does the full pass with `humanizer`.

The three tab labels got their own keys rather than borrowing Instagram's.
Calling Archiv `searchNavBarItemLabel` would have been a lie in the source even
with nothing drawn.

## Two things found on the way

**Sheets sat on a warm neutral grey.** `AppColors.background` is
`ARGB(255, 32, 30, 30)`, and `DESIGN.md` §3 says no surface in this app is
neutral grey. Both themes now put sheets at depth 0.15.

**`timeago` would have printed English dates and warned about it into a log
nobody reads.** German is registered now. The package's own phrasing gives
`vor ~1 Tag`; the tilde is its abbreviation for *about*, and whether that is
acceptable German for this product is a Phase 11 question, not a Phase 3 one.

## Verified

Built, installed on `pixel8_api36` after `pm clear`, dark mode. The ground is
black, the tab bar distinguishes the selected tab, the date reads `vor ~1 Tag`,
and the body face is Fira Sans while the wordmark stays Newsreader.

`pm clear` matters here: `LocaleBloc` is a `HydratedBloc`, so an install that
already stored `en` keeps it. On an existing device the language changes on
reinstall, not on update.
