"""Split a transparent icon sheet laid out as a grid into one PNG per icon.

Run:  python -I tool/cut_icon_grid.py <sheet.webp|png> <out-folder> <rows>x<cols> name1,name2,...
Example (rewards, row by row):
  python -I tool/cut_icon_grid.py rewards.webp assets/images/rewards 2x3 \
      star,trophy,crown,medal,gem,gift
Output: <out-folder>/<name>.png, 512x512 RGBA, each icon centred with a margin.
Columns and rows are found from gaps in the alpha channel; icons that touch
the neighbouring row are split where the sheet is emptiest.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
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
    sheet_path, out_dir, grid, names = sys.argv[1:5]
    rows, cols = (int(n) for n in grid.lower().split('x'))
    names = names.split(',')
    assert len(names) == rows * cols, 'need one name per cell'
    sheet = Image.open(sheet_path).convert('RGBA')
    alpha = np.array(sheet)[..., 3] > 16
    col_runs = runs(np.where(alpha.any(axis=0))[0])
    assert len(col_runs) == cols, f'expected {cols} columns, found {col_runs}'
    # Row boundaries: the emptiest horizontal band near each equal split.
    counts = alpha.sum(axis=1)
    bounds = [0]
    for r in range(1, rows):
        centre = round(sheet.height * r / rows)
        lo, hi = centre - 60, centre + 60
        bounds.append(lo + int(np.argmin(counts[lo:hi])))
    bounds.append(sheet.height)
    target = os.path.join(ROOT, out_dir) if not os.path.isabs(out_dir) else out_dir
    os.makedirs(target, exist_ok=True)
    for c, (x0, x1) in enumerate(col_runs):
        for r in range(rows):
            y0, y1 = bounds[r], bounds[r + 1]
            sub = alpha[y0:y1, x0 : x1 + 1]
            ys = np.where(sub.any(axis=1))[0]
            xs = np.where(sub.any(axis=0))[0]
            top, bottom = y0 + int(ys[0]), y0 + int(ys[-1]) + 1
            left, right = x0 + int(xs[0]), x0 + int(xs[-1]) + 1
            size = max(bottom - top, right - left) + 16
            canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            crop = sheet.crop((left, top, right, bottom))
            canvas.paste(
                crop, ((size - crop.width) // 2, (size - crop.height) // 2), crop
            )
            name = names[r * cols + c]
            canvas.resize((OUT, OUT), Image.LANCZOS).save(
                os.path.join(target, f'{name}.png'), optimize=True
            )
    print('icons written:', ', '.join(names))


if __name__ == '__main__':
    main()
