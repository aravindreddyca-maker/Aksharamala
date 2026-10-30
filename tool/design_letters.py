"""Design the English capital-letter stroke templates (A-Z).

    python tool/design_letters.py [preview_dir]

Writes lib/src/handwriting/letter_templates.dart. With a preview_dir it also
draws every letter with its numbered strokes, so the order and direction can
be looked at. These are simple school-style capitals drawn in-house. They are
NOT teacher-verified (strokeOrderVerified stays false), so the app gives
feedback but awards no handwriting mastery for them.

Coordinates are the unit square, x to the right, y DOWN, 0.1-0.9 used.
"""

import math
import os
import sys


def line(*pts, per=6):
    out = []
    for a, b in zip(pts, pts[1:]):
        for k in range(per):
            t = k / per
            out.append((round(a[0] + (b[0] - a[0]) * t, 3), round(a[1] + (b[1] - a[1]) * t, 3)))
    out.append(pts[-1])
    return out


def smooth(pts, per=7):
    out = []
    P = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(per):
            t = k / per
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t * t + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t ** 3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t * t + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t ** 3)
            out.append((round(x, 3), round(y, 3)))
    out.append(pts[-1])
    return out


def arc(cx, cy, rx, ry, a0, a1, n=24):
    """Ellipse arc, angles in degrees, 0 = right, 90 = down (screen y)."""
    return [(round(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * k / n)), 3),
             round(cy + ry * math.sin(math.radians(a0 + (a1 - a0) * k / n)), 3)) for k in range(n + 1)]


L = {}
L['A'] = [line((.5, .1), (.2, .9)), line((.5, .1), (.8, .9)), line((.31, .6), (.69, .6))]
L['B'] = [line((.25, .1), (.25, .9)),
          line((.25, .1), (.5, .1)) + smooth([(.5, .1), (.68, .16), (.72, .3), (.6, .44), (.5, .5), (.25, .5)])[1:],
          line((.25, .5), (.55, .5)) + smooth([(.55, .5), (.74, .56), (.78, .72), (.64, .86), (.5, .9), (.25, .9)])[1:]]
L['C'] = [arc(.5, .5, .3, .4, -40, -320)]
L['D'] = [line((.25, .1), (.25, .9)),
          line((.25, .1), (.45, .1)) + smooth([(.45, .1), (.68, .2), (.76, .5), (.68, .8), (.45, .9), (.25, .9)])[1:]]
L['E'] = [line((.28, .1), (.28, .9)), line((.28, .1), (.75, .1)), line((.28, .5), (.68, .5)), line((.28, .9), (.75, .9))]
L['F'] = [line((.28, .1), (.28, .9)), line((.28, .1), (.75, .1)), line((.28, .5), (.68, .5))]
L['G'] = [arc(.5, .5, .3, .4, -40, -320)[:-1] + smooth([(.8, .55), (.78, .7)])[:1] if False else arc(.5, .5, .3, .4, -40, -330),
          line((.52, .55), (.8, .55))]
L['H'] = [line((.25, .1), (.25, .9)), line((.75, .1), (.75, .9)), line((.25, .5), (.75, .5))]
L['I'] = [line((.5, .1), (.5, .9))]
L['J'] = [smooth([(.62, .1), (.62, .6), (.58, .8), (.45, .9), (.3, .85), (.22, .7)])]
L['K'] = [line((.27, .1), (.27, .9)), line((.75, .1), (.27, .55)), line((.42, .43), (.78, .9))]
L['L'] = [line((.27, .1), (.27, .9)), line((.27, .9), (.75, .9))]
L['M'] = [line((.2, .9), (.2, .1)), line((.2, .1), (.5, .65)), line((.5, .65), (.8, .1)), line((.8, .1), (.8, .9))]
L['N'] = [line((.25, .9), (.25, .1)), line((.25, .1), (.75, .9)), line((.75, .9), (.75, .1))]
L['O'] = [arc(.5, .5, .3, .4, -90, -450, 36)]
L['P'] = [line((.27, .1), (.27, .9)),
          line((.27, .1), (.5, .1)) + smooth([(.5, .1), (.7, .16), (.74, .32), (.62, .46), (.5, .5), (.27, .5)])[1:]]
