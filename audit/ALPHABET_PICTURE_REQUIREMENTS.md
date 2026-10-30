# Pictures needed for the "A for Apple" alphabet theme

For every letter of the alphabet, the child sees the letter and one picture word
("A for Apple"). This is the list of pictures required. Machine-readable copy:
`ALPHABET_PICTURE_REQUIREMENTS.csv` (language, letter, word, status, file).

## Same standard as the age 5–6 artwork

Exactly 512 × 512 px, transparent WebP with real alpha, polished soft 3D
children's style, one subject centred with a generous margin (keep the subject
inside the middle ~440 px), readable on a small phone, culturally appropriate
for India. **No text, letters, numbers, logos, watermark, border, emoji or
background scene.** Suggested folder and names: `assets/images/quiz/en_<word>.webp`
(and `hi_`, `ta_`, `te_` for the others).

Shared prompt, then add the "Picture" line:

> Polished soft 3D children's educational illustration for ages 3–6; one
> immediately recognizable subject; centered, entire subject visible, generous
> transparent margin, soft studio light, warm friendly expression where
> applicable; no embedded text, letters, numbers, symbols, border, watermark,
> unrelated props, or background scene.

## English A to Z: 26 pictures, 12 exist, 14 needed

| Letter | Word | Status | Picture (add to the shared prompt) |
|---|---|---|---|
| A | Apple | exists (`quiz/apple.png`) | |
| B | Ball | exists (`quiz/ball.png`) | |
| C | Cat | exists (`quiz/cat.png`) | |
| D | Dog | exists (`age56/dog.webp`) | |
| E | Egg | **needed** | One whole white hen's egg standing upright in a small cup. |
| F | Fish | exists (`age56/fish.webp`) | |
| G | Goat | **needed** | One friendly standing goat, full body, small horns. |
| H | Hat | **needed** | One colourful child's sun hat with a wide brim, no face. |
| I | Ink | **needed** | One small glass ink bottle with a single blue drop beside it, no label. *Better word: Igloo or Ice cream (children know them); the pack uses Ink, so the word would need approving first.* |
| J | Jam | **needed** | One open jar of red fruit jam with a small spoon, no label. |
| K | Kite | exists (`quiz/kite.png`) | |
| L | Lion | **needed** | One friendly young lion cub, full body, sitting. |
| M | Mango | exists (`quiz/mango.png`) | |
| N | Nest | exists (`age56/nest.webp`) | |
| O | Orange | **needed** | One fresh orange with a green leaf and one peeled segment beside it. |
| P | Pen | exists (`quiz/te_pen.webp`) | |
| Q | Queen | **needed** | One friendly storybook Indian queen with a simple crown and royal sari (cultural review). |
| R | Rabbit | **needed** | One friendly white rabbit sitting, long ears up. |
| S | Sun | exists (`age56/sun.webp`) | |
| T | Tree | exists (`age56/tree.webp`) | |
| U | Umbrella | **needed** | One open colourful umbrella, handle visible. |
| V | Van | **needed** | One small friendly passenger van, three-quarter side view, no lettering or logos. |
| W | Water | exists (`age56/water.webp`) | |
| X | Xylophone | **needed** | One colourful child's xylophone with two mallets. |
| Y | Yak | **needed** | One friendly yak with long fur, full body. |
| Z | Zebra | **needed** | One friendly zebra standing, full body, clear stripes. |

Notes: the existing apple, ball, cat, kite and mango are PNGs from the first art
set (not 512 × 512 WebP in this style). Regenerate them if you want one
consistent look across the alphabet.

## Hindi, Tamil and Telugu: pictures for the pack's own picture words

Telugu is covered: all 14 of its picture words have a picture. Still needed:

| Language | Letter | Word | Meaning | Picture |
|---|---|---|---|---|
| Hindi | इ | इमली | tamarind | A small bunch of brown tamarind pods, one split open. |
| Hindi | ई | ईख | sugarcane | Two short stalks of sugarcane with leaves. |
| Hindi | उ | उल्लू | owl | One friendly owl, full body, perched. |
| Hindi | ऊ | ऊन | wool | A ball of wool with a loose strand and two knitting needles. |
| Hindi | ऋ | ऋषि | sage | A calm Indian sage with a beard, seated, simple robes (cultural review). |
| Hindi | ए | एक | one | Exactly one red apple (the count is the point; no numeral). |
| Hindi | ऐ | ऐनक | spectacles | One pair of child-sized round spectacles. |
| Hindi | ओ | ओस | dew | Dew drops on a single green leaf. |
| Hindi | औ | औरत | woman | One friendly adult Indian woman, waist up. |
| Tamil | ஆ | ஆடு | goat | One friendly standing goat (same picture as English G). |
| Tamil | உ | உடை | clothes | One folded colourful child's shirt and shorts. |
| Tamil | எ | எலி | mouse | One friendly mouse, full body. |
| Tamil | ஏ | ஏணி | ladder | One wooden ladder leaning on a plain wall-less post. |
| Tamil | ஓ | ஓடை | stream | A small stream of water between two stones. |
| Tamil | ஔ | ஔவை | a name | Not a picture word: it is a person's name. Ask a Tamil educator for a replacement word. |

## Letters with no picture word yet

51 Telugu, 46 Hindi and 30 Tamil letters exist; 14, 14 and 16 have a pack
picture word. The rest are shown on their own. Draft words for 59 of them are in
`ALPHABET_WORD_CHART_PROPOSAL.md`; each new word would need approving by a native
speaker and then one picture from this same standard. Rare letters (for example
ఙ, ఞ, ங், ழ், ङ, ञ) are taught inside other words and should not get a forced
picture.

## Totals

| Language | Picture words | Pictures exist | Pictures needed |
|---|---:|---:|---:|
| English | 26 | 12 | **14** |
| Hindi | 14 | 5 | **9** (one, a name: ask an educator) |
| Tamil | 16 | 10 | **6** (one is a name: ask an educator) |
| Telugu | 14 | 14 | 0 |
| **Total** | 70 | 41 | **29** |
