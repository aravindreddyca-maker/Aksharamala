# Aksharamala — Regional Language + Number Galaxy Curriculum Pack

This pack includes **Telugu, Tamil, Hindi, English, and Numbers**. It is a **substantial draft curriculum and question-bank starter**, not a professionally validated, fully finished curriculum for every skill through age 12. **Do not publish or enable all lessons without review.**

## Contents
- `content/telugu.json`, `tamil.json`, `hindi.json`, `english.json`: alphabet recognition, guided tracing specs, vocabulary and spelling exercises, two short stories and comprehension/sequence questions per language, vowel-combination outlines, grammar and writing unit outlines.
- `content/numbers.json`: numeral recognition 0–100, counting 0–20, addition and subtraction facts within 20, multiplication/division facts 1–12, plus 20 advanced topic outlines.
- `LESSON_INDEX.csv`: searchable lesson inventory.
- `CURRICULUM_ROADMAP.md`: age bands and scope.
- `IMPLEMENTATION_FOR_CLAUDE.md`: Flutter implementation guidance.
- `VALIDATION_CHECKLIST.md`: quality gates.

## Key limitations
1. The language content is AI-drafted. Telugu, Tamil and Hindi **must be checked by native-speaking teachers** for vocabulary, stories, script conventions and teaching sequence; English phonics requires specialist review.
2. Generated letter-recognition quizzes test visual identification; **speech assets are missing** and `audio.verified_by_native_speaker` is false.
3. `picture_word_match` activities have `asset_key` references, **not actual image files**. Create and verify one image per asset.
4. Tracing lessons require **real educator-approved stroke geometry** and behavioural validation; a touch-count heuristic is not sufficient.
5. Advanced language grammar, writing, orthographic combinations, and higher maths topics are **outlines only** (`content_status: outline_only`); they need complete authored instruction, practice and assessment before use.
6. Arithmetic answer keys are generated and machine-checkable, but question wording, difficulty, distractors and visual scaffolding require human QA.
7. In the regional-app plan, Numbers can be included as a **shared optional module** in each regional flavor or shipped as a separate Number Galaxy app; avoid showing other language worlds.
8. Age bands are indicative. Advancement should be mastery-based; older beginners must be able to start at foundational skills.

## Integration
Read `IMPLEMENTATION_FOR_CLAUDE.md`. Import content into a staging environment, validate schema and curriculum before enabling it. Keep existing progress identifiers stable or migrate them.
