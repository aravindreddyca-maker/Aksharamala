"""Generate the original transparent world emblems.

Run:  python tool/make_home_assets.py
Output: assets/images/emblems/<world>.png (256x256)
(star() is kept for reference; the shipped star is rewards/star.png.)
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = 'C:/Windows/Fonts'
SIZE = 256
SS = 3  # supersampling for smooth edges

# id -> (glyph, light colour, dark colour, font file, font index)
WORLDS = {
    'english': ('A', (0x5C, 0xCB, 0x78), (0x17, 0x7A, 0x45), 'arialbd.ttf', 0),
    'telugu': ('అ', (0xFF, 0x9D, 0x55), (0xC9, 0x4E, 0x2B), 'Nirmala.ttc', 1),
    'hindi': ('अ', (0xFF, 0xD1, 0x5C), (0xB8, 0x74, 0x00), 'Nirmala.ttc', 1),
    'tamil': ('அ', (0xEF, 0x72, 0xA8), (0xA5, 0x2C, 0x68), 'Nirmala.ttc', 1),
    'numbers': ('123', (0x8B, 0x7C, 0xF6), (0x4B, 0x3D, 0xBA), 'arialbd.ttf', 0),
}


def gradient_disc(size, light, dark):
    """Vertical gradient clipped to a circle, on a transparent canvas."""
    grad = Image.new('RGBA', (size, size))
    px = grad.load()
    for y in range(size):
        t = y / (size - 1)
        c = tuple(int(light[i] + (dark[i] - light[i]) * t) for i in range(3))
        for x in range(size):
            px[x, y] = c + (255,)
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(grad, (0, 0), mask)
    return out


def emblem(glyph, light, dark, font_file, font_index):
    s = SIZE * SS
    canvas = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    margin = int(s * 0.05)
    # soft drop shadow
    shadow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse(
        (margin, margin + int(s * 0.03), s - margin, s - margin + int(s * 0.03)),
        fill=(0, 0, 0, 110),
    )
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(s * 0.02)))
    # white ring + gradient body
    d = ImageDraw.Draw(canvas)
    d.ellipse((margin, margin, s - margin, s - margin), fill=(255, 255, 255, 255))
    ring = int(s * 0.045)
    inner = s - 2 * (margin + ring)
    body = gradient_disc(inner, light, dark)
    canvas.paste(body, (margin + ring, margin + ring), body)
    # glossy highlight
    gloss = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).ellipse(
        (s * 0.22, s * 0.13, s * 0.78, s * 0.47), fill=(255, 255, 255, 60)
    )
    canvas = Image.alpha_composite(canvas, gloss)
    # glyph, centred, with a dark under-shadow for contrast
    path = f'{FONTS}/{font_file}'
    px_size = int(s * (0.34 if len(glyph) > 1 else 0.5))
    font = ImageFont.truetype(path, px_size, index=font_index)
    d = ImageDraw.Draw(canvas)
    box = d.textbbox((0, 0), glyph, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    x = (s - w) / 2 - box[0]
    y = (s - h) / 2 - box[1] + s * 0.01
    d.text((x, y + s * 0.012), glyph, font=font, fill=(0, 0, 0, 90))
    d.text((x, y), glyph, font=font, fill=(255, 255, 255, 255))
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def star():
    s = SIZE * SS
    cx = cy = s / 2
    outer, inner_r = s * 0.46, s * 0.2
    pts = []
    for i in range(10):
        r = outer if i % 2 == 0 else inner_r
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a) + s * 0.02))
    canvas = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(canvas).polygon(pts, fill=(0xB8, 0x74, 0x00, 255))
    body = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.polygon(pts, fill=(0xFF, 0xD8, 0x5C, 255))
    # lighter top half for depth
    top = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(top).polygon(pts, fill=(0xFF, 0xF0, 0xA0, 255))
    cut = Image.new('L', (s, s), 0)
    ImageDraw.Draw(cut).rectangle((0, 0, s, int(s * 0.42)), fill=255)
    body.paste(top, (0, 0), cut)
    # inset: shrink body slightly so the darker polygon forms an outline
    shrink = int(s * 0.03)
    body = body.crop((shrink, shrink, s - shrink, s - shrink)).resize((s, s), Image.LANCZOS)
    canvas = Image.alpha_composite(canvas, body)
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    emblem_dir = os.path.join(ROOT, 'assets', 'images', 'emblems')
    os.makedirs(emblem_dir, exist_ok=True)
    for world_id, (glyph, light, dark, font_file, idx) in WORLDS.items():
        emblem(glyph, light, dark, font_file, idx).save(
            os.path.join(emblem_dir, f'{world_id}.png'), optimize=True
        )
    print('assets written')


if __name__ == '__main__':
    main()
