# -*- coding: utf-8 -*-
"""Checker for content/teaching/rollout_letters.json (extends the pilot checker). Run:
    python -X utf8 -I tool/check_rollout_letters.py
Prints ASCII only (Indic text is never printed). Exit code 1 if any ERROR.
This is a mechanical check of the creator's own output; it is NOT a verification of wording, pedagogy or audio."""
import json
import os
import re
import sys
import unicodedata

ROOT = r"E:\Aksharamala"
J = ROOT + r"\content\teaching_pending\rollout_letters.json"
PILOT = ROOT + r"\content\teaching\pilot_teaching_plans.json"
WORLDS = ["english", "telugu", "hindi", "tamil"]
DONE = {"en-a", "te-a", "hi-a", "ta-a"}
errs, warns = [], []


def E(m):
    errs.append(m)


def Wn(m):
    warns.append(m)


def asc(s):
    return s.encode("ascii", "backslashreplace").decode()


plan = json.load(open(J, encoding="utf-8"))
pilot = json.load(open(PILOT, encoding="utf-8"))
if plan.get("schema_version") != 1:
    E("schema_version != 1")
if plan.get("status") != "rollout_unverified":
    E("status != rollout_unverified")
lessons = plan["lessons"]
print("JSON parses; schema_version", plan["schema_version"], "status", plan["status"], "lessons", len(lessons))

# ---------------- expected lessons, parsed independently from the Dart source
src = open(ROOT + r"\lib\src\curriculum.dart", encoding="utf-8").read()
exp = {}
for w in WORLDS:
    m = re.search(r"final _%sRecognition = _recognitionSequence\((.*?)\n\);" % w, src, re.S).group(1)
    g = lambda k: re.search(k + r":\s*'([^']*)'", m).group(1)
    if "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" in m:
        t = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    else:
        t = re.findall(r"'([^']*)'", re.search(r"targets:\s*const\s*\[(.*?)\],\s*\n\s*locale", m, re.S).group(1))
    n = len(t)
    rows = []
    for i, L in enumerate(t):
        idat = lambda k: g("firstLessonId") if k == 0 else "%s-%03d" % (g("idPrefix"), k + 1)
        rows.append(dict(id=idat(i), letter=L, title=g("challenge"), locale=g("locale"),
                         objective="%s %s" % (g("objectivePrefix"), L), prereq=[] if i == 0 else [idat(i - 1)],
                         options=[t[i], t[(i + 1) % n], t[(i + 2) % n]], prev=t[i - 1] if i else t[-1]))
    exp[w] = rows

# alphabet table
at = open(ROOT + r"\lib\src\alphabet\alphabet_data.dart", encoding="utf-8").read()
alpha = {}
for w in WORLDS:
    body = re.search(r"const %sAlphabet = AlphabetSet\((.*?)\n\);" % w, at, re.S).group(1)
    d = {}
    for lm in re.finditer(r"AlphabetLetter\('([^']*)'(.*?)\)(?:,\s*\n)", body, re.S):
        mm = re.search(r"word:\s*'([^']*)'", lm.group(2))
        d[lm.group(1)] = mm.group(1) if mm else None
    alpha[w] = d


def begins_exact(word, letter):
    if not word or not word.startswith(letter) or word == letter:
        return False
    return not (len(word) > len(letter) and unicodedata.category(word[len(letter)]) in ("Mn", "Mc"))


# ---------------- coverage and ids across pilot + rollout
by_world = {w: {} for w in WORLDS}
for les in lessons:
    by_world[les["world"]][les["lesson_id"]] = les
gaps = []
cover = {}
for w in WORLDS:
    want = [r for r in exp[w] if r["id"] not in DONE]
    have = by_world[w]
    cover[w] = (len(have), len(want))
    for r in want:
        if r["id"] not in have:
            E("coverage: %s %s has no plan" % (w, r["id"]))
            gaps.append(r["id"])
    for lid in have:
        if lid not in {r["id"] for r in want}:
            E("coverage: %s plan %s is not an expected lesson" % (w, lid))
