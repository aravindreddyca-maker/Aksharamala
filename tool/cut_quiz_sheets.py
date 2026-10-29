"""Cut the Telugu, Hindi, Tamil and Number Galaxy quiz sheets, and the story covers.

Each sheet is a grid of label-free pictures separated by thin white lines (the
Telugu sheet has rounded tiles with transparent gaps). Tiles are cropped just
inside their lines, given rounded corners, and saved as WebP (small and sharp).
Story covers are 16:9 scenes, resized to 1280 px wide.

Run:  python -I tool/cut_quiz_sheets.py <folder-holding-the-source-images>
Source names expected: 15..18.webp covers (butterfly, kite, parrot, mango),
19 Hindi, 20 Telugu, 21 Tamil, 22 Number Galaxy sheets.
Output: assets/images/quiz/<id>.webp and assets/images/stories/<id>.webp
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RADIUS = 34
SS = 4

# sheet file -> (column spans, row spans, names row by row). Spans are pixel
# ranges just inside the white separator lines of the 1672x941 sheet.
SHEETS = {
    19: ([(4, 551), (562, 1110), (1121, 1668)], [(4, 466), (477, 937)],
         ['hi_pomegranate', 'hi_lotus', 'hi_house',
          'hi_kite_blue', 'hi_kite_red', 'hi_kite_green']),
    20: ([(14, 551), (566, 1104), (1120, 1658)], [(10, 460), (474, 922)],
         ['te_amma', 'te_house', 'te_elephant',
          'te_pen', 'te_school', 'te_fruit']),
    21: ([(4, 553), (564, 1107), (1118, 1668)], [(4, 464), (475, 937)],
         ['ta_mother', 'ta_leaf', 'ta_swing',
          'ta_flower', 'ta_house', 'ta_stone']),
    22: ([(4, 550), (561, 1119), (1130, 1668)], [(4, 937)],
         ['num_rocket', 'num_moon', 'num_crystal']),
}
COVERS = {15: 'butterfly', 16: 'kite', 17: 'parrot', 18: 'mango'}


def rounded(tile):
    w, h = tile.size
    big = Image.new('L', (w * SS, h * SS), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        (0, 0, w * SS - 1, h * SS - 1), radius=RADIUS * SS, fill=255
    )
    tile = tile.convert('RGBA')
    tile.putalpha(big.resize((w, h), Image.LANCZOS))
    return tile


def main():
    src = sys.argv[1]
    quiz = os.path.join(ROOT, 'assets', 'images', 'quiz')
    stories = os.path.join(ROOT, 'assets', 'images', 'stories')
    os.makedirs(quiz, exist_ok=True)
    os.makedirs(stories, exist_ok=True)
    for number, (cols, rows, names) in SHEETS.items():
        sheet = Image.open(os.path.join(src, f'{number}.webp')).convert('RGB')
        i = 0
        for y0, y1 in rows:
            for x0, x1 in cols:
                rounded(sheet.crop((x0, y0, x1, y1))).save(
                    os.path.join(quiz, f'{names[i]}.webp'), quality=88
                )
                i += 1
    for number, name in COVERS.items():
        cover = Image.open(os.path.join(src, f'{number}.webp')).convert('RGB')
        cover = cover.resize((1280, round(1280 * cover.height / cover.width)),
                             Image.LANCZOS)
        cover.save(os.path.join(stories, f'{name}.webp'), quality=84)
    print('quiz sheets and story covers written')


if __name__ == '__main__':
    main()
