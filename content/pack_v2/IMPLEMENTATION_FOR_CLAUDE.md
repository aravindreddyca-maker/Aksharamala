# Instructions for Claude / Flutter

1. Inspect the existing Aksharamala repository and `CURRICULUM_AUDIT.md` before changing code. Do not replace working content blindly.
2. Create versioned Dart models and a JSON validator for `content/*.json`. Detect duplicate IDs, missing required fields, unreachable prerequisites, empty assessments, duplicate options, and incorrect answer keys.
3. Support five **content modules** (`telugu`, `tamil`, `hindi`, `english`, `numbers`). The four language apps use one language each; Numbers is optional as a shared module or a fifth app, subject to product decision.
4. Do not assume `image_asset` or `asset_key` exists: audit missing images and block image-based questions until assets are verified.
5. Do not use TTS letter-name playback as verified phonics. Test each target language on real devices and prefer recorded native-speaker core sounds.
6. For tracing, implement guided stroke paths, tolerances and scoring; until validated, make tracing practice-only and never award mastery for scribbles.
7. For `content_status: outline_only`, show an admin/editor backlog item, **not a child-facing quest**. These are NOT ready lessons.
8. Build question generators that randomize distractor order and avoid ambiguous words, accidental answer leakage, repetitive choices, or easy positional guessing.
9. Numbers: generate dot/counter pictures for 0–20; use ten-frames and base-ten blocks for larger quantities; support visual and spoken questions, and verify all arithmetic programmatically.
10. Support age-based recommendations with mastery-based flexibility. Track per-skill mastery, error types and spaced review, not just quest completion.
11. Implement content review workflow: draft → native review → media verified → QA passed → published.
12. Preserve existing user progress via stable ID mapping; do not push or release without user approval.
13. Test at landscape sizes 640×360, 800×360, 960×540 and 1280×800; verify safe areas and text shaping.
14. Provide a coverage report by chapter, age band, content readiness, and missing media. Distinguish a lesson template from a fully production-ready lesson.

## Initial work request
Implement the schema importer and validator only, then present the coverage report and a proposal for the first 10 Telugu lessons and first 10 Number Galaxy lessons. Wait for approval before changing production curriculum.
