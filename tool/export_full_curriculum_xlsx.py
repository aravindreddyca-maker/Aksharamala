"""Builds audit/AKSHARAMALA_FULL_CURRICULUM_AND_QUESTIONS.xlsx.

Inputs: build/curriculum_dump.json (flutter test tool/dump_curriculum_test.dart),
content/teaching/*.json (teaching plans bundled in the app), content/rhymes/rhymes.json,
reference/Aksharamala_Consolidated_Curriculum_Levels_1_to_5.xlsx (proposed rows).
Run: python -X utf8 -I tool/export_full_curriculum_xlsx.py
"""
import glob
import json
from collections import Counter, defaultdict
from pathlib import Path

import openpyxl
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'audit' / 'AKSHARAMALA_FULL_CURRICULUM_AND_QUESTIONS.xlsx'
LANG = {'english': 'English', 'telugu': 'Telugu', 'hindi': 'Hindi',
        'tamil': 'Tamil', 'numbers': 'English (Number Galaxy)'}
WORLD = {'english': 'English Forest', 'telugu': 'Telugu Kingdom',
         'hindi': 'Hindi Valley', 'tamil': 'Tamil Garden', 'numbers': 'Number Galaxy'}
REGIONAL = {'telugu', 'hindi', 'tamil'}
HEAD_FILL = PatternFill('solid', fgColor='2E3A59')
HEAD_FONT = Font(bold=True, color='FFFFFF')
WRAP = Alignment(wrap_text=True, vertical='top')


def clean(v):
    if v is None:
        return ''
    if isinstance(v, (list, tuple)):
        return ' | '.join(str(x) for x in v)
    return str(v)


def sheet(wb, title, header, rows, widths):
    ws = wb.create_sheet(title)
    ws.append(header)
    for r in rows:
        ws.append([clean(c) for c in r])
    for c in ws[1]:
        c.fill, c.font, c.alignment = HEAD_FILL, HEAD_FONT, WRAP
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w
    for row in ws.iter_rows(min_row=2):
        for c in row:
            c.alignment = WRAP
    ws.freeze_panes = 'A2'
    if rows:
        ws.auto_filter.ref = ws.dimensions
    return ws


dump = json.load(open(ROOT / 'build' / 'curriculum_dump.json', encoding='utf-8'))
lessons = dump['lessons']
bank = dump['questions']

# teaching plans
plans = {}
for f in sorted(glob.glob(str(ROOT / 'content' / 'teaching' / '*.json'))):
    for p in json.load(open(f, encoding='utf-8'))['lessons']:
        plans.setdefault(p['lesson_id'], p)

# proposed rows from the reference workbook (rows not implemented in the app)
ref = openpyxl.load_workbook(ROOT / 'reference' /
                             'Aksharamala_Consolidated_Curriculum_Levels_1_to_5.xlsx',
                             read_only=True)
app_ids = {l['id'] for l in lessons}
proposed = defaultdict(list)
for lv in range(1, 6):
    ws = ref[f'Level {lv}']
    rows = list(ws.iter_rows(values_only=True))
    for r in rows[1:]:
        lid = str(r[2] or '')
        if lid.startswith('proposed-'):
            proposed[lv].append(r)
# an outline row of the old workbook is dropped when the app now has lessons
# for that level and world (those lessons supersede the outline)
WN = {'English Forest': 'english', 'Telugu Kingdom': 'telugu', 'Hindi Valley': 'hindi',
      'Tamil Garden': 'tamil', 'Number Galaxy': 'numbers'}
for lv in list(proposed):
    proposed[lv] = [
        r for r in proposed[lv]
        if sum(1 for l in lessons
               if lv in l['levels'] and l['world'] == WN.get(str(r[0]))) < 3]

wb = openpyxl.Workbook()
wb.remove(wb.active)

# ---- per level sheets
cur_head = ['Status', 'Lesson ID', 'World', 'Language', 'Title', 'Topic / skill',
            'Objective', 'Needs first (prerequisites)', 'Teaching plan in app',
            'Educator / native review needed', 'Activity type', 'Question items']
q_head = ['Question ID', 'Interaction type', 'Source', 'Phase', 'Lesson ID', 'World',
          'Language', 'Question / prompt', 'Option 1', 'Option 2', 'Option 3', 'Option 4',
          'Correct answer', 'Hints', 'Explanation', 'Verification status',
          'Options check', 'Same prompt+answer as']
