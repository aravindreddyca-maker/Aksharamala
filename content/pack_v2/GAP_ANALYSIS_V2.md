# Curriculum gap assessment — expanded v2 (29 October 2026)

## What changed
Added explicit handwriting practice targets for all five modules: Telugu vowels/consonants/gunintam forms and a starter set of conjuncts; Tamil 12 uyir + 18 mei + 216 uyirmei + aytham; Hindi vowels/consonants/barakhadi combinations and sample conjuncts; English uppercase and lowercase; Numbers digits, two-digit numbers, and a sample of three-digit numbers. Existing tracing lessons are retained and annotated with a handwriting specification. Added independent writing records. Counts are in COVERAGE_SUMMARY.csv.

## Critical outstanding gaps — do not label as production ready
1. **No verified stroke geometry, animations or dotted paths**. Every new writing target is a *content target*, not a working handwriting activity. `stroke_paths: null`, `stroke_validation_enabled: false`, `mastery_award_enabled: false` intentionally prevent false mastery.
2. **No verified recorded narration or native-language instruction translations**. New English placeholder instructions must be localised by qualified educators and audio tested on real Android devices.
3. **Upper-level curriculum remains outlines**. Grammar, composition, comprehension, number sense, fractions, decimals, geometry, measurement, time, money, data and word problems need fully authored explanations, scaffolded examples and multiple assessments. Arithmetic drill quantity is not equivalent to curriculum depth.
4. **Prerequisite links are mostly empty**. Create and validate dependency graphs; a child must not be asked to independently read unfamiliar letter forms.
5. **Writing inventories require local curriculum review**. Telugu rare vowels/signs and ottu list, Hindi conventional vowel/consonant inventory and barakhadi variants, Tamil special forms and borrowed consonants, and the selected three-digit number samples are not exhaustive or independently validated.
6. **Not all learning objectives have multiple independent questions**. Need distinct practice, recall, listening discrimination, formative checks, remediation and delayed mastery checks.
7. **Assets missing**: character-specific tracing paths, handwriting exemplars, word illustrations and age-appropriate story art must be sourced or produced and visually verified.
8. **Learning design not implemented**: per-age/skill adaptive progression, parent dashboards, real device screen-size and accessibility checks, offline voice packs, writing feedback and progress migrations require engineering.
9. **Content QA**: All word meanings, distractors, stories, Hindi gender agreement, English phonics, and language-specific pronunciation require native educator sign-off.
10. **Numeracy**: Needs conceptual manipulatives, number lines, carry/borrow instruction, place-value blocks, worked solutions, math language localisation and varied word problems; writing targets alone do not fill these gaps.

## Writing lesson implementation contract
Each writing lesson has `handwriting_spec`. Render only as unscored preview/practice until `stroke_paths` is populated with educator-approved normalized stroke segments, guides are available, device handwriting evaluation is tested, and a human has reviewed accessibility and letterform variants. Never infer writing mastery from touch count. Do not claim handwriting functionality based on lesson-record counts.

## Recommended next authoring batches
A. Educator-approved stroke SVG/vector paths for basic letters and 0–9; B. localised narration and tested voice; C. scaffolded vowel/consonant/matra/gunintam/uyirmei teaching with review; D. age-banded reading/grammar/writing; E. numeracy concept units and worked examples; F. real-child usability and learning outcomes.

## Verification performed
All five JSON files parsed, lesson IDs unique per module, language identifiers consistent, and existing MCQ answers occur in options without duplicate options. This is a *structural* check, not a linguistic or pedagogical validation.
