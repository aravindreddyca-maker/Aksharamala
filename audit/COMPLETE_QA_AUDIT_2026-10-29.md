# Aksharamala — complete app and curriculum QA audit

Audit date: 29 October 2026 (Asia/Calcutta)  
Audited revision: `24d26f0`  
Mode: audit only; no product or curriculum behavior was changed.  
Companion matrix: `audit/COVERAGE_MATRIX_2026-10-29.csv`

## Release decision

**NO-GO for unsupervised use by children and NO-GO for a claim of a complete ages 3–12 curriculum.** The repository is a credible offline Flutter vertical slice, but its complete child-facing surface is 20 legacy quests by default, optionally expanded by a parent-controlled preview to 10 Telugu vowel lessons and 11 Number Galaxy lessons (0–10). The 4,532 JSON entries are authoring records, not 4,532 finished or playable lessons.

The most serious blockers are:

1. No age-specific playable curriculum for ages 7–9 or 10–12, despite UI labels promising grammar, arithmetic, comprehension, writing, and advanced maths.
2. Tamil, Hindi, English, and almost all pack content are not imported into the app. Only Telugu and numbers receive preview lessons.
3. All 3,184 handwriting records in the pack lack stroke geometry. The app has templates only for numbers 0–10, and even those templates explicitly state that stroke order is not teacher-verified.
4. No recorded or native-speaker-verified audio exists. Android device TTS is the only speech path.
5. All 20 advanced maths topics are headings only; age 10–12 has no usable maths content.
6. English legacy `C _ T` offers A, E, O, so both CAT and COT are valid. The question is ambiguous.
7. The supplied audit brief is truncated after handwriting item “9. Meaning”; requirements after that point, if any, were not available.

## 1. Evidence and architecture inventory

The app uses Flutter with no third-party runtime packages (`pubspec.yaml` lists only the Flutter SDK). `MaterialApp` has a single root home (`SplashScreen`); navigation is imperative `Navigator` routing rather than a named route table.

| Area | Implemented evidence | Audit conclusion |
|---|---|---|
| App state | `lib/src/app_controller.dart` | One `ChangeNotifier` owns profiles, active learner, progress, rewards, preview flag, recommendations and persistence. |
| Domain data | `lib/src/models.dart`, `lib/src/curriculum.dart` | Five worlds; four hardcoded legacy quests per world. Lessons have no age or prerequisite field. |
| Screens | splash, profile, home, world map, legacy lesson, batch lesson, achievements, parent dashboard | All primary product surfaces exist. The world map does not enforce lesson prerequisites or locks. |
| Persistence | `lib/src/services/local_store.dart` | Versioned local JSON; temporary-file replacement. Parse failure silently returns an empty snapshot, so corrupt data is lost from the user's perspective. |
| Speech | `speech_service.dart`, Android `MainActivity.kt` | Android `TextToSpeech`; locale is set per utterance; unsupported voices fail gracefully. No recorded audio assets exist. |
| Rewards | `app_controller.dart`, `achievements_screen.dart` | Up to 3 stars per quest; four badges; replay farming is capped. |
| Adaptation | `recommendedLesson` and `adaptiveMessage` | Next unfinished lesson or deterministic replay; weak-world message after two attempts below 70%. This is recommendation text, not individualized curriculum. |
| Assets | `pubspec.yaml`, `assets/images/**` | 69 bundled images: 37 PNG and 32 WebP; nine declared image folders. No audio directory. |
| Authoring pack | `content/pack_v2/content/*.json` | 4,532 schema-draft records validated by pure-Dart importer logic; pack files are not bundled into the shipped app. |
| Preview import | `lib/src/batch/batch_content.dart` | 10 Telugu lessons and 11 number lessons copied into Dart and enabled only through a parent switch. |
| Handwriting | `lib/src/handwriting/**`, `writing_pad.dart` | Shape/stroke validator, guided and independent modes, arrows/start dots when a template exists, font-mask fallback otherwise. |

Implemented activities are: recognition choices, picture/word choices, missing-letter choices, paged stories with one comprehension choice, counting, one addition, one subtraction, multilingual number-name recognition, and tracing. Preview lessons add listen, recognition, word choice, quantity choice, counting, comparison, guided writing and independent writing.

There is no account, cloud sync, analytics, ad SDK, production network permission, teacher portal, multi-step assessment engine, authored mastery test, or curriculum download path.

## 2. Curriculum record audit

Independent JSON parsing produced these totals:

| Module | Records | Text-complete drafts | Needs media | Blueprints | Outlines | Handwriting placeholders | Playable preview lessons |
|---|---:|---:|---:|---:|---:|---:|---:|
| Telugu | 1,490 | 53 | 22 | 34 | 18 | 1,363 | 10 |
| Tamil | 597 | 32 | 22 | 31 | 18 | 494 | 0 |
| Hindi | 1,071 | 48 | 22 | 32 | 18 | 951 | 0 |
| English | 210 | 28 | 28 | 36 | 14 | 104 | 0 |
| Numbers | 1,164 | 872 | 0 | 0 | 20 | 272 | 11 |
| **Total** | **4,532** | **1,033** | **94** | **133** | **88** | **3,184** | **21** |

