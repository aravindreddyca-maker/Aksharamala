"""Recompose candidate artwork into production WebPs for the age 5-6 worlds.

    python tool/recompose_age56.py

Reads the background-removed candidates in `.tmp_cutouts/Aksharamala_cutouts/`
and writes `assets/images/age56/<name>.webp` at exactly 512 x 512 px with a
transparent canvas, the subject centred and a generous margin (the subject is
fitted inside a 448 px square, so every side keeps at least 32 px). Nothing is
stretched. The cloud and sunray pictures also lose a few pixels of rim, where
the original baked checkerboard still showed.

Images that failed review (see audit/AGE_5_6_ARTWORK_REVIEW_LEDGER.csv) are
not written. The four older, non-square pictures are only padded to 512 x 512.
"""

import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, '.tmp_cutouts', 'Aksharamala_cutouts')
DST = os.path.join(ROOT, 'assets', 'images', 'age56')

SIZE = 512
FIT = 448            # subject box; margin >= 32 px on every side
MAX_KB = 95          # the visuals test requires < 100 KB

# candidate file -> production name. Rejected candidates are left out on
# purpose: wave stays as it was, how and paternal_uncle are not shipped.
ACCEPTED = {
    'flag': 'flag',
    'hen': 'chicken',
    'conch_shell': 'conch',
    'boy_face': 'head',
    'fox': 'fox',
    'tooth': 'tooth',
    'clouds': 'sky',
    'sunrays_clouds': 'ray',
    'vegetables': 'vegetables',
    'cake': 'cake',
    'sarus_crane': 'crane',
    'monkey': 'monkey',
    'milk_glass': 'milk',
    'black_ball': 'black',
    'koel': 'cuckoo',
}

# pictures whose rim still shows a baked checkerboard: trim it back
CLEAN_RIM = {'clouds': 14, 'sunrays_clouds': 14}

# older non-square pictures: pad only
PAD_ONLY = ['dog', 'fish', 'sun', 'tree']


def save_webp(im, path):
    for q in (90, 86, 82, 78, 74, 70, 64, 58):
        im.save(path, 'WEBP', quality=q, alpha_quality=100, method=6)
        if os.path.getsize(path) <= MAX_KB * 1024:
            return q
    return 0


def compose(im, rim=0):
    im = im.convert('RGBA')
    if rim:
        a = np.asarray(im)[..., 3] > 128
        a = ndi.binary_erosion(a, iterations=rim)
        soft = ndi.gaussian_filter(a.astype(np.float32), 2.0)
        arr = np.asarray(im).copy()
        arr[..., 3] = np.clip(soft * 255, 0, 255).astype(np.uint8)
        im = Image.fromarray(arr, 'RGBA')
    box = im.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    im = im.crop(box)
    scale = FIT / max(im.size)
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((SIZE - im.width) // 2, (SIZE - im.height) // 2))
    return canvas


def main():
    os.makedirs(DST, exist_ok=True)
    for src, name in ACCEPTED.items():
        out = os.path.join(DST, name + '.webp')
        im = compose(Image.open(os.path.join(SRC, src + '.png')), CLEAN_RIM.get(src, 0))
        q = save_webp(im, out)
        print(f'{name}.webp  quality {q}  {os.path.getsize(out) // 1024} KB')
    for name in PAD_ONLY:
        path = os.path.join(DST, name + '.webp')
        im = Image.open(path).convert('RGBA')
        if im.size == (SIZE, SIZE):
            continue
        canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        canvas.alpha_composite(im, ((SIZE - im.width) // 2, (SIZE - im.height) // 2))
        q = save_webp(canvas, path)
        print(f'{name}.webp  padded to 512x512  {os.path.getsize(path) // 1024} KB')


if __name__ == '__main__':
    sys.exit(main())
