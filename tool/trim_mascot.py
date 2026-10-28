"""Trim a transparent-background mascot to its outline and size it for the app.

Run:  python -I tool/trim_mascot.py <input.png|webp> <name> [max_height=768]
Output: assets/images/mascots/<name>.png (RGBA, trimmed with a small margin)
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    src, name = sys.argv[1], sys.argv[2]
    max_height = int(sys.argv[3]) if len(sys.argv) > 3 else 768
    im = Image.open(src).convert('RGBA')
    bbox = im.getchannel('A').point(lambda v: 255 if v > 16 else 0).getbbox()
    if not bbox:
        raise SystemExit('image has no visible pixels')
    pad = 6
    box = (
        max(0, bbox[0] - pad),
        max(0, bbox[1] - pad),
        min(im.width, bbox[2] + pad),
        min(im.height, bbox[3] + pad),
    )
    im = im.crop(box)
    if im.height > max_height:
        scale = max_height / im.height
        im = im.resize((round(im.width * scale), max_height), Image.LANCZOS)
    target = os.path.join(ROOT, 'assets', 'images', 'mascots')
    os.makedirs(target, exist_ok=True)
    im.save(os.path.join(target, f'{name}.png'), optimize=True)
    print(f'{name}: {im.size}')


if __name__ == '__main__':
    main()
