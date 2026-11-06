"""Builds audit/CHATGPT_ARTWORK_REQUESTS.csv and audit/LESSON_ARTWORK_MAP.csv.

Sources (all existing records in the repo):
  - audit/ALPHABET_PICTURE_REQUIREMENTS.csv        rows with status 'needed'
  - audit/AGE_5_6_PRODUCTION_ARTWORK_SPEC.md       table rows not yet integrated
  - audit/AGE_5_6_ASSET_MANIFEST.csv               lesson ids of missing images
  - content/teaching/pilot_teaching_plans.json     review.assets_missing
Run: python -X utf8 -I tool/build_artwork_requests.py
"""
import csv
import json
import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HEAD = ['Asset ID', 'Concept', 'English description', 'Learning world', 'Level',
        'Referencing lesson IDs', 'Required dimensions', 'Transparency requirement',
        'Suggested filename', 'Asset status', 'Priority']
STYLE = ('Polished soft 3D children\'s educational illustration, one immediately '
         'recognizable subject, centered, entire subject visible, generous '
         'transparent margin, soft studio light, friendly look; no text, letters, '
         'numbers, border, watermark or background scene.')

rows = OrderedDict()   # asset id -> dict
lesson_map = []        # (lesson id, asset id)


def add(asset_id, concept, desc, world, level, lessons, filename, status, priority):
    r = rows.get(asset_id)
    if r:
        r['lessons'] = sorted(set(r['lessons']) | set(lessons))
        return
    rows[asset_id] = dict(concept=concept, desc=desc, world=world, level=level,
                          lessons=sorted(set(lessons)), filename=filename,
                          status=status, priority=priority)


# 1. alphabet words still needed
for r in csv.DictReader(open(ROOT / 'audit/ALPHABET_PICTURE_REQUIREMENTS.csv', encoding='utf-8-sig')):
    if r['status'] != 'needed':
        continue
    lang = r['language']
    meaning = r['meaning'].strip()
    slug = re.sub(r'[^a-z0-9]+', '-', meaning.lower()).strip('-')
    aid = f'alpha-{slug}'
    prefix = {'english': '', 'hindi': 'hi_', 'tamil': 'ta_', 'telugu': 'te_'}[lang]
    add(aid, f'{meaning} ({r["word"]})',
        f'{STYLE} Subject: {meaning}.', lang, 1,
        [f'alphabet:{lang}:{r["letter"]}'], f'assets/images/quiz/{prefix}{slug}.webp',
        'needed', 'P1 - Level 1 letters')

# 2. age 5-6 spec rows that are not yet integrated
spec = (ROOT / 'audit/AGE_5_6_PRODUCTION_ARTWORK_SPEC.md').read_text(encoding='utf-8')
for line in spec.splitlines():
    if not line.startswith('| `'):
        continue
    cells = [c.strip() for c in line.strip().strip('|').split('|')]
    if len(cells) < 5:
        continue
    status = cells[-1]
    if re.search(r'verified|Existing|Pack WebP|New WebP', status):
        continue
    aid_file = cells[0].replace('`', '').split('/')
    aid = aid_file[0].strip()
    fn = aid_file[1].strip() if len(aid_file) > 1 else aid + '.webp'
    if len(cells) >= 6:
        english, focus, lesson_cell = cells[1], cells[3], cells[4]
    else:
        english, focus, lesson_cell = cells[1], cells[2], cells[3]
    lessons = [x.strip() for x in lesson_cell.split(';') if x.strip()]
    lang = lessons[0].split('-')[0] if lessons else 'mixed'
    add(aid, english, f'{STYLE} {focus}', lang, 2, lessons,
        f'assets/images/age56/{fn}', 'needed', 'P2 - Level 2 lessons')

# 3. manifest lessons whose images are missing (lesson mapping)
for r in csv.DictReader(open(ROOT / 'audit/AGE_5_6_ASSET_MANIFEST.csv', encoding='utf-8-sig')):
    if r['missing_images']:
        for a, v in rows.items():
            if r['lesson_id'] in v['lessons']:
                lesson_map.append((r['lesson_id'], a))

# 4. pilot plans
plans = json.load(open(ROOT / 'content/teaching/pilot_teaching_plans.json', encoding='utf-8'))
for l in plans['lessons']:
    for m in l.get('review', {}).get('assets_missing', []):
        add('pilot-' + re.sub(r'\W+', '-', m.lower()), m, f'{STYLE} {m}', l['world'],
            l['level'], [l['lesson_id']], f'assets/images/quiz/{m}.webp', 'needed',
            'P1 - pilot lessons')

with open(ROOT / 'audit/CHATGPT_ARTWORK_REQUESTS.csv', 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.writer(f)
    w.writerow(HEAD)
    for aid, v in rows.items():
        w.writerow([aid, v['concept'], v['desc'], v['world'], v['level'],
                    '; '.join(v['lessons']), '512 x 512 px', 'Transparent background (WebP, alpha)',
                    v['filename'], v['status'], v['priority']])
with open(ROOT / 'audit/LESSON_ARTWORK_MAP.csv', 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.writer(f)
    w.writerow(['Lesson ID', 'Asset ID'])
    for aid, v in rows.items():
        for l in v['lessons']:
            w.writerow([l, aid])
print('requests:', len(rows), 'mappings:', sum(len(v['lessons']) for v in rows.values()))
