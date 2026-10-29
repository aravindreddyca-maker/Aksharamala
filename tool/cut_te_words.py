import sys
from PIL import Image, ImageFilter

src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGB')
names = ['cow', 'fly', 'squirrel', 'swing', 'five', 'camel']
xs = [12, 520, 1028]
ys = [12, 518]
W, H = 496, 494
KEEP = 380      # picture ends here; the painted word sits below
SIDE = 512
sheet = Image.new('RGB', (SIDE * 3, SIDE * 2), 'white')
for i, name in enumerate(names):
    x0, y0 = xs[i % 3], ys[i // 3]
    tile = im.crop((x0, y0, x0 + W, y0 + H))
    px = tile.load()
    # mask of the painted red letter, only inside the top-left corner
    mask = Image.new('L', (W, H), 0)
    mp = mask.load()
    for y in range(0, 160):
        for x in range(0, 185):
            r, g, b = px[x, y]
            if 200 <= r <= 245 and g < 14 and b < 14:
                mp[x, y] = 255
    mask = mask.filter(ImageFilter.MaxFilter(7))  # grow so anti-aliased edges go too
    mp = mask.load()
    for y in range(0, 160):
        for x in range(0, 185):
            if mp[x, y] or min(px[x, y]) > 205:
                px[x, y] = (255, 255, 255)
    body = tile.crop((8, 8, W - 8, KEEP))
    canvas = Image.new('RGB', (SIDE, SIDE), 'white')
    canvas.paste(body, ((SIDE - body.width) // 2, (SIDE - body.height) // 2))
    canvas.save(f'{out}/te_{name}.webp', 'WEBP', quality=88)
    sheet.paste(canvas, ((i % 3) * SIDE, (i // 3) * SIDE))
sheet.save(f'{out}/te_sheet_preview.png')
print('ok')