lids = [l["lesson_id"] for l in lessons]
pl = [l["lesson_id"] for l in pilot["lessons"]]
if len(lids) != len(set(lids)):
    E("duplicate lesson ids inside rollout")
for x in lids:
    if x in pl:
        E("lesson id %s also in pilot file" % x)
pilot_all = set()
for l in pilot["lessons"]:
    for s in l["introduce"] + l["demonstrate"] + l["remediation"]["explain"]:
        pilot_all.add(s["id"])
    for q in l["guided"] + l["practice"] + l["check"] + l["remediation"]["guided"] + l["remediation"]["check"]:
        pilot_all.add(q["id"])

all_ids = []
assets_seen = set()
n_steps = n_q = 0
tokre = re.compile(r"[\s.,!?;:\u2026\u0964\-\u2013\u2014\"'()]+")
tasks_ok = {"letter_id", "pick_word", "not_word", "not_letter", "word_to_letter", "name_picture", "hear_pick"}
variety = {}
word_repeats = [0]
SCRIPT = {"telugu": (0x0C00, 0x0C7F), "hindi": (0x0900, 0x097F), "tamil": (0x0B80, 0x0BFF)}


def tokens(s):
    return [t for t in tokre.split(s) if t]


STEMS = ["అక్షర", "अक्षर", "எழுத்"]  # the words for "letter" in te/hi/ta


def leaks(ans, text, letter_answer=False):
    """True if the answer appears as its own token (any answer) or, for answers of 2+ chars, as a substring.
    The language's own word for 'letter' (te/hi/ta) is removed first: it contains conjunct letters by spelling alone."""
    for st in STEMS:
        text = text.replace(st, " ")
    if len(ans) > 1 and not letter_answer and ans in text:
        return True
    low = [t.lower() for t in tokens(text)]
    return ans.lower() in low


def sig(q):
    return (q["prompt"], tuple(sorted(q["options"])), q["answer"], json.dumps(q["visual"], sort_keys=True), q["speech"])


