import sys, os, json, csv
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

d = sys.argv[1]
out = sys.argv[2]
rows = []
for f in sorted(os.listdir(d)):
    if not f.lower().endswith(('.webp', '.png')):
        continue
    p = os.path.join(d, f)
    im = Image.open(p)
    fmt = im.format
    w, h = im.size
    mode = im.mode
    r = dict(file=f, format=fmt, size=f'{w}x{h}', mode=mode, kb=round(os.path.getsize(p) / 1024, 1))
    problems = []
    if fmt != 'WEBP':
        problems.append('not WebP')
    if (w, h) != (512, 512):
        problems.append('not 512x512')
    if 'A' not in mode:
        problems.append('no alpha channel')
        r.update(transparent_pct=0, margin='', coverage='', checker='')
        r['problems'] = '; '.join(problems)
        rows.append(r)
        continue
    a = np.asarray(im.convert('RGBA')).astype(np.float32)
    al = a[..., 3]
    tr = float((al < 10).mean())
    r['transparent_pct'] = round(100 * tr, 1)
    if tr < 0.03:
        problems.append('almost no transparency (opaque background?)')
    corners = [al[:12, :12], al[:12, -12:], al[-12:, :12], al[-12:, -12:]]
    if any(c.mean() > 10 for c in corners):
        problems.append('corner not transparent')
    ys, xs = np.where(al > 24)
    if len(xs):
        x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
        m = dict(l=x0, t=y0, r=w - 1 - x1, b=h - 1 - y1)
        r['margin'] = f"L{m['l']} T{m['t']} R{m['r']} B{m['b']}"
        mn = min(m.values())
        if mn < 0.04 * w:
            problems.append(f'margin under 4% ({mn}px)')
        cx = (x0 + x1) / 2 / w
        cy = (y0 + y1) / 2 / h
        if abs(cx - .5) > .06 or abs(cy - .5) > .08:
            problems.append(f'off-centre ({cx:.2f},{cy:.2f})')
        cov = max((x1 - x0) / w, (y1 - y0) / h)
        r['coverage'] = f'{cov:.2f}'
        if cov < .45:
            problems.append('subject too small')
    else:
        r['margin'] = ''
        r['coverage'] = '0'
        problems.append('empty')
    # a baked checkerboard shows as opaque, colourless, alternating squares
    rgb = a[..., :3]
    sat = rgb.max(2) - rgb.min(2)
    opaque_grey = (al > 200) & (sat < 8) & (rgb.mean(2) > 190)
    # look for alternating blocks along rows inside the opaque-grey area
    chk = 0.0
    if opaque_grey.sum() > 2000:
        lum = rgb.mean(2)
        dx = np.abs(np.diff(lum, axis=1)) > 18
        dy = np.abs(np.diff(lum, axis=0)) > 18
        both = opaque_grey[:, 1:] & opaque_grey[:-1, :][:, :1].repeat(w - 1, 1) if False else opaque_grey[:, 1:]
        chk = float((dx & both).sum() / max(both.sum(), 1))
    r['checker'] = f'{chk:.3f}'
    if chk > 0.12:
        problems.append('possible baked checkerboard')
    # white/grey fringe on soft edges
    edge = (al > 10) & (al < 245)
    if edge.sum() > 200:
        fr = rgb[edge]
        light = (fr.min(1) > 225).mean()
        r['fringe_light_pct'] = round(100 * float(light), 1)
        if light > 0.55:
            problems.append('light halo on edges')
    r['problems'] = '; '.join(problems)
    rows.append(r)
cols = ['file', 'format', 'size', 'mode', 'kb', 'transparent_pct', 'margin', 'coverage', 'checker', 'fringe_light_pct', 'problems']
with open(out, 'w', newline='', encoding='utf-8') as fh:
    w_ = csv.DictWriter(fh, fieldnames=cols, extrasaction='ignore')
    w_.writeheader()
    w_.writerows(rows)
bad = [r for r in rows if r.get('problems')]
print('files', len(rows), 'with problems', len(bad))
for r in bad:
    print(r['file'], '|', r['size'], r['mode'], '|', r['problems'])