# Interaction types whose items legitimately have no options
NO_OPTION_TYPES = {'parentMarked', 'listen', 'write', 'tracing', 'none'}


def options_check(itype, opts, answer):
    has = [o for o in opts if o]
    if not has:
        return ('No options (expected: ' + itype + ')') if itype in NO_OPTION_TYPES \
            else 'MISSING OPTIONS'
    if answer and answer not in has:
        return 'ANSWER NOT IN OPTIONS'
    return 'OK'
count_cur = Counter()
count_q = Counter()
count_plan = Counter()
by_level_lessons = defaultdict(list)
for l in lessons:
    for lv in l['levels']:
        by_level_lessons[lv].append(l)

PH = ['introduce', 'demonstrate']


def plan_rows(p, lesson_title):
    out = []
    for phase in ['guided', 'practice', 'check']:
        for q in p.get(phase, []):
            out.append((phase, q))
    rem = p.get('remediation', {})
    for phase, key in [('remediation guided', 'guided'), ('remediation check', 'check')]:
        for q in rem.get(key, []):
            out.append((phase, q))
    return out


# question items per lesson (exam bank + app steps that ask + teaching-plan items)
count_items = Counter()
for q in bank:
    count_items[q['lessonId']] += 1
# a lesson step that asks the same question (same lesson, prompt and answer) as an
# exam-bank row is a mirror of that row: it is shown but not counted twice
bank_key = {(q['lessonId'], q['prompt'], q['answer']): q['id'] for q in bank}
for l in lessons:
    count_items[l['id']] += sum(
        1 for s in l.get('steps', [])
        if s['isQuestion'] and (l['id'], s['prompt'], s.get('answer', '')) not in bank_key)
    p = plans.get(l['id'])
    if p:
        count_items[l['id']] += len(plan_rows(p, l['title']))

# same prompt+answer across different bank questions (review repeats, not auto-deleted)
same_pa = defaultdict(list)
for q in bank:
    same_pa[(q['prompt'], q['answer'])].append(q['id'])

for lv in range(1, 9):
    crow = []
    qrow = []
    for l in sorted(by_level_lessons[lv], key=lambda x: (x['world'], x['id'])):
        has_plan = l['id'] in plans
        n_steps = len(l.get('steps', []))
        n_items = count_items[l['id']]
        if has_plan:
            plan_text = 'Yes (teach > demonstrate > guided > practice > check)'
        elif n_steps:
            plan_text = f'No (step lesson: {n_steps} steps, no teaching plan)'
        else:
            plan_text = 'No (single quiz question)'
        crow.append(['Implemented in app', l['id'], WORLD[l['world']], LANG[l['world']],
                     l['title'], ' / '.join(x for x in [l['topic'], l['skill']] if x),
                     l['objective'], l['prerequisites'],
                     plan_text,
                     'Yes' if l['world'] in REGIONAL else 'Language/pedagogy review pending'
                     if l['world'] != 'numbers' else 'Educator review pending',
                     l['kind'], n_items if n_items else
                     f"0 - no question items ({l['kind']} activity)"])
        count_cur[(lv, 'impl')] += 1
        if has_plan:
            count_plan[lv] += 1
    for r in proposed[lv]:
        crow.append(['Proposed (workbook outline, no content yet)', r[2], r[0],
                     r[9], r[3], r[6], r[5], r[8], 'No', 'Yes'])
        count_cur[(lv, 'prop')] += 1
    sheet(wb, f'L{lv} Curriculum', cur_head, crow,
          [22, 24, 16, 18, 26, 26, 44, 22, 30, 24, 14, 26])

    # questions: exam bank
    for q in sorted((x for x in bank if x['level'] == lv),
                    key=lambda x: (x['world'], x['id'])):
        opts = (q['options'] + [''] * 4)[:4]
        ver = ', '.join(q['verification'])
        prompt = q['prompt']
        if q.get('glyph'):
            prompt = f"{prompt}   [shown: {q['glyph']}]"
        if q.get('passage'):
            prompt = f"{q['passage']}\n{prompt}"
        others = [x for x in same_pa[(q['prompt'], q['answer'])] if x != q['id']]
        qrow.append([q['id'], q['type'], 'Lesson question (exam bank)', 'lesson', q['lessonId'],
                     WORLD[q['world']], LANG[q['world']], prompt, *opts, q['answer'],
                     '', q['explanation'], ver,
                     options_check(q['type'], opts, q['answer']), ', '.join(others)])
        count_q[(lv, 'bank')] += 1
    # questions: app lesson steps (the step-based lessons; listen/write steps are shown too)
    for l in sorted(by_level_lessons[lv], key=lambda x: (x['world'], x['id'])):
        for s in l.get('steps', []):
            opts = (s.get('options', []) + [''] * 4)[:4]
            prompt = s['prompt'] + (f"   [shown: {s['glyph']}]" if s.get('glyph') else '')
            mirror = bank_key.get((l['id'], s['prompt'], s.get('answer', '')))
            src = 'Lesson step (app)' + (' - mirror of exam bank row' if mirror else '')
            qrow.append([f"{l['id']}#s{s['index']}", s['kind'], src, 'step',
                         l['id'], WORLD[l['world']], LANG[l['world']], prompt, *opts,
                         s.get('answer', ''), '', '',
                         'Not educator-verified' + (' (regional text)' if l['world'] in REGIONAL else ''),
                         options_check(s['kind'], opts, s.get('answer', '')), mirror or ''])
            if s['isQuestion'] and not mirror:
                count_q[(lv, 'step')] += 1
    # questions: teaching plans
    for l in sorted(by_level_lessons[lv], key=lambda x: (x['world'], x['id'])):
        p = plans.get(l['id'])
        if not p:
            continue
        for phase, q in plan_rows(p, l['title']):
            opts = (q.get('options', []) + [''] * 4)[:4]
            hints = ' / '.join(q.get('hints', []))
            ver = 'teaching plan, unverified by native speaker' if \
                l['world'] in REGIONAL else 'teaching plan, content-verified (structure and arithmetic only)'
            itype = 'visual:' + str((q.get('visual') or {}).get('type', 'none'))
            qrow.append([q.get('id', ''), itype, 'Teaching plan item', phase, l['id'],
                         WORLD[l['world']], LANG[l['world']], q.get('prompt', ''), *opts,
                         q.get('answer', ''), hints, q.get('explanation', ''), ver,
                         options_check('none' if not opts[0] else 'choice',
                                       opts, q.get('answer', '')), ''])
            count_q[(lv, 'plan')] += 1
    sheet(wb, f'L{lv} Questions', q_head, qrow,
          [22, 18, 24, 16, 22, 16, 16, 52, 20, 20, 20, 20, 20, 40, 40, 30, 26, 30])