No pack record is published, native-reviewed, or backed by recorded audio. Every module has zero recorded-audio references and zero native-speaker verifications. All writing specifications have zero stroke paths and zero verified stroke orders.

Across choice records, no duplicate options were found and every declared answer was present in its options. Correct answers are stored first in nearly all records, but every such assessment declares `shuffle_options: true`; correctness therefore depends on the player actually shuffling. The preview player does shuffle. Pack prerequisites are metadata only for most content because the data is not imported; even imported `BatchLesson.prerequisites` are not enforced by `WorldMapScreen`.

## 3. Module findings

### Telugu

The pack declares 51 recognition characters, 14 క vowel-sign combinations, 20 vocabulary items, two stories, two comprehension records, eight grammar headings and six writing headings. It contains the requested early examples అమ్మ, ఆవు, ఇల్లు, ఈగ, ఉడుత, ఊయల, ఐదు and ఒంటె. The preview imports ten vowels/letters: అ, ఆ, ఇ, ఈ, ఉ, ఊ, ఎ, ఏ, ఐ, ఒ. ఋ is deliberately deferred as rare; ఓ and ఔ are not in the preview. The preview does not import consonants, gunintalu instruction, ottulu instruction, sentences, grammar or stories.

The vocabulary and spelling are drafts requiring native-educator review. No rare-letter picture word was invented for ఎ; that lesson is letter-only, which is the correct conservative choice. Picture mappings exist for the requested imported words. However, displayed words such as అమ్మ and ఇల్లు already contain conjunct/ottu forms before those forms are taught.

Severity: **Critical** for curriculum completeness; **High** for unverified language/audio; **Critical** for handwriting claims.

### Tamil

The pack correctly inventories 12 uyir and 18 mei recognition targets (30 total). It has only 11 க-series combination blueprints, not all 216 uyirmei combinations, and none is imported. The legacy app teaches only அ, one word choice, tracing of அ and one story. ஆய்த எழுத்து ஃ is not present as a child-facing lesson.

The data model stores combined forms in full strings (`rendered_combination`) and Flutter renders strings rather than iterating code points, so the inspected implementation does not split a Tamil grapheme into visible Unicode code points. That is a source-level finding, not a cross-device font-rendering certification.

Severity: **Critical**.

### Hindi

The pack declares 46 recognition records and 12 क-series matra combinations, but all combination records are blueprints and none is imported. The legacy app teaches only अ, one कमल completion item, tracing of अ and one story. Barakhadi, common conjuncts, sentence progression, grammar and verified handwriting are absent from the playable curriculum.

Strings are passed intact to Flutter and Android TTS, so pre-base signs and conjuncts are not deliberately split in code. Real-device rendering and native pronunciation remain unverified. The older legacy story inconsistency remains educationally risky: the title uses “नीला पतंग” while standard agreement normally expects “नीली पतंग”; this requires Hindi educator sign-off.

Severity: **Critical**.

### English

The pack declares uppercase A–Z recognition and 26 vocabulary records, but no lowercase recognition sequence. Ten phonics entries are blueprints, not lessons. There are no imported pack lessons. The legacy surface teaches A, the ambiguous `C _ T` item, tracing A and one short story.

There is no complete letter-sound sequence, CVC progression, sight-word curriculum, sentence curriculum, grammar practice or independent writing. The phonics ambiguity is confirmed: offered A and O produce valid English words CAT and COT. A picture or semantic clue would be required to make the answer unique.

Severity: **Critical**.

### Number Galaxy

The pack includes 101 numeral-recognition, 21 counting, 231 addition, 231 subtraction, 144 multiplication and 144 division records. I independently recalculated all **750 arithmetic keys**: zero incorrect keys, zero division-by-zero records, zero negative subtraction results and zero duplicate option sets were found.

Question quality is nevertheless weak. In every one of the 750 arithmetic records the correct value is the smallest numeric option, with distractors `answer + 1` and `answer + 2`. Although options are shuffled, a child can solve every item by selecting the smallest displayed number. This is a systematic answer-pattern defect, not valid mastery assessment.

Addition/subtraction are bounded to non-negative results within 0–20; multiplication covers 1×1 through 12×12; division consists only of exact products divided by one factor, so there are no remainders or zero cases. The pack has no generated runtime questions, word problems, or multi-step problems.

Twenty topic records—place value, patterns, shapes, measurement, time, money, fractions, decimals, percentages, geometry, data, word problems, factors/multiples, negative numbers and ratio—are `outline_only`. All eight age-10–12 maths topics are headings without teaching, practice or assessment. The only playable preview is 0–10 recognition/count/compare/write; default legacy maths is counting three, 2+3, 7−2 and number names.

