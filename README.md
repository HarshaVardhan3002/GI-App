# GI-App

Ein endoskopisches Bild pro Tag, eine Frage auf Facharztniveau, und eine
Auflösung, die auf eine nummerierte Leitlinienempfehlung zurückführt.

**The image is the hook. The guideline recommendation is the payoff.**

Built for the DGVS Hackathon 2026 - Viszeralmedizin, Hamburg, 17-18 September.
Team of three developers and two physicians. The deliverable is a working
prototype demoed to a jury in about ten minutes, not a shipped product.

---

## Status

This is the working base, not the product.

The forked Instagram app runs end to end on this machine with **no backend at
all** - no Supabase, no PowerSync, no Firebase, no `.env`, no
`google-services.json`. Every existing screen works against a content set
bundled with the app.

What has **not** happened yet: the Instagram identity is still on screen, the
social features are still rendered, and the content is placeholder. That is the
next phase, and it is planned before it is built. See
[`CLAUDE.md`](CLAUDE.md) for how that work is expected to proceed.

```sh
cd app
flutter pub get
flutter run -t lib/main_local.dart --flavor development
```

## Layout

```
app/ the forked Flutter app
 lib/main_local.dart entrypoint: no Firebase, no PowerSync
 lib/bootstrap_local.dart
 packages/local_content_client/
 local DatabaseClient, AuthenticationClient and
 Firebase stand-ins - the seam the whole app hangs on
 assets/content/ the four JSON files that are the database
 assets/images/ 4:5 WebP, one per image in the bank

pipeline/ content tooling, TypeScript and Python
 src/lib/schema.ts the contract; single source of truth for shape
 src/validate-content.ts the gate
 src/generate-posts.ts image + recommendation -> draft post
 src/review-server.ts physician approve/reject UI
 scripts/build_image_bank.py dataset -> WebP + images.json
 scripts/extract_recommendations.py
 AWMF guideline PDF -> recommendations
```

## How the app runs without a backend

`DatabaseClient` is an abstract class and `PowerSyncDatabaseClient` is only one
implementation of it. `LocalDatabaseClient` is another, reading the bundled
JSON. The same trick covers authentication and the two Firebase-backed
repositories. Nothing above the data layer knows the difference, which is why
every screen kept working.

That seam is also where a real backend goes later: implement the same
interfaces, change one line in `main_local.dart`, change nothing else.

## The four constraints

1. **No patient data.** Images come only from open, de-identified CC BY 4.0
 datasets. Attribution renders on screen.
2. **Guideline text is cited, never redistributed.** At most 400 characters per
 quote, always with its citation. Copyright is the AWMF author collective's,
 and shipping needs a separate rights agreement.
3. **Nothing unreviewed reaches a user.** Content is `draft` until a physician
 approves it. Only `approved` renders.
4. **German UI, German content, Fachsprache.** No mascots, no confetti, no
 gamification.

## Content pipeline

```sh
cd pipeline
npm install
npm run validate # the gate - run before every build
npm run review # physician approve/reject, http://localhost:4173
```

Content is data, not code. Swapping in real content means replacing JSON files,
never editing a component.

## Licensing

A derivative work of an MIT-licensed project with an additional clause on
replication, plus dataset and guideline obligations. Read
[`ATTRIBUTION.md`](ATTRIBUTION.md) before publishing or demoing this anywhere.
