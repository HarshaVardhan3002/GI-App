# Phase 2, as built

What the plan asked for, plus four things it did not know about. Verified on
`pixel8_api36` in dark mode.

## Planned, and done

| Target | Where | Result |
|---|---|---|
| Action row and counts | `post_footer.dart` | Gone. The seven callbacks stay on the constructor, so `PostLargeView` and every other call site are untouched |
| Stories carousel | `feed_page.dart` | Gone, with its divider |
| Chat entry | `feed_app_bar.dart` | Gone |
| Camera and chat by swipe | `home_page.dart` | Physics pinned. Swiping left or right from the feed now does nothing |
| Five tabs to three | `bottom_nav_bar.dart` | Heute, Archiv, Mehr, mapped to branches 0, 1 and 4. The five branches are untouched |

## Four things the plan did not know about

### 1. Upstream's demo posts were in our feed

Scroll past the real cases and the app appended
`PostsRepository.recommendedPosts`: six hardcoded posts by `emil.zulufov`,
captioned `Hello world3` through `Hello world8`, with stock photography loaded
from freepik. `feed_bloc.dart:63` requested them the moment the real feed ran
out, and `feed_page.dart` had a loader that asked for more.

**Another product's demo content, under our wordmark, two swipes from the top.**
Nobody had scrolled to the end. Both sites are commented out; the event, the
handler and the list stay.

### 2. The feed closed with social-feed furniture

A green tick reading *"You're all caught up"* and a *"Suggested for you"* header,
appended by `_computeSponsoredBlocks` whenever `hasMore` is false. The first
congratulates a reader for reaching the end of three cases. The second
introduces a section that is now empty, because the posts it held are the ones
removed above. Both gone.

### 3. Removing the furniture ate a case

`_buildBlock` had a branch that fired on **the last index whatever the block
was**. Upstream got away with it because the last block was always that
furniture, never a post. With the furniture gone the last block is a real case,
and the branch swallowed it: the feed showed two of the three approved cases and
would not scroll past them.

**This is the shape of bug that only appears at the end of a list**, and it was
found by walking the feed to its end rather than by reading the diff. The branch
is commented out. There was nothing to fetch anyway: `feedPageLimit` is 7 and
the content set is smaller, so the first page is always the only page.

### 4. The tab bar had no selected state

Upstream left `selectedItemColor` and `unselectedItemColor` at the same value.
Invisible with five labelled tabs, obvious with three unlabelled ones. Set
explicitly; Phase 3 replaces both with ramp tokens.

## Three cases, not four, and that is correct

`posts.json` holds four. The one dated today is `draft`, and
`local_content_source.dart:75` drops anything not `approved` before it reaches
the feed. **The app is refusing to render unreviewed content, which is
constraint 3 working.** It is written down here because from the outside it
looks like a missing post.

## Also in this branch

The em-dashes are out of the four Dart files this project wrote, per
`CLAUDE.md` §8. One paired-dash clause broke in the substitution and was
repaired by hand: `every existing screen — the feed, the post layout, the
navigation shell — keeps working` had become `... shell: keeps working`. A
paired dash is not the same construction as a single one, and the automatic
replacement cannot tell them apart.

## Left for later, deliberately

Archiv and Mehr are still the fork's timeline and profile screens, showing
broken-image icons and a spinner against the empty local client. Phase 6 and
Phase 7 replace them. Nothing in this phase pretends otherwise.
