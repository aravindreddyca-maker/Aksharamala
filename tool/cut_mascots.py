"""Cut five mascots (boy, elephant, tiger, girl, parrot) out of the sheet.

The sheet paints a grey checkerboard where it means "transparent", so a plain
flood fill leaves speckle. Instead: treat low-saturation bright pixels as
background, take everything else as the character, close small gaps, fill the
enclosed holes (white robot body, eye whites), keep the single biggest shape
and feather the edge.

Run:  python -I tool/cut_mascots.py <composite-sheet.webp|png>
Output: assets/images/mascots/<name>.png (RGBA, ~2x the sheet's pixels)
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# name -> box (x0, y0, x1, y1) on the 1672x941 sheet; y0 skips the emblem row.
BOXES = {
    'boy': (40, 352, 285, 615),
    'elephant': (280, 352, 575, 615),
    'tiger': (595, 352, 840, 615),
    'girl': (845, 352, 1095, 615),
    'parrot': (1090, 352, 1400, 615),
    # The robot is left out: its white body is indistinguishable from the
    # sheet's painted checkerboard, so it cannot be cut out cleanly.
}
SCALE = 2


def cut(sheet, box):
    im = sheet.crop(box)
    im = im.resize((im.width * SCALE, im.height * SCALE), Image.LANCZOS)
    rgb = np.asarray(im).astype(np.float32) / 255
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    candidate = (sat < 0.17) & (mx > 0.70)
    # Only background that connects to the crop's border counts, so white
    # areas fenced in by the character's outline (robot body) stay.
    seeds = np.zeros_like(candidate)
    seeds[0, :] = seeds[-1, :] = seeds[:, 0] = seeds[:, -1] = True
    background = ndimage.binary_propagation(seeds & candidate, mask=candidate)
    fg = ndimage.binary_closing(~background, iterations=2)
    fg = ndimage.binary_fill_holes(fg)
    fg = ndimage.binary_opening(fg, iterations=2)
    labels, n = ndimage.label(fg)
    if n > 1:
        sizes = ndimage.sum(fg, labels, range(1, n + 1))
        fg = labels == (1 + int(np.argmax(sizes)))
    fg = ndimage.binary_erosion(fg, iterations=1)
    alpha = Image.fromarray((fg * 255).astype('uint8')).filter(
        ImageFilter.GaussianBlur(1.2)
    )
    out = im.convert('RGBA')
    out.putalpha(alpha)
    bbox = alpha.point(lambda v: 255 if v > 24 else 0).getbbox()
    return out.crop(bbox) if bbox else out


def main():
    sheet = Image.open(sys.argv[1]).convert('RGB')
    target = os.path.join(ROOT, 'assets', 'images', 'mascots')
    os.makedirs(target, exist_ok=True)
    for name, box in BOXES.items():
        cut(sheet, box).save(os.path.join(target, f'{name}.png'), optimize=True)
    print('mascots written')


if __name__ == '__main__':
    main()