# ---- rhymes
rp = ROOT / 'content' / 'rhymes' / 'rhymes.json'
if rp.exists():
    rr = []
    for r in json.load(open(rp, encoding='utf-8'))['rhymes']:
        lines = '\n'.join(x['text'] for x in r['lines'])
        gloss = '\n'.join(x.get('meaning_en', '') for x in r['lines'])
        a = r.get('activity', {}).get('items', [{}])[0]
        rr.append([r['id'], r['language'].title(), r['title'], lines, gloss,
                   a.get('blank_word', ''), a.get('options', []), a.get('answer', ''),
                   r.get('source', ''), 'Native review needed' if
                   r.get('review', {}).get('native_review_needed') else 'English'])
    sheet(wb, 'Rhymes', ['ID', 'Language', 'Title', 'Lines', 'English meaning',
                         'Blank word', 'Options', 'Answer', 'Source', 'Review'],
          rr, [18, 12, 24, 44, 44, 14, 28, 14, 30, 20])

# ---- summary + readme (front)
ws = wb.create_sheet('Summary', 0)
ws.append(['Level', 'Lessons implemented in app', 'Lessons with a teaching plan',
           'Proposed lessons (outline only)', 'Lesson questions (exam bank)',
           'Teaching-plan question items', 'Questions total',
           'Lesson step questions (app)', 'Implemented lessons with NO question items'])
for lv in range(1, 9):
    no_items = sum(1 for l in by_level_lessons[lv] if count_items[l['id']] == 0)
    ws.append([f'Level {lv}', count_cur[(lv, 'impl')], count_plan[lv],
               count_cur[(lv, 'prop')], count_q[(lv, 'bank')], count_q[(lv, 'plan')],
               count_q[(lv, 'bank')] + count_q[(lv, 'plan')] + count_q[(lv, 'step')],
               count_q[(lv, 'step')], no_items])
ws.append(['Total'] + [sum(ws.cell(r, c).value for r in range(2, 10)) for c in range(2, 10)])
for c in ws[1]:
    c.fill, c.font, c.alignment = HEAD_FILL, HEAD_FONT, WRAP
