"""Split the two-lion feedback sheet (real alpha) into one PNG each.

Run:  python -I tool/cut_feedback.py <sheet.webp|png>
Output: assets/images/feedback/wonderful.png (left), good_try.png (right),
        trimmed to the artwork and sized to at most 640 px tall.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAX_H = 640


def runs(idx, gap=10):
    out, start, prev = [], idx[0], idx[0]
    for v in idx[1:]:
        if v - prev > gap:
            out.append((int(start), int(prev)))
            start = v
        prev = v
    out.append((int(start), int(prev)))
    return out


def main():
    sheet = Image.open(sys.argv[1]).convert('RGBA')
    mask = np.array(sheet)[..., 3] > 16
    cols = runs(np.where(mask.any(axis=0))[0])
    assert len(cols) == 2, f'expected two images, found {cols}'
    target = os.path.join(ROOT, 'assets', 'images', 'feedback')
    os.makedirs(target, exist_ok=True)
    for (x0, x1), name in zip(cols, ['wonderful', 'good_try']):
        sub = mask[:, x0 : x1 + 1]
        ys = np.where(sub.any(axis=1))[0]
        pad = 6
        crop = sheet.crop((max(0, x0 - pad), max(0, int(ys[0]) - pad),
                           x1 + pad, int(ys[-1]) + pad))
        if crop.height > MAX_H:
            scale = MAX_H / crop.height
            crop = crop.resize((round(crop.width * scale), MAX_H), Image.LANCZOS)
        crop.save(os.path.join(target, f'{name}.png'), optimize=True)
        print(name, crop.size)


if __name__ == '__main__':
    main()