Severity: **Critical**.

## 4. Handwriting engine critical audit

| Requirement | Numbers 0–10 | Telugu preview | Tamil/Hindi/English pack |
|---|---|---|---|
| Correct displayed glyph | Implemented | Implemented for 10 imported glyphs | Data only; not playable |
| Starting point | Green dot from template | No authored start point; font-mask guide | None |
| Direction | Arrow and validator | No authored direction | None |
| Stroke order | Validator supports it | No authored order | None |
| Animated demonstration | **Absent** | **Absent** | **Absent** |
| Guided tracing | Implemented | Font-outline mask | Not playable |
| Independent writing | Implemented | Font-mask shape check | Not playable |
| Shape evaluation | Template validator | Rasterized font-mask validator | Not playable |
| Teacher-verified formation | **No** | **No** | **No** |
| Mastery award | Deliberately disabled for unverified templates | Deliberately disabled | Not playable |

The engine is substantially better than the legacy “minimum stroke” behavior described in older documentation: it rejects random scribbles, wrong digits, wrong direction/order, excess ink and missing strokes in unit tests. But its only authored templates are digits 0–10, and `digit_templates.dart` marks every template `strokeOrderVerified == false`. Telugu uses a font outline, which can judge rough shape but cannot establish pedagogically correct start, direction or order. No writing animation exists.

Result: useful **practice prototype**, not a certified handwriting-teaching engine.

## 5. Progression, unlocking and child UX

- All legacy and preview quest cards are tappable. The world map has no locked state and never consults `BatchLesson.prerequisites`.
- Completion is awarded when required choice steps are correct. Writing steps are practice-only, a safe decision while strokes are unverified.
- Every age sees the same worlds and lessons. Age affects labels and guidance text only.
- The parent preview switch exposes unfinished curriculum directly to children without an educator-review guard.
- The “adaptive” path recommends the first unfinished quest and later rotates by attempt count. It does not diagnose phoneme, grapheme or maths misconceptions.
- Instructions depend on reading or pressing Listen. TTS availability and pronunciation vary by device, and there is no recorded fallback.

## 6. Automated verification status

Dependency-independent checks executed on this revision:

- `node tool/verify_phase12.mjs` — **pass**.
- `node tool/verify_docs.mjs` — **pass**.
- `node tool/verify_product.mjs` — **fail**: `Missing product evidence: finger tracing`. This verifier is stale relative to the redesigned `WritingPad` terminology or exposes a documentation/source expectation mismatch; either way it is not green.
- Independent Node parsing/recalculation — **pass** for JSON parse, record counts, option duplication, answer membership and all 750 arithmetic keys; **fail** for distractor-pattern quality.

Flutter was supplied at `E:\flutter-sdk\bin\flutter.bat` after the initial audit pass. Current verification on Flutter 3.47.8 / Dart 3.13.7 produced:

- `flutter analyze` — **pass**, no issues found.
- `flutter test` — **pass**, **352 passed and 13 skipped**. The skips are named known curriculum defects, not unavailable tests.
- `flutter test test/audit --dart-define=AUDIT_STRICT=true` — **expected failure**, **29 passed and 13 failed**. The 13 failures explicitly confirm the known defects: emoji lesson symbols, mixed-script TTS, ambiguous `C _ T`, answers exposed in prompts, absent word pictures, unstated/inconsistent story answers, unused assets/data, identical age content, no age field, one taught Indic letter per legacy world, and tracing text that promises absent dots.
- `flutter build apk --debug` — **pass**, producing `build/app/outputs/flutter-apk/app-debug.apk`.

These checks validate static analysis, widget/unit behavior and Android compilation on revision `24d26f0`. They do not replace real-device sound playback, multilingual font/rendering checks, touch tracing, accessibility review, or supervised child-usability testing.

## 7. Required release gates

1. Import and complete a genuinely age-banded curriculum; do not expose authoring rows as lesson counts.
2. Obtain native educator sign-off for Telugu, Tamil and Hindi, and early-literacy sign-off for English.
3. Record and native-verify audio for every child-facing instruction, target and example.
4. Replace maths distractor generation so the answer is not always the smallest option; add word problems, edge cases and advanced strands.
5. Author and teacher-verify stroke paths, starts, directions and orders for every taught glyph; add an actual animated demonstration.
6. Enforce prerequisites/unlocks or remove claims that the sequence is enforced.
7. Resolve the English CVC ambiguity and review every phonics item for a single defensible answer.
8. Perform real-device multilingual rendering/audio, touch, accessibility and supervised child-usability testing; automated analysis, tests and the debug APK build are now current and recorded above.

Until these gates pass, the app should be described only as an **offline multilingual learning prototype/vertical slice**, not a complete curriculum for children ages 3–12.