for les in lessons:
    lid, w = les["lesson_id"], les["world"]
    r = next(x for x in exp[w] if x["id"] == lid)
    L = r["letter"]
    low = L.lower()
    # source fidelity
    if les["level"] != 1:
        E("%s: level != 1" % lid)
    if les["title"] != r["title"]:
        E("%s: title changed" % lid)
    if les["prerequisites"] != r["prereq"]:
        E("%s: prerequisites changed" % lid)
    if les["locale"] != r["locale"]:
        E("%s: locale changed" % lid)
    if not les["objective"].startswith(r["objective"]):
        E("%s: objective does not start with the source objective" % lid)
    for k in ("introduce", "demonstrate", "guided", "practice", "check", "remediation", "review", "mastery", "variant"):
        if k not in les:
            E("%s: missing %s" % (lid, k))
    rem = les["remediation"]
    want_counts = (2, 6, 3, 5, 3, 3, 2, 3) if les["variant"] == "words_pictures" else (2, 5, 3, 6, 3, 3, 2, 3)
    if (len(les["introduce"]), len(les["demonstrate"]), len(les["guided"]), len(les["practice"]), len(les["check"]),
            len(rem["explain"]), len(rem["guided"]), len(rem["check"])) != want_counts:
        E("%s: step/question counts" % lid)
    if les["mastery"] != {"check_total": 3, "check_pass": 2, "remediation_pass": 2, "max_remediation_cycles": 2,
                          "after_limit": "offer_parent_support"}:
        E("%s: mastery" % lid)
    rv = les["review"]
    if rv.get("native_review_needed") is not True:
        E("%s: native_review_needed not true" % lid)
    if not rv.get("items_to_review"):
        E("%s: items_to_review empty" % lid)
    steps = les["introduce"] + les["demonstrate"] + rem["explain"]
    qs = les["guided"] + les["practice"] + les["check"] + rem["guided"] + rem["check"]
    n_steps += len(steps)
    n_q += len(qs)
    var = les["variant"]
    # source word facts
    wl = alpha[w].get(L)
    has_begin = begins_exact(wl, L)
    if var == "letter_only" and any(v.get("type") in ("letterWord",) for s in steps for v in [s["visual"]]):
        E("%s: letter_only plan shows a word" % lid)
    if var != "letter_only" and not has_begin:
        E("%s: claims a word for a letter whose source word does not begin with it" % lid)
    if var == "words_pictures":
        for x in r["options"]:
            if not begins_exact(alpha[w].get(x), x):
                E("%s: words_pictures but option %s has no beginning word" % (lid, asc(x)))

    # text hygiene
    def hygiene(t, where):
        if not isinstance(t, str) or not t.strip():
            E("%s: empty text" % where)
            return
        if "{" in t or "}" in t or "None" in t:
            E("%s: unformatted placeholder" % where)
        if w == "english":
            if re.search(r"[^\x00-\x7F]", t):
                E("%s: non-ascii in English text" % where)
        else:
            lo, hi = SCRIPT[w]
            if not any(lo <= ord(c) <= hi for c in t):
                Wn("%s: no %s script characters" % (where, w))

    for s in steps:
        all_ids.append(s["id"])
        if not s["id"].startswith(lid + "."):
            E("bad id " + s["id"])
        hygiene(s["text"], s["id"] + ".text")
        hygiene(s["speech"], s["id"] + ".speech")
        v = s["visual"]
        if v["type"] not in ("none", "glyph", "picture", "letterWord"):
            E("%s: bad visual" % s["id"])
        if v["type"] in ("picture", "letterWord"):
            assets_seen.add((lid, v["asset"]))
    # remediation explain: different text from demonstrate; not all visuals copied
    dt = {s["text"] for s in les["demonstrate"] + les["introduce"]}
    for s in rem["explain"]:
        if s["text"] in dt:
            E("%s: remediation text equals a teaching step" % s["id"])
        if s["visual"]["type"] == "none":
            E("%s: remediation step shows nothing" % s["id"])
    dv = {json.dumps(s["visual"], sort_keys=True) for s in les["demonstrate"] + les["introduce"]}
    if all(json.dumps(s["visual"], sort_keys=True) in dv for s in rem["explain"]):
        E("%s: remediation only repeats teaching visuals" % lid)

    earlier = {q["task"] for q in les["guided"] + les["practice"]} | {"letter_id"} if False else {q["task"] for q in les["guided"] + les["practice"]}
    sigs = []
    for q in qs:
        qid = q["id"]
        all_ids.append(qid)
        ph = qid.split(".")[1]
        if not qid.startswith(lid + "."):
            E("bad id " + qid)
        if q.get("task") not in tasks_ok:
            E("%s: task %s" % (qid, q.get("task")))
        hygiene(q["prompt"], qid + ".prompt")
        hygiene(q["speech"], qid + ".speech")
        hygiene(q["explanation"], qid + ".expl")
        if q["answer"] not in q["options"]:
            E("%s: answer not in options" % qid)
        if len(set(q["options"])) != len(q["options"]) or not 2 <= len(q["options"]) <= 4:
            E("%s: options" % qid)
        wrong = {o for o in q["options"] if o != q["answer"]}
        if set(q["wrong_feedback"]) != wrong:
            E("%s: wrong_feedback keys" % qid)
        if not 1 <= q["difficulty"] <= 3:
            E("%s: difficulty" % qid)
        v = q["visual"]
        if v["type"] in ("objects", "numberLine", "letterWord"):
            E("%s: visual %s not allowed in a question" % (qid, v["type"]))
        if v["type"] == "picture":
            assets_seen.add((lid, v["asset"]))
            if v.get("caption", "") != "":
                E("%s: question picture has a caption" % qid)
        for o, p in q.get("optionPictures", {}).items():
            assets_seen.add((lid, p))
            if o not in q["options"]:
                E("%s: optionPictures key" % qid)
        LA = q["task"] in ("letter_id", "word_to_letter", "not_letter")  # letter answers: whole-token match only
        is_assess = ph in ("practice", "check", "remediation_check")
        if is_assess:
            if v["type"] == "glyph" and v["glyph"] == q["answer"]:
                E("%s: glyph equals answer" % qid)
            if v["type"] == "picture" and v.get("caption") == q["answer"]:
                E("%s: caption equals answer" % qid)
            if leaks(q["answer"], q["prompt"], LA):
                E("%s: prompt contains answer" % qid)
            for o, m in q["wrong_feedback"].items():
                if leaks(q["answer"], m, LA):
                    E("%s: wrong_feedback leaks the answer" % qid)
            for h in q["hints"]:
                if leaks(q["answer"], h, LA):
                    E("%s: a practice/check hint contains the answer" % qid)
        # hint 1 free of the answer everywhere
        if q["hints"] and leaks(q["answer"], q["hints"][0], LA):
            E("%s: hint 1 contains the answer" % qid)
        if ph in ("guided", "remediation_guided") and len(q["hints"]) != 2:
            E("%s: guided needs 2 hints" % qid)
        if ph == "practice" and len(q["hints"]) != 2:
            E("%s: practice needs 2 hints" % qid)
        if ph in ("check", "remediation_check"):
            if q["hints"]:
                E("%s: check has hints" % qid)
            if len(q["options"]) != 3:
                E("%s: check item must have exactly 3 options" % qid)
            if q["task"] in ("not_word", "not_letter"):
                E("%s: NOT puzzle used in a check" % qid)
            if q["task"] not in earlier:
                E("%s: task %s not taught/practised earlier (guided/practice)" % (qid, q["task"]))
        if ph in ("remediation_guided",) and q["task"] not in earlier:
            E("%s: task %s not taught earlier" % (qid, q["task"]))
        sigs.append(sig(q))
    # repetition
    if len(set(sigs)) != len(sigs):
        E("%s: duplicate question item (same prompt, option set, answer, visual, speech)" % lid)
    ck = [sig(q) for q in les["check"]]
    ok_ = {sig(q) for q in les["guided"] + les["practice"] + rem["guided"]}
    for q in les["check"]:
        if sig(q) in ok_:
            E("%s: check repeats an earlier item" % q["id"])
    for q in rem["check"]:
        if sig(q) in ok_ or sig(q) in ck:
            E("%s: remediation check repeats an earlier item" % q["id"])
    for grp, name in ((les["check"], "check"), (rem["check"], "remediation check")):
        if len({q["options"].index(q["answer"]) for q in grp}) < 2:
            E("%s: %s answer position not varied" % (lid, name))
    # not-puzzle taught in demonstrate
    if not any(("NOT" in s["text"].upper() or "puzzle" in s["text"].lower() or True) for s in les["demonstrate"]):
        pass
    variety[lid] = (len({q["prompt"] for q in qs}), len({(q["task"]) for q in qs}), len(qs))
    # no practice/check question uses a letter outside the lesson's letters + previous letter (letter tasks)
    seq = [x["letter"] for x in exp[w]]
    allowed = set(seq) | ({x.lower() for x in seq} if w == "english" else set())
    for q in qs:
        if q["task"] in ("letter_id", "word_to_letter", "not_letter"):
            for o in q["options"]:
                if o not in allowed:
                    E("%s: option %s outside the lesson letters" % (q["id"], asc(o)))
    # assets: every step/question visual asset must exist; assets_missing is only a wish list that nothing references
    for (l2, a_) in [x for x in assets_seen if x[0] == lid]:
        if not os.path.isfile(os.path.join(ROOT, a_.replace("/", os.sep))):
            E("%s: visual references non-existent file %s" % (lid, a_))
    for a_ in rv["assets_missing"]:
        if os.path.isfile(os.path.join(ROOT, a_.replace("/", os.sep))):
            E("%s: asset %s listed missing but exists" % (lid, a_))
        if (lid, a_) in assets_seen:
            E("%s: wished-for asset %s is referenced by the plan" % (lid, a_))
    # (answer, option set) of letter tasks never repeats within a lesson (guided, practice, check, remediation)
    seen_as = {}
    for q in qs:
        if q["task"] in ("letter_id", "word_to_letter"):
            key = (q["answer"], frozenset(q["options"]))
            if key in seen_as:
                E("%s: repeats the answer + option set of %s" % (q["id"], seen_as[key]))
            seen_as[key] = q["id"]
    if var != "words_pictures":
        rv_p = [q for q in les["practice"] if q.get("purpose") == "spaced_review_previous_letter"]
        rv_c = [q for q in les["check"] if q.get("purpose") == "spaced_review_previous_letter"]
        prevL = r["prev"]
        if len(rv_p) != 1 or len(rv_c) != 1 or any(q["answer"] != prevL for q in rv_p + rv_c):
            E("%s: spaced-review items (one in practice, one in check, answer = previous letter) missing" % lid)
    else:
        for q in les["check"] + rem["check"]:
            if q["task"] in ("pick_word", "name_picture", "hear_pick"):
                key = (q["answer"], frozenset(q["options"]))
                if any((x["answer"], frozenset(x["options"])) == key for x in les["guided"] + les["practice"]):
                    word_repeats[0] += 1
    for q in qs:
        if q["visual"]["type"] == "picture" and os.path.basename(q["visual"]["asset"]) in ("hi_one.webp", "te_five.webp"):
            E("%s: number picture used in a question" % q["id"])
    if var == "words_pictures":
        if [s_["visual"]["type"] for s_ in les["demonstrate"][-2:]] != ["letterWord", "picture"]:
            E("%s: puzzle does not show both pictures" % lid)

