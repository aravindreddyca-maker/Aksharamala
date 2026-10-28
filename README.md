# Aksharamala

Aksharamala is a colourful, offline-first Flutter learning adventure for children ages 3–12. It offers a working vertical slice across **English Forest**, **Telugu Kingdom**, **Hindi Valley**, **Tamil Garden**, and **Number Galaxy**. The app is intentionally dependency-light: learning, progress and speech work without a network connection or account.

The main learning experience is landscape-first and locked to landscape on Android. Its illustrated adventure map uses five bundled ChatGPT-generated PNG scenes; lesson activities use responsive two-panel layouts on phones and tablets.

The Phase 1–2 landscape foundation also includes horizontal artwork-backed quest trails, responsive profile/reward/parent layouts, a shared game UI token set, large child-friendly controls, and system font fallbacks for Telugu, Devanagari and Tamil. See `AUDIT_PHASES_1_2.md` for the inspected surfaces, resolved defects and deliberately pending later phases.

## Run

Prerequisites: Flutter 3.47 or newer, Dart 3.13 or newer, JDK 17, and an Android SDK for device/APK builds.

```powershell
flutter pub get
flutter run
```

Verification:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

## Implemented vertical slice

- Animated splash and persistent multi-child profiles with avatar, name, age and star totals.
- Four age stages: 3–4 (listen/tap/count/recognise), 5–6 (trace/spell/add/subtract), 7–9 (read/write/grammar/arithmetic) and 10–12 (comprehension/writing/advanced maths). The home banner adapts its guidance to the active child.
- Five interactive world maps, each with four playable quests and completion state.
- Wide illustrated adventure-map home with local artwork, high-contrast overlays, scroll-safe cards and responsive phone/tablet sizing.
- Two-panel landscape lesson layout for quizzes, stories, maths and tracing, with independently scrollable panels and large touch targets.
- English, Telugu, Hindi and Tamil alphabet/word lessons; multilingual number names for 1–10; addition and subtraction.
- Native Android `TextToSpeech` pronunciation with `en-US`, `en-IN`, `te-IN`, `hi-IN` and `ta-IN` locales. Missing device voices fail gracefully.
- Finger tracing canvas with guide glyph, clear/retry and a minimum-stroke completion guard.
- Choice-based matching, spelling and maths interactions plus paged interactive stories.
- Stars, four achievements, celebratory feedback, progress meters and a rewards cabinet.
- A deterministic adaptive engine that selects unfinished work, rotates mastered material, and prioritises a world below 70% accuracy after repeated attempts.
- Grown-up arithmetic gate and parent dashboard with world progress, attempts, accuracy, stage focus, adaptive insight and privacy explanation.
- Versioned local JSON persistence. There is no login, ad SDK, analytics SDK, cloud service, or runtime network dependency.

Every visible action in the implemented slice has a handler: world and quest cards navigate; listen invokes native speech; answers submit; stories page; tracing clears/submits; profile selection switches learners; reward and parent controls open their screens.

## Architecture

```text
lib/
  main.dart
  src/
    app.dart                  app root and dependency scope
    app_controller.dart       profiles, progress, rewards, adaptation
    curriculum.dart           structured multilingual curriculum data
    models.dart               domain models and age staging
    services/
      local_store.dart        offline JSON snapshot repository
      speech_service.dart     Flutter/native speech channel
    screens/                  splash, profiles, home, maps, lessons, rewards, parents
    widgets/common.dart       shared visual primitives
android/.../MainActivity.kt   Android TextToSpeech implementation
test/                         model, persistence/adaptation, and widget-flow tests
```

The UI depends on `AppController`; the controller depends on the replaceable `LocalStore`. Tests inject a temporary file store. Curriculum is data-driven (`LearningWorld` → `Lesson`) so more letters, numbers, games, story pages and stage-specific variants can be added without altering navigation.

## Curriculum expansion path

This repository is a production-shaped vertical slice, not a complete multi-year content library. The next increments should add full alphabet sets and grapheme clusters, level-tagged lesson variants for each age stage, richer drag-and-drop matching and free-form spelling, trace-shape scoring, more operations/fractions/geometry, narrated story packs, content authoring/import tools, accessibility and child usability studies, and encrypted backup/optional parent-controlled sync.

Before a store release, also add original reviewed audio assets as a fallback for missing TTS voices, replace the simple parent arithmetic gate with a configurable parent control, consider an embedded database once the curriculum grows beyond the current versioned app-files JSON snapshot, create signed release configuration and branded launcher artwork, and perform native-device QA across screen sizes and all target scripts.

## Tests

- `models_test.dart`: stage boundaries, five-world coverage and four-language number names.
- `controller_test.dart`: profile/progress persistence, rewards and adaptive next-lesson behavior.
- `app_widget_test.dart`: age-adaptive home, functional launch controls for all five worlds, a world map, and a playable lesson surface.
- `overflow_test.dart`: every implemented screen and lesson at 640x360, 800x360, 960x540 and 1280x800 with normal and enlarged text.
- `tool/verify_product.mjs`: dependency-independent source audit used when reviewing the vertical slice.
- `tool/verify_phase12.mjs`: landscape, artwork, compatibility, script fallback and audit-boundary checks.

## Privacy

Aksharamala stores only child-entered profile details and learning progress in a local JSON snapshot. The app declares no production internet permission. Android debug/profile manifests retain Flutter's development-only internet permission for tooling.