L['Q'] = [arc(.5, .48, .3, .38, -90, -450, 36), line((.55, .66), (.8, .92))]
L['R'] = [line((.27, .1), (.27, .9)),
          line((.27, .1), (.5, .1)) + smooth([(.5, .1), (.7, .16), (.74, .3), (.62, .44), (.5, .48), (.27, .48)])[1:],
          line((.5, .48), (.76, .9))]
L['S'] = [smooth([(.72, .22), (.62, .12), (.45, .1), (.3, .17), (.27, .3), (.38, .42), (.55, .5), (.7, .6), (.74, .74), (.66, .86), (.5, .9), (.34, .86), (.25, .76)])]
L['T'] = [line((.2, .1), (.8, .1)), line((.5, .1), (.5, .9))]
L['U'] = [smooth([(.25, .1), (.25, .6), (.3, .8), (.5, .9), (.7, .8), (.75, .6)]) + line((.75, .6), (.75, .1))[1:]]
L['V'] = [line((.2, .1), (.5, .9)), line((.5, .9), (.8, .1))]
L['W'] = [line((.1, .1), (.3, .9)), line((.3, .9), (.5, .1)), line((.5, .1), (.7, .9)), line((.7, .9), (.9, .1))]
L['X'] = [line((.2, .1), (.8, .9)), line((.8, .1), (.2, .9))]
L['Y'] = [line((.2, .1), (.5, .5)), line((.8, .1), (.5, .5)), line((.5, .5), (.5, .9))]
L['Z'] = [line((.22, .1), (.78, .1)), line((.78, .1), (.22, .9)), line((.22, .9), (.78, .9))]


def dart():
    o = ['/// Stroke templates for the English capital letters A-Z.', '///',
         '/// Drawn in-house as simple school-style capitals (see tool/design_letters.py)',
         '/// and checked only by eye, so `strokeOrderVerified` is false: a teacher must',
         '/// confirm the stroke order and direction before any child can earn',
         '/// handwriting mastery. Regenerate with the design tool, do not edit by hand.',
         'library;', '', "import 'stroke_template.dart';", '',
         'Stroke _s(List<double> xy) => [for (var i = 0; i < xy.length; i += 2) Pt(xy[i], xy[i + 1])];', '',
         '/// Capital letter -> template.', 'final Map<String, StrokeTemplate> letterTemplates = {']
    for k in sorted(L):
        o += [f"  '{k}': StrokeTemplate(", f"    glyph: '{k}',", "    script: 'english',",
              "    source: 'hand-drawn in-house, unverified',", '    strokes: [']
        for s in L[k]:
            o.append('      _s([%s]),' % ', '.join(('%g' % v) for p in s for v in p))
        o += ['    ],', '  ),']
    o.append('};')
    return '\n'.join(o) + '\n'


def preview(d):
    from PIL import Image, ImageDraw
    W = 150
    sheet = Image.new('RGB', (W * 9, W * 3), 'white')
    dr = ImageDraw.Draw(sheet)
    cols = ['#d33', '#36c', '#292', '#c80']
    for i, k in enumerate(sorted(L)):
        ox, oy = (i % 9) * W, (i // 9) * W
        dr.rectangle([ox + 3, oy + 3, ox + W - 3, oy + W - 3], outline='#ccc')
        for si, s in enumerate(L[k]):
            pts = [(ox + 10 + x * (W - 20), oy + 10 + y * (W - 20)) for x, y in s]
            dr.line(pts, fill=cols[si % 4], width=4)
            x0, y0 = pts[0]
            dr.ellipse([x0 - 7, y0 - 7, x0 + 7, y0 + 7], fill=cols[si % 4])
            dr.text((x0 - 3, y0 - 5), str(si + 1), fill='white')
        dr.text((ox + 6, oy + 5), k, fill='black')
    sheet.save(os.path.join(d, 'letters_preview.png'))


if __name__ == '__main__':
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(root, 'lib', 'src', 'handwriting', 'letter_templates.dart'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(dart())
    if len(sys.argv) > 1:
        preview(sys.argv[1])
    print('letters', len(L))
