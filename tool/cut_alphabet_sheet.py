"""Cut an "A for Apple" picture sheet into production WebPs.

    python tool/cut_alphabet_sheet.py <english|indic> <sheet image>

The sheet is one white-background image holding many pictures. Each picture is
cut out by its own box (the sheet's tiles are not a clean grid), the background
is removed with rembg, and the result is saved twice:

- `.tmp_cutouts/alphabet_en/<name>.png`: full-size transparent cutout (source)
- `assets/images/quiz/en_<name>.webp`: exactly 512 x 512, transparent, the
  subject fitted inside a 448 px box so every side keeps at least 32 px

Pictures listed in SKIP failed review and are cut for the record only; they are
not written to assets. Nothing is stretched.
"""

import os
import sys

import numpy as np
from PIL import Image
from rembg import new_session, remove
from scipy import ndimage as ndi

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CUTS = os.path.join(ROOT, '.tmp_cutouts', 'alphabet_sheets')
ASSETS = os.path.join(ROOT, 'assets', 'images', 'quiz')

# where each picture sits on a supplied sheet: (x0, y0, x1, y1), and the file
# prefix. "english" is the first sheet (E-Z pictures); "indic" is the Hindi and
# Tamil sheet.
SHEETS = {
    'english': {
        'prefix': 'en_',
        'box': {
            'egg': (30, 20, 270, 322), 'goat': (296, 0, 535, 332),
            'hat': (588, 28, 945, 278), 'ink': (965, 35, 1205, 300),
            'jam': (1268, 8, 1500, 326), 'lion': (4, 330, 272, 662),
            'orange': (300, 372, 604, 672), 'queen': (626, 296, 912, 700),
            'rabbit': (950, 330, 1160, 672), 'umbrella': (1222, 354, 1536, 658),
            'van': (4, 700, 436, 972), 'xylophone': (440, 730, 818, 985),
            'yak': (822, 684, 1196, 1018), 'zebra': (1200, 662, 1500, 1018),
        },
        # the supplied queen is cropped at the hem (no feet): not shipped
        'skip': {'queen'},
        'names': {},
    },
    'indic': {
        'prefix': '',
        'box': {
            'tamarind': (4, 4, 340, 345), 'sugarcane': (316, 0, 640, 345),
            'owl': (625, 8, 890, 345), 'wool': (900, 20, 1225, 345),
            'sage': (1225, 0, 1536, 345),
            'apple': (4, 345, 292, 660), 'spectacles': (305, 430, 645, 625),
            'dew': (640, 350, 918, 665), 'woman': (920, 345, 1205, 690),
            'goat': (1245, 335, 1490, 690),
            'clothes': (4, 650, 385, 1000), 'mouse': (385, 660, 652, 1000),
            'ladder': (730, 655, 920, 1000), 'stream': (960, 680, 1536, 1010),
        },
        # the Tamil goat is the English goat picture (already shipped)
        'skip': {'goat'},
        'names': {
            'tamarind': 'hi_tamarind', 'sugarcane': 'hi_sugarcane',
            'owl': 'hi_owl', 'wool': 'hi_wool', 'sage': 'hi_sage',
            'apple': 'hi_one', 'spectacles': 'hi_spectacles', 'dew': 'hi_dew',
            'woman': 'hi_woman', 'clothes': 'ta_clothes', 'mouse': 'ta_mouse',
            'ladder': 'ta_ladder', 'stream': 'ta_stream',
        },
    },
}

# Pictures the background remover gets wrong, fixed by colour instead:
#  - COLOUR_KEY: pale subjects (water) the remover treats as background; the
#    subject is everything that is not near-white on the sheet.
#  - CLEAR_WHITE: opaque white left inside or under the subject (spectacle
#    lenses; the white strip under the woman, where the sheet crops her).
COLOUR_KEY = {'stream': 22}
CLEAR_WHITE = {'spectacles': (None, 215), 'woman': (0.78, 236)}

SIZE, FIT, MAX_KB = 512, 448, 95


def save_webp(im, path):
    for q in (90, 86, 82, 78, 74, 70, 64, 58):
        im.save(path, 'WEBP', quality=q, alpha_quality=100, method=6)
        if os.path.getsize(path) <= MAX_KB * 1024:
            return q
    return 0


def compose(cut):
    box = cut.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    cut = cut.crop(box)
    s = FIT / max(cut.size)
    cut = cut.resize((max(1, round(cut.width * s)), max(1, round(cut.height * s))), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(cut, ((SIZE - cut.width) // 2, (SIZE - cut.height) // 2))
    return canvas


def main(which, sheet):
    conf = SHEETS[which]
    BOX, SKIP = conf['box'], conf['skip']
    os.makedirs(CUTS, exist_ok=True)
    im = Image.open(sheet).convert('RGB')
    sess = new_session('isnet-general-use')
    for name, (x0, y0, x1, y1) in BOX.items():
        tile = im.crop((x0, y0, min(x1, im.width), min(y1, im.height)))
        cut = remove(tile, session=sess, post_process_mask=True)
        arr = np.asarray(cut).copy()
        a = arr[..., 3] > 40
        lab, n = ndi.label(ndi.binary_dilation(a, iterations=14))
        if n > 1:  # keep the main subject with its parts (cup, spoon, mallets)
            sizes = ndi.sum(a, lab, range(1, n + 1))
            arr[..., 3] = np.where(lab == 1 + int(np.argmax(sizes)), arr[..., 3], 0)
        if name in COLOUR_KEY:
            rgb = np.asarray(tile).astype(int)
            far = (255 - rgb.min(2)) > COLOUR_KEY[name]
            far = ndi.binary_closing(far, iterations=3)
            far = ndi.binary_fill_holes(far)
            lab2, n2 = ndi.label(ndi.binary_dilation(far, iterations=10))
            if n2 > 1:
                sz = ndi.sum(far, lab2, range(1, n2 + 1))
                far = far & (lab2 == 1 + int(np.argmax(sz)))
            soft = ndi.gaussian_filter(far.astype(np.float32), 1.2)
            arr = np.dstack([rgb.astype(np.uint8), np.clip(soft * 255, 0, 255).astype(np.uint8)])
        if name in CLEAR_WHITE:
            top, thr = CLEAR_WHITE[name]
            white = np.asarray(tile).min(2) > thr
            if top is not None:
                white[: int(white.shape[0] * top), :] = False
            arr[..., 3] = np.where(white, 0, arr[..., 3])
        cut = Image.fromarray(arr, 'RGBA')
        cut.save(os.path.join(CUTS, name + '.png'))
        if name in SKIP:
            print(f'{name}: cut for the record, not shipped')
            continue
        fname = conf['names'].get(name, conf['prefix'] + name)
        out = os.path.join(ASSETS, fname + '.webp')
        q = save_webp(compose(cut), out)
        print(f'{fname}.webp  quality {q}  {os.path.getsize(out) // 1024} KB')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
