# Age 5–6 curriculum and visual coverage

Generated from the five supplied JSON files and `audit/AGE_5_6_ASSET_MANIFEST.csv`.
All 162 records use the existing `BatchLesson` engine. “Playable” means the
lesson has teaching content, a valid practice answer and a resolvable unlock
path. “Visually incomplete” means required production illustration art is
still absent; those lessons remain playable but are not reported as visually
complete.

| Module | Playable | Incomplete lessons | Missing topics | Visually complete | Visual art missing |
|---|---:|---:|---|---:|---:|
| English | 30 | 0 | None in supplied scope: CVC phonics, sight words, sentences and letter shapes are present | 25 | 5 |
| Telugu | 26 | 0 | None in supplied scope: గుణింతాలు and simple reading are present | 8 | 18 |
| Hindi | 26 | 0 | None in supplied scope: मात्राएँ and simple reading are present | 11 | 15 |
| Tamil | 26 | 0 | None in supplied scope: உயிர்மெய்யெழுத்துகள் and simple reading are present | 11 | 15 |
| Number Galaxy | 54 | 0 | None in supplied scope: place value, addition, subtraction, comparison, patterns, shapes and everyday maths are present | 51 | 3 |
| **Total** | **162** | **0** | — | **106** | **56** |

## Asset inventory

- Reused validated app art: cat, mango and Telugu cow.
- Added optimized 512 px WebP cutouts: dog, fish, sun and tree. The reference
  goat was not shipped because the supplied JSON has no goat vocabulary lesson.
- Added optimized 512 px WebP cutouts for pin, sit and pig. Consolidated
  semantically identical concepts across languages and reused ten suitable
  existing illustrations, improving visual completion from 86 to 102 lessons.
- The baseline 76 missing lesson rows consolidate to 70 unique visual concepts:
  17 are now integrated and verified; 53 remain in the production queue.
- Integrated four transparent 512 px geometry WebPs from the supplied visual
  production pack. Their intentionally flat treatment preserves exact shape
  recognition; geometry, alpha transparency and phone-size decoding were
  inspected before the corresponding lessons were marked visually complete.
- Full production requirements, multilingual word mapping, prompts, lesson
  usage and review status are recorded in `AGE_5_6_PRODUCTION_ARTWORK_SPEC.md`.
- Script combinations are rendered and animated as native Flutter text; marks
  are not baked into raster images.
- Counting and arithmetic manipulatives are code-native, cache-free visuals.
- Audio uses the existing speech path. No imported pronunciation is marked as
  native-speaker verified.
- No imported lesson awards handwriting mastery. Guided tracing remains
  practice-only until validated stroke geometry and evaluation are supplied.

The CSV manifest has one row per lesson, lists every resolved and missing
required image, and records code-native animation use. Missing illustration
rows are intentionally `visually_complete=false`; they are the next safe asset
production queue rather than placeholder lesson records.

## Source status

The supplied ZIP labels the curriculum draft-ready for technical integration
and requiring educator review. The import preserves that status with
`educatorReviewVerified=false` for every lesson. No record is represented as
pedagogically or pronunciation verified merely because it is technically
playable.