for i, w in enumerate([14, 22, 24, 26, 26, 26, 18, 22, 26], 1):
    ws.column_dimensions[get_column_letter(i)].width = w
ws.append([])
by_world = Counter()
for l in lessons:
    for lv in l['levels']:
        by_world[(lv, l['world'])] += 1
ws.append(['Implemented lessons by level and world'])
ws.cell(ws.max_row, 1).font = Font(bold=True)
ws.append(['Level'] + [WORLD[w] for w in WORLD])
for c in ws[ws.max_row]:
    c.fill, c.font = HEAD_FILL, HEAD_FONT
for lv in range(1, 9):
    ws.append([f'Level {lv}'] + [by_world[(lv, w)] for w in WORLD])

rd = wb.create_sheet('README', 0)
notes = [
    'Aksharamala: curriculum and questions by level, all languages',
    '',
    'Source: generated from the app itself (lessons, exam question bank, bundled teaching plans) '
    'plus the proposed rows of the consolidated curriculum workbook.',
    '',
    'Sheets: Summary; for each level a Curriculum sheet (L1..L8 Curriculum) and a Questions sheet '
    '(L1..L8 Questions); Rhymes.',
    '"Implemented in app" = a child can play it. "Proposed" = an outline row from the workbook with NO content yet.',
    '"Lesson question (exam bank)" = the question the lesson itself asks (these also feed parent exams).',
    '"Teaching plan item" = guided, practice, check and remediation questions of the new teach-first plans.',
    '',
    'HONEST STATUS',
    '- Levels 3 to 8 were added to the app in a later work session; their independent review status is not recorded in this file (see the audit reports).',
    '- Only lessons with a teaching plan have the full teach > demonstrate > guided > practice > check sequence.',
    '- Telugu, Hindi and Tamil text, and all spoken audio (phone voice), have NOT been checked by a native speaker or educator.',
    '- Teaching plans were checked by an independent reviewer for structure and arithmetic only.',
    '- Exam-bank questions are machine-checked (answer is among the options, sums recomputed); none is educator-verified.',
    '- Rhymes are unverified drafts.',
    '- Human review (native speakers, educators, the rhyme copyright check) is still required for every row. This file cannot record it as done.',
    '',
    'COLUMNS ADDED IN THIS VERSION',
    '- Question ID: stable key. Exam-bank questions use the app id (for example en-a#q0); lesson steps use lessonId#s<step index>; teaching-plan items use their plan id.',
    '- Interaction type: exam-bank questions use the app question type (listening, parentMarked, arithmetic, pictureIdentification, recognition, multipleChoice). Lesson steps use the step kind (listen, choice, write, pickWord, pickLetter, pickQuantity, count, compare). Teaching-plan items use visual:<type>.',
    '- Activity type (Curriculum sheets): the lesson kind (tracing, alphabet, story, game, words, numbers, steps). Tracing and free-writing activities have no options by design.',
    '- Options check: OK, or "No options (expected: ...)" for parent-marked, listen, write, tracing and visual-only items, or MISSING OPTIONS / ANSWER NOT IN OPTIONS, which need fixing.',
    '- Same prompt+answer as: other exam-bank questions with the same prompt and correct answer. These are listed for review. Nothing is deleted automatically.',
    '- Lesson steps: the app asks step questions inside each step-based lesson. Most of them repeat an exam-bank row (same lesson, same question, same answer). Those rows are marked "mirror of exam bank row" and are not counted twice.',
    '- The Level 2 "Read the ..." and "Look closely" lessons have no exam-bank rows; their questions are the step rows, so they now show content.',
    '- Duplicates: the first version of this file reported 54 exact duplicate records. This rebuild finds no exact duplicate rows. Repeats that remain are listed in "Same prompt+answer as" for review.',
]
for n in notes:
    rd.append([n])
rd.column_dimensions['A'].width = 120
rd['A1'].font = Font(bold=True, size=14)
rd['A10'].font = Font(bold=True)
for row in rd.iter_rows():
    for c in row:
        c.alignment = Alignment(wrap_text=True, vertical='top')

wb.move_sheet('README', offset=-wb.index(wb['README']))
OUT.parent.mkdir(exist_ok=True)
wb.save(OUT)
print('saved', OUT)
for lv in range(1, 9):
    print(lv, count_cur[(lv, 'impl')], count_plan[lv], count_cur[(lv, 'prop')],
          count_q[(lv, 'bank')], count_q[(lv, 'plan')])
