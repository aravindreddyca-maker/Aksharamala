# Age 5–6 candidate artwork: inventory and review (30 October 2026)

Eighteen candidate pictures were supplied (flag, chicken, conch, head, fox,
tooth, sky, ray, vegetables, wave, cake, crane, monkey, milk, black, how,
cuckoo, and a family picture for "paternal uncle"). Their background-removed
originals are in `.tmp_cutouts/Aksharamala_cutouts/`; the production copies are
in `assets/images/age56/`. Every file was inspected as an image, not only
measured. The full per-file record is
`AGE_5_6_ARTWORK_REVIEW_LEDGER.csv`.

## The standard checked

Exactly 512 × 512 px; WebP with a real alpha channel; subject centred with a
generous margin (the production fit is a 448 px box, so at least 32 px each
side); no text, border or background scene; readable on a small phone; soft 3D
children's style; culturally appropriate; under 100 KB.
`tool/validate_age56_art.py` measures size, alpha, margins, centring and a
baked-checkerboard test; `test/age56_visuals_test.dart` now also reads every
WebP header and requires 512 × 512 with alpha.

## Result

| Decision | Count | Files |
|---|---:|---|
| Accepted | 6 | flag, chicken, conch, head, fox, tooth |
| Accepted, style note | 7 | vegetables, cake, crane, monkey, milk, black, cuckoo |
| Provisional (kept, needs regeneration) | 3 | sky, ray, wave |
| Rejected (removed from the app) | 2 | how, paternal_uncle |

What changed for the 13 accepted pictures: they arrived as 512 × 512 WebPs with
0–4 px of margin (the subject touched the edge). They were recomposed from the
full-resolution cutouts, scaled down proportionally into a 448 px box and
centred (`tool/recompose_age56.py`); nothing was stretched. Each is now a true
512 × 512 transparent WebP between 14 and 52 KB.

**Style.** Seven accepted pictures are photographs, not soft 3D illustrations,
so the set is visually mixed. They were accepted because the background is
clean and the meaning is right; they should be regenerated if one consistent
style is wanted. No picture was restyled by editing.

**Provisional.** `sky` and `ray` still carried a faint baked checkerboard on
the rim (trimmed 14 px) and have blobby outlines. `wave` is a cropped sea scene
with straight edges, not an isolated subject, and was not recomposed. They stay
so the lessons keep a picture, and are flagged for regeneration.

**Rejected.**

- `how` shows a boy building a toy car. The lesson word (कैसा) means "how /
  what kind"; the spec asks for a child comparing two visibly different
  objects. The picture does not convey the concept.
- `paternal_uncle` shows a man with his arm around a boy. That reads as father
  and son. A single picture of a man can never establish "father's younger
  brother" (चाचा): the relationship comes from the sentence or a family tree,
  not from how a person looks. The spec's idea of one adult man standing alone,
  checked by a kinship educator, is the safest picture; this one suggests a
  different relationship. It was also cropped by the photo frame (0 px margin).

Both were removed from `assets/images/age56/` and from the generator's picture
table (`tool/generate_age56.dart`), so lessons `hindi-56-007` and
`hindi-56-017` are honestly "visually incomplete" again. Their lesson ids,
prerequisites, progress and rewards are unchanged.

## Older pictures

`dog`, `fish`, `sun` and `tree` were 512 × 425; they were padded (not scaled)
to 512 × 512. The other existing pictures were not part of this review. 24 of
the current 52 files have a margin under 4 % of the canvas (they were accepted
earlier); the ledger lists each, and `tool/recompose_age56.py` can be extended
to recompose them.

## Coverage after this change

150 of 162 lessons are visually complete (152 before; two were removed). The
other 12 need a picture: the 10 concepts never generated (gowri, service, hug,
maternal_uncle, father, grandfather, toy, rain, lullaby, sita) plus how and
paternal_uncle.

## Still not done

Pronunciation and native-educator review are untouched by this artwork work and
remain unverified for every lesson. `cuckoo` still needs species verification,
`black` an educator's view on colour-versus-object, `flag` a representation
review, and any relationship picture a kinship educator.
