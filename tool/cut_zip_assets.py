"""Cut the approved mascots and reward badges out of the concept-art crops.

The crops in Aksharamala_Image_Assets.zip sit on a white background. This
flood-fills the white from the border (so white inside an object, such as a
ball's patches or an eye highlight, survives), erodes one pixel to remove the
white fringe, and writes RGBA PNGs.

Run:  python -I tool/cut_zip_assets.py <extracted-zip-folder>
Output: assets/images/mascots/*.png, assets/images/rewards/*.png
"""
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEEP = {
    'mascots': ['boy', 'girl', 'elephant', 'tiger', 'parrot'],
    'rewards': ['star', 'trophy', 'crown', 'medal', 'gem', 'gift'],
}
SCALE = 3  # upscale first so the cut edge is smooth, not stair-stepped


def cut(path):
    src = Image.open(path).convert('RGB')
    big = src.resize((src.width * SCALE, src.height * SCALE), Image.LANCZOS)
    marker = (255, 0, 255)
    work = big.copy()
    w, h = work.size
    for x in range(0, w, 4):
        for y in (0, h - 1):
            if min(work.getpixel((x, y))) > 225:
                ImageDraw.floodfill(work, (x, y), marker, thresh=38)
    for y in range(0, h, 4):
        for x in (0, w - 1):
            if min(work.getpixel((x, y))) > 225:
                ImageDraw.floodfill(work, (x, y), marker, thresh=38)
    bg = Image.new('RGB', (w, h), marker)
    is_bg = ImageChops.difference(work, bg).convert('L').point(
        lambda v: 255 if v == 0 else 0
    )
    alpha = ImageChops.invert(is_bg)
    alpha = alpha.filter(ImageFilter.MinFilter(5)).filter(
        ImageFilter.GaussianBlur(1.4)
    )
    out = big.convert('RGBA')
    out.putalpha(alpha)
    box = alpha.point(lambda v: 255 if v > 24 else 0).getbbox()
    if box:
        pad = 6
        out = out.crop(
            (
                max(0, box[0] - pad),
                max(0, box[1] - pad),
                min(w, box[2] + pad),
                min(h, box[3] + pad),
            )
        )
    return out


def main():
    zip_dir = sys.argv[1]
    for folder, names in KEEP.items():
        target = os.path.join(ROOT, 'assets', 'images', folder)
        os.makedirs(target, exist_ok=True)
        for name in names:
            cut(os.path.join(zip_dir, folder, f'{name}.png')).save(
                os.path.join(target, f'{name}.png'), optimize=True
            )
    print('cut-outs written')


if __name__ == '__main__':
    main()
