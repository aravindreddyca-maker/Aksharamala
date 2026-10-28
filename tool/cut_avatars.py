"""Split the six-avatar sheet (real alpha channel) into one PNG per avatar.

Run:  python -I tool/cut_avatars.py <avatar-sheet.webp|png>
Output: assets/images/avatars/<name>.png, 512x512 RGBA, subject centred.
Sheet order: row 1 lion, panda, unicorn; row 2 tiger, frog, robot.
Names match GameAvatar.options so saved profiles keep their avatar.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAMES = [['lion', 'panda', 'unicorn'], ['tiger', 'frog', 'robot']]
OUT = 512


def runs(idx, gap=8):
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
    alpha = np.array(sheet)[..., 3] > 16
    col_runs = runs(np.where(alpha.any(axis=0))[0])
    assert len(col_runs) == 3, f'expected 3 columns, found {col_runs}'
    target = os.path.join(ROOT, 'assets', 'images', 'avatars')
    os.makedirs(target, exist_ok=True)
    for c, (x0, x1) in enumerate(col_runs):
        col = alpha[:, x0 : x1 + 1]
        # Rows touch in projection; split where the column is emptiest.
        counts = col.sum(axis=1)
        lo, hi = sheet.height // 2 - 60, sheet.height // 2 + 60
        split = lo + int(np.argmin(counts[lo:hi]))
        for r, (y0, y1) in enumerate([(0, split), (split, sheet.height)]):
            sub = col[y0:y1]
            ys = np.where(sub.any(axis=1))[0]
            xs = np.where(sub.any(axis=0))[0]
            top, bottom = y0 + int(ys[0]), y0 + int(ys[-1]) + 1
            left, right = x0 + int(xs[0]), x0 + int(xs[-1]) + 1
            size = max(bottom - top, right - left) + 12
            cx, cy = (left + right) // 2, (top + bottom) // 2
            canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            crop = sheet.crop((left, top, right, bottom))
            canvas.paste(
                crop,
                ((size - crop.width) // 2, (size - crop.height) // 2),
                crop,
            )
            canvas.resize((OUT, OUT), Image.LANCZOS).save(
                os.path.join(target, f'{NAMES[r][c]}.png'), optimize=True
            )
    print('avatars written')


if __name__ == '__main__':
    main()
