"""Cut the Aksharamala logo out of a sheet that paints a grey checkerboard where
it means "transparent".

The checkerboard is low-saturation mid-grey. Only grey that touches the sheet's
border counts as background, so the logo's own white letters and clouds (which
sit inside coloured shapes) stay. The edge is then eroded a hair and feathered.

Run:  python -I tool/cut_logo.py <logo.webp|png>
Output: assets/images/brand/logo.png (RGBA, trimmed, 900 px wide)
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    im = Image.open(sys.argv[1]).convert('RGB')
    rgb = np.asarray(im).astype(np.float32) / 255
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    candidate = (sat < 0.10) & (mx > 0.48) & (mx < 0.86)
    candidate = ndimage.binary_closing(candidate, iterations=1)
    # The sheet has a thin coloured line on its very edge, so seed from a band
    # a few pixels in rather than from the outermost row.
    seeds = np.zeros_like(candidate)
    band = 12
    seeds[:band, :] = seeds[-band:, :] = seeds[:, :band] = seeds[:, -band:] = True
    background = ndimage.binary_propagation(seeds & candidate, mask=candidate)
    # Take the thin bright squares of the checker too: dilate into near-white
    # pixels that touch confirmed background (but never into saturated colour).
    bright = (sat < 0.10) & (mx >= 0.86)
    for _ in range(3):
        grow = ndimage.binary_dilation(background, iterations=2) & bright
        if not grow.any():
            break
        background |= grow
    # Drop the sheet's own edge line, or it would fence the background in and
    # hole-filling below would turn the whole checkerboard back into logo.
    background[:band, :] = background[-band:, :] = True
    background[:, :band] = background[:, -band:] = True
    fg = ~background
    fg = ndimage.binary_fill_holes(fg)
    fg = ndimage.binary_opening(fg, iterations=2)
    labels, n = ndimage.label(fg)
    if n > 1:
        sizes = ndimage.sum(fg, labels, range(1, n + 1))
        fg = labels == (1 + int(np.argmax(sizes)))
    fg = ndimage.binary_erosion(fg, iterations=2)
    alpha = Image.fromarray((fg * 255).astype('uint8')).filter(
        ImageFilter.GaussianBlur(1.3)
    )
    out = im.convert('RGBA')
    out.putalpha(alpha)
    bbox = alpha.point(lambda v: 255 if v > 24 else 0).getbbox()
    out = out.crop(bbox)
    out = out.resize((900, round(900 * out.height / out.width)), Image.LANCZOS)
    target = os.path.join(ROOT, 'assets', 'images', 'brand')
    os.makedirs(target, exist_ok=True)
    out.save(os.path.join(target, 'logo.png'), optimize=True)
    print('logo', out.size)


if __name__ == '__main__':
    main()
