"""Generate the Android launcher icons from one square app-icon PNG.

Run:  python -I tool/make_launcher_icons.py <app-icon.png|webp>
Writes into android/app/src/main/res:
  mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png          legacy icon (48-192 px)
  mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher_foreground.png  adaptive layer (108 dp)
  mipmap-anydpi-v26/ic_launcher.xml                    adaptive icon
  values/ic_launcher_background.xml                    adaptive background colour

The artwork has rounded, transparent corners. Legacy icons keep it as drawn.
For the adaptive icon the artwork is centre-cropped to 80% so the layer is
fully opaque edge to edge (the launcher then applies its own round or squircle
mask); the face stays inside the 66% safe zone.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
# density -> (legacy px, adaptive layer px)
DENSITIES = {
    'mdpi': (48, 108),
    'hdpi': (72, 162),
    'xhdpi': (96, 216),
    'xxhdpi': (144, 324),
    'xxxhdpi': (192, 432),
}


def restore_corner_alpha(art):
    """Some exports flatten the rounded corners to solid black. If the image
    has no transparency, make the border-connected black real transparency."""
    if art.getchannel('A').getextrema()[0] < 250:
        return art
    rgb = np.asarray(art.convert('RGB'))
    dark = rgb.max(axis=2) < 24
    seeds = np.zeros_like(dark)
    seeds[0, :] = seeds[-1, :] = seeds[:, 0] = seeds[:, -1] = True
    outside = ndimage.binary_propagation(seeds & dark, mask=dark)
    outside = ndimage.binary_dilation(outside, iterations=1)
    alpha = Image.fromarray(((~outside) * 255).astype('uint8')).filter(
        ImageFilter.GaussianBlur(1.0)
    )
    out = art.copy()
    out.putalpha(alpha)
    return out


def main():
    art = restore_corner_alpha(Image.open(sys.argv[1]).convert('RGBA'))
    side = min(art.size)
    art = art.crop(((art.width - side) // 2, (art.height - side) // 2,
                    (art.width + side) // 2, (art.height + side) // 2))
    inset = round(side * 0.10)
    cropped = art.crop((inset, inset, side - inset, side - inset))
    assert cropped.getchannel('A').getextrema()[0] > 240, 'crop still has transparent corners'
    # Background colour = the artwork's own sky (upper-left, clear of the mane).
    r, g, b, _ = art.getpixel((round(side * .26), round(side * .09)))
    colour = f'#{r:02X}{g:02X}{b:02X}'
    for name, (legacy, layer) in DENSITIES.items():
        folder = os.path.join(RES, f'mipmap-{name}')
        os.makedirs(folder, exist_ok=True)
        art.resize((legacy, legacy), Image.LANCZOS).save(
            os.path.join(folder, 'ic_launcher.png'), optimize=True
        )
        cropped.resize((layer, layer), Image.LANCZOS).save(
            os.path.join(folder, 'ic_launcher_foreground.png'), optimize=True
        )
    any_dir = os.path.join(RES, 'mipmap-anydpi-v26')
    os.makedirs(any_dir, exist_ok=True)
    with open(os.path.join(any_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n'
        )
    with open(os.path.join(RES, 'values', 'ic_launcher_background.xml'), 'w',
              encoding='utf-8') as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources>\n'
            f'    <color name="ic_launcher_background">{colour}</color>\n'
            '</resources>\n'
        )
    print('launcher icons written; background', colour)


if __name__ == '__main__':
    main()
