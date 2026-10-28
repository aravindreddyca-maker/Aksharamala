# Aksharamala Phase 1–2 Audit

Scope: audit and upgrade the existing Flutter app in place. Existing curriculum, routes, profile JSON, lesson identifiers, progress schema, native TTS bridge, five worlds, Tamil content, and navigation are preserved. Phase 3–9 work is intentionally pending until this landscape foundation is accepted.

## Phase 1 — Audit and defect remediation

### Architecture inspected

- `AppScope`/`AppController` state flow, curriculum models, all seven screen modules, shared widgets and theme.
- Versioned local JSON repository and Android application-files channel.
- Android activity orientation, native TTS lifecycle/locales, Gradle configuration and offline dependency set.
- Bundled world artwork, asset registration, navigation handlers and the complete widget/model/controller test suite.

### Prioritized findings

| Priority | Finding | Resolution |
|---|---|---|
| P0 | Remaining emoji glyphs acted as final artwork on profiles, maps, rewards, stories, splash and dashboard. Rendering varied by Android device. | Replaced presentation glyphs with a consistent Material illustration language. Legacy stored emoji avatar values map to icons so existing profiles remain readable. |
| P0 | World map was a portrait-style vertical list and did not use landscape space. | Rebuilt as an illustrated horizontal quest trail over each bundled world scene. |
| P1 | Profile, rewards and parent screens were narrow stacked layouts with weak landscape hierarchy. | Added responsive wide compositions, adaptive grids and bounded scrolling. |
| P1 | Font fallback and touch-size rules were scattered. | Added shared design tokens, Telugu/Devanagari/Tamil fallbacks and 52dp minimum controls. |
| P1 | Previous overflow coverage did not use the exact required landscape matrix across every screen. | Matrix now covers 640x360, 800x360, 960x540 and 1280x800 at 1.0x and 1.3x text scaling. |
| P2 | `allowSkip` on returning profile selection was unused. | Added a functional Continue action that retains the active child. |
| P2 | Existing analyzer info findings prevented a genuinely clean analysis result. | Added required control-flow braces. |

### Phase 1 modified files

- `lib/src/theme.dart`, `lib/src/widgets/common.dart`
- `lib/src/curriculum.dart`, `lib/src/screens/lesson_screen.dart`, `lib/src/screens/splash_screen.dart`
- `lib/src/services/local_store.dart`
- `test/overflow_test.dart`, `test/card_paint_test.dart`, `test/contrast_test.dart`
- `tool/verify_phase12.mjs`, `GATES.md`, this audit

## Phase 2 — Premium landscape experience

### Implemented

- Home retains the five illustrated world cards, adaptive banner, profile, rewards and parent navigation.
- Each world now opens a wide, artwork-backed adventure trail with large sequential quest cards, completion state and recommended quest.
- Lesson screens retain their responsive two-panel layout, tracing, stories, quizzes, audio and progress recording; emoji story placeholders and completion glyphs are replaced with consistent icons.
- Profile selection uses a landscape split layout and remains scroll-safe on short phones. Saved legacy avatars remain compatible.
- Rewards use a responsive badge cabinet; parent progress uses wide metric cards, artwork thumbnails, adaptive insight and privacy panels.
- Shared text styles include system fallbacks for English, Telugu, Hindi and Tamil scripts.

### Phase 2 modified files

- `lib/src/screens/home_screen.dart`
- `lib/src/screens/world_map_screen.dart`
- `lib/src/screens/profile_screen.dart`
- `lib/src/screens/achievements_screen.dart`
- `lib/src/screens/parent_dashboard.dart`
- `lib/src/screens/lesson_screen.dart`, `lib/src/screens/splash_screen.dart`

## Checklist

- Completed: audit of Flutter, Android, storage, TTS, assets, navigation and tests.
- Completed: landscape-first presentation across all implemented screens.
- Completed: no emoji used as final screen artwork; legacy data remains compatible.
- Completed: exact landscape viewport and text-scale widget coverage.
- Completed: existing profile/progress schema and lesson identifiers preserved.
- Pending: Phase 3–9 expansion (new original art pipeline, advanced tracing recognition, full curriculum packs, richer game mechanics, recorded audio packs, expanded telemetry-free adaptation and release hardening).

## Verification evidence

Final command results are recorded in `GATES.md`. Only commands actually executed are reported as passing.
