"""Cut quiz pictures out of a sheet of label-free picture tiles.

The sheet is a 3x2 grid of rounded-square pictures sitting on a soft coloured
glow. Each tile is cropped just inside its rim and given its own rounded
corners (so none of the glow comes along). The app writes the word itself.

Run:  python -I tool/cut_quiz_cards.py <sheet.webp|png> name1,...,name6
Output: assets/images/quiz/<name>.png (RGBA, ~478 px square, rounded corners)

The tile boxes below are measured for the 1536x1024 sheet (columns left to
right, rows top to bottom). A sheet with a different layout needs new boxes.
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COLS = [(18, 496), (527, 1006), (1038, 1518)]
ROWS = [(16, 494), (522, 1001)]
RADIUS = 36  # px, at the source size
SS = 4  # supersampling for a smooth mask edge


def rounded_mask(size, radius):
    w, h = size
    big = Image.new('L', (w * SS, h * SS), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        (0, 0, w * SS - 1, h * SS - 1), radius=radius * SS, fill=255
    )
    return big.resize((w, h), Image.LANCZOS)


def main():
    sheet = Image.open(sys.argv[1]).convert('RGBA')
    names = sys.argv[2].split(',')
    assert len(names) == len(ROWS) * len(COLS)
    target = os.path.join(ROOT, 'assets', 'images', 'quiz')
    os.makedirs(target, exist_ok=True)
    for r, (y0, y1) in enumerate(ROWS):
        for c, (x0, x1) in enumerate(COLS):
            tile = sheet.crop((x0, y0, x1, y1))
            tile.putalpha(rounded_mask(tile.size, RADIUS))
            tile.save(
                os.path.join(target, f'{names[r * len(COLS) + c]}.png'),
                optimize=True,
            )
    print('quiz pictures written:', ', '.join(names))


if __name__ == '__main__':
    main()