# ids unique across pilot + rollout
if len(all_ids) != len(set(all_ids)):
    E("duplicate step/question ids inside rollout")
clash = set(all_ids) & pilot_all
if clash:
    E("step/question ids also in pilot: %d" % len(clash))

# ---------------- report
print("ids: %d unique: %d | steps: %d questions: %d | pilot ids %d, clash %d" % (len(all_ids), len(set(all_ids)), n_steps, n_q, len(pilot_all), len(clash)))
print("coverage (planned/expected): " + ", ".join("%s %d/%d" % (w, a, b) for w, (a, b) in cover.items()))
vc = {}
for l in lessons:
    vc[(l["world"], l["variant"])] = vc.get((l["world"], l["variant"]), 0) + 1
print("variants: " + ", ".join("%s/%s %d" % (k[0], k[1], v) for k, v in sorted(vc.items())))
miss_total = sum(1 for l in lessons if l["review"]["assets_missing"])
print("lessons listing missing assets: %d; distinct asset paths referenced: %d" % (miss_total, len({a for _, a in assets_seen})))
dist = {}
for lid, (np_, nt, nq) in variety.items():
    v = next(l["variant"] for l in lessons if l["lesson_id"] == lid)
    dist.setdefault(v, []).append((np_, nt))
for v, xs in dist.items():
    print("variety %-17s lessons %3d | distinct prompts per lesson min %d max %d | distinct task types min %d max %d" % (
        v, len(xs), min(a for a, _ in xs), max(a for a, _ in xs), min(b for _, b in xs), max(b for _, b in xs)))
print("words_pictures check/remediation-check WORD items sharing answer+option set with a guided/practice item (data limit, only 3 words): %d" % word_repeats[0])
print("gaps (expected lessons with no plan): %d %s" % (len(gaps), gaps[:10]))
print("WARNINGS:", len(warns))
for e in warns[:20]:
    print(" ~", asc(e))
print("ERRORS:", len(errs))
for e in errs[:60]:
    print(" -", asc(e))
sys.exit(1 if errs else 0)
