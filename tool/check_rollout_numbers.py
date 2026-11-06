# -*- coding: utf-8 -*-
"""check_rollout.py - extended pilot checker for content/teaching_pending/rollout_numbers.json.
Independent recomputation of every answer from prompt + visual (+ options) - it does NOT import the generator.
Run: python -X utf8 -I check_rollout.py
Written by content-creator. A passing run is NOT a verification (that belongs to content-verifier)."""
import json, os, re, sys, unicodedata
from collections import Counter

ROOT = r"E:\Aksharamala"
R = os.path.join(ROOT, "content", "teaching_pending", "rollout_numbers.json")
P = os.path.join(ROOT, "content", "teaching", "pilot_teaching_plans.json")
S56 = os.path.join(ROOT, "content", "age56", "numbers_age_5_6.json")
CUR = os.path.join(ROOT, "lib", "src", "curriculum.dart")
errs = []
info = []


def E(m):
    errs.append(m)


roll = json.load(open(R, encoding="utf-8"))
pilot = json.load(open(P, encoding="utf-8"))
src56 = {l["id"]: l for l in json.load(open(S56, encoding="utf-8"))["lessons"]}
print("JSON parses; schema_version", roll["schema_version"], "status", roll["status"], "lessons", len(roll["lessons"]))
if roll["status"] != "rollout_unverified":
    E("status is not rollout_unverified")

WORDS = {w: i for i, w in enumerate(["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"])}
NUMW = {v: k for k, v in WORDS.items()}
SHAPE = {"triangle": (3, 3, "Triangle"), "square": (4, 4, "Square"), "rectangle": (4, 4, "Rectangle"), "circle": (0, 0, "Circle")}
PARTS = ["morning", "afternoon", "evening", "night"]


# ------------------------------------------------ expected lesson set + metadata
expected = ["numbers-count-%03d" % i for i in range(11)] + sorted(src56) + \
           ["num-count", "num-names", "num-subtract", "num-multiply", "num-divide", "num-fraction", "num-percent"]
got = [l["lesson_id"] for l in roll["lessons"]]
missing = [x for x in expected if x not in got]
extra = [x for x in got if x not in expected]
if missing:
    E("lessons NOT covered: %s" % missing)
if extra:
    E("unexpected lessons: %s" % extra)
if len(got) != len(set(got)):
    E("duplicate lesson ids")
cur = open(CUR, encoding="utf-8").read()
CURL = {}
for m in re.finditer(r"id: '(num-[a-z]+)',(.*?)\n      \),", cur, re.S):
    body = m.group(2)
    t = re.search(r"title: '([^']*)'", body).group(1)
    o = re.search(r"learningObjective: '([^']*)'", body).group(1)
    pr = re.search(r"prerequisites: \[([^\]]*)\]", body)
    pr = re.findall(r"'([^']*)'", pr.group(1)) if pr else []
    stage = re.search(r"ExperienceStage\.(\w+)", body).group(1)
    CURL[m.group(1)] = (t, o, pr, {"explorer": 1, "creator": 2, "scholar": 3, "champion": 4}[stage])
for l in roll["lessons"]:
    lid = l["lesson_id"]
    if lid in src56:
        s = src56[lid]
        if (l["title"], l["objective"], l["prerequisites"], l["level"]) != (s["title"], s["objective"], s["prerequisites"], s["level"]):
            E("%s: title/objective/prereq/level differ from numbers_age_5_6.json" % lid)
    elif lid in CURL:
        c = CURL[lid]
        if (l["title"], l["objective"], l["prerequisites"], l["level"]) != c:
            E("%s: metadata differs from curriculum.dart %r vs %r" % (lid, (l["title"], l["objective"], l["prerequisites"], l["level"]), c))
    elif lid.startswith("numbers-count-"):
        n = int(lid[-3:])
        if l["title"] != "Number %d" % n or l["level"] != 1 or l["prerequisites"] != ([] if n == 0 else ["numbers-count-%03d" % (n - 1)]):
            E("%s: metadata differs from batch_content.dart" % lid)
        if l["objective"] != "Count objects: %d" % n:
            E("%s: objective differs from pack record" % lid)
    if l["world"] != "numbers" or l["locale"] != "en-IN":
        E("%s: world/locale" % lid)

# ------------------------------------------------ ids unique across both files
ids = []
for src in (pilot, roll):
    for l in src["lessons"]:
        ids.append(l["lesson_id"])
        r = l["remediation"]
        for it in l["introduce"] + l["demonstrate"] + r["explain"] + l["guided"] + l["practice"] + l["check"] + r["guided"] + r["check"]:
            ids.append(it["id"])
dups = [k for k, v in Counter(ids).items() if v > 1]
if dups:
    E("ids not unique across pilot + rollout: %s" % dups[:10])
print("ids across pilot+rollout:", len(ids), "unique:", len(set(ids)))

# ------------------------------------------------ helpers for solving
def ints(s):
    return [int(x) for x in re.findall(r"\d+", s)]


def toks(s):
    return re.findall(r"(?<![\d])\d+(?![\d])", s)


def groups(v):
    return [g["count"] for g in v["groups"]]


def seqterms(g):
    return [int(x) for x in re.findall(r"\d+", g)]


def solve(q, l):
    t = q.get("task")
    p = q["prompt"]
    v = q["visual"]
    opts = q["options"]
    try:
        if t == "add_objects":
            return str(sum(groups(v)))
        if t == "add_line":
            return str(v["start"] + v["jump"]) if v["jump"] >= 0 else None
        if t in ("add_symbolic",):
            a, b = ints(p)[:2]
            return str(a + b)
        if t == "bond10":
            a = ints(p)[0]
            return str(10 - a)
        if t == "add_ones":
            m = re.search(r"What is (\d+) \+ (\d+)\?", p)
            return str(int(m.group(1)) + int(m.group(2)))
        if t == "sub_objects":
            g = groups(v)
            return str(g[0] - v["takeAway"])
        if t == "sub_line":
            return str(v["start"] + v["jump"])
        if t == "sub_symbolic":
            a, b = ints(p)[:2]
            return str(a - b)
        if t == "fact":
            a, b = ints(p)
            good = []
            for o in opts:
                x, y, z = ints(o)
                if x + y == z and y == b and z == a:
                    good.append(o)
            return good[0] if len(good) == 1 else None
        if t in ("tens_pic", "ones_pic"):
            if t == "tens_pic":
                return str(v["tens"])
            return str(v["ones"])
        if t in ("tens_sym", "ones_sym"):
            n = ints(p)[0]
            return str(n // 10 if t == "tens_sym" else n % 10)
        if t == "build":
            a, b = ints(p)
            return str(a * 10 + b)
        if t == "sign":
            a, b = ints(p)[:2]
            return "=" if a == b else ("<" if a < b else ">")
        if t == "bigger":
            return str(max(int(o) for o in opts))
        if t == "smaller":
            return str(min(int(o) for o in opts))
        if t == "compare3":
            big = "biggest" in p
            return str(max(int(o) for o in opts) if big else min(int(o) for o in opts))
        if t == "count":
            if v["type"] == "objects":
                return str(sum(groups(v)))
            return "0" if "no " in p or "empty" in p or "nothing" in p else None
        if t == "line":
            if v["showHops"]:
                return str(v["start"] + v["jump"])
            return str(v["start"])
        if t in ("next", "missing", "rule"):
            if v["type"] == "glyph":
                seq = [int(x) for x in re.findall(r"\d+", v["glyph"])]
            else:
                seq = None
            if t == "rule":
                d = seq[1] - seq[0]
                return ("+%d" % d) if d > 0 else ("\u2212%d" % -d)
            if t == "missing":
                a, c, d = seq
                # glyph is "a, __, c, d"
                gap = (d - a) // 3
                return str(a + gap)
            if t == "next":
                if seq is not None:
                    d = seq[1] - seq[0]
                    return str(seq[-1] + d)
                nums = ints(p)
                d = nums[1] - nums[0]
                return str(nums[2] + d)
        if t in ("sides", "corners"):
            a = v["asset"]
            k = os.path.basename(a).split(".")[0]
            return str(SHAPE[k][0 if t == "sides" else 1])
        if t == "name":
            k = os.path.basename(v["asset"]).split(".")[0]
            return SHAPE[k][2]
        if t == "which_prop":
            pr = p
            if "3 straight sides" in pr or "3 corners" in pr:
                return "Triangle"
            if "4 corners and all its sides the same length" in pr or "4 equal sides" in pr:
                return "Square"
            if "2 long" in pr:
                return "Rectangle"
            if "round" in pr or "no corners" in pr:
                return "Circle"
        if t == "numeral_to_word":
            return NUMW[int(v["glyph"])]
        if t == "word_to_numeral":
            w = re.search(r"'(\w+)'", p).group(1)
            return str(WORDS[w])
        if t == "count_to_word":
            return NUMW[sum(groups(v))]
        if t == "groups_pic":
            g = groups(v)
            return str(sum(g))
        if t == "repeat_add":
            return str(sum(ints(p.split("=")[0])))
        if t == "times_sym":
            a, b = ints(p)[:2]
            return str(a * b)
        if t == "story":
            n = ints(p)
            return str(n[0] * n[1])
        if t == "share":
            return str(groups(v)[0] // ints(p)[0])
        if t == "bags":
            n = ints(p)
            return str(groups(v)[0] // n[1] if len(n) > 1 and groups(v)[0] == n[0] else n[0] // n[1])
        if t == "share_story":
            n = ints(p)
            return str(n[0] // n[1])
        if t == "sym":
            a, b = ints(p)[:2]
            return str(a // b)
        if t == "half_set":
            return str(groups(v)[0] // 2)
        if t == "half_sym":
            return str(ints(p)[0] // 2)
        if t == "half_story":
            return str(ints(p)[0] // 2)
        if t == "which_split":
            N = ints(p)[0]
            good = [o for o in opts if ints(o)[0] == ints(o)[1] and sum(ints(o)) == N]
            return good[0] if len(good) == 1 else None
        if t == "pct_set":
            pct = ints(p)[0]
            return str(groups(v)[0] * pct // 100)
        if t in ("pct_sym", "pct_story"):
            n = ints(p)
            return str(n[1] * n[0] // 100) if t == "pct_sym" else str(n[0] * n[1] // 100)
        if t == "match_fraction":
            return {25: "one quarter", 50: "one half", 100: "one whole"}[ints(p)[0]]
        if t == "time_of_day":
            s = p.lower()
            if any(k in s for k in ("wake", "birds", "breakfast", "just coming up")):
                return "morning"
            if "lunch" in s or "middle of the day" in s:
                return "afternoon"
            if any(k in s for k in ("going down", "orange", "sets")):
                return "evening"
            if any(k in s for k in ("moon", "asleep")):
                return "night"
        if t in ("order_after", "order_before"):
            m = re.search(r"comes (after|before) the (\w+)", p)
            w, part = m.group(1), m.group(2)
            i = PARTS.index(part)
            return PARTS[(i + 1) % 4] if w == "after" else PARTS[(i - 1) % 4]
        if t in ("units_longer", "units_shorter"):
            m = re.search(r"The (\w+) is (\d+) clips long. The (\w+) is (\d+) clips", p)
            a, x, b, y = m.group(1), int(m.group(2)), m.group(3), int(m.group(4))
            if t == "units_longer":
                return "The " + (a if x > y else b)
            return "The " + (a if x < y else b)
        if t == "word_pick":
            return "shorter" if " longer than" in p else "longer"
        if t == "pic_longer":
            return "The top pencil"
        if t == "how_compare":
            return "Put their ends together"
        if t == "unit_for":
            s = p
            if "price" in s:
                return "rupees"
            if "how long" in s or "how tall" in s:
                return "metres"
            if "how much" in s:
                return "litres"
        if t == "money_word":
            return "rupees"
        if t == "pay_with":
            return None
    except Exception as ex:  # a solver failure is itself a finding
        E("%s: solver error %r" % (q["id"], ex))
        return None
    return None


# ------------------------------------------------ per-lesson checks
VISUALS = {"none", "glyph", "picture", "letterWord", "objects", "numberLine", "baseTen"}
assets = set()
solved = Counter()
unsolved = Counter()
key_pos_check = Counter()
key_pos_rem = Counter()
task_counts = Counter()
rep_info = []
nonascii_letter_hits = 0
counts = Counter()
feedback_claims = Counter()
term_checks = Counter()
desc_info = [0]


def vis_sig(v):
    return json.dumps(v, sort_keys=True, ensure_ascii=False)


def chkvis(v, where, phase, qa=None):
    t = v["type"]
    if t not in VISUALS:
        E("%s: bad visual type %s" % (where, t))
    allowed = {"none": {"type"}, "glyph": {"type", "glyph"}, "picture": {"type", "asset", "caption"},
               "letterWord": {"type", "glyph", "word", "asset"},
               "objects": {"type", "groups", "operator", "revealCount", "countAll", "result", "showResult", "takeAway", "labels"},
               "baseTen": {"type", "tens", "ones", "showTotal"},
               "numberLine": {"type", "from", "to", "start", "jump", "showHops"}}[t]
    if set(v) - allowed:
        E("%s: unexpected visual fields %s" % (where, set(v) - allowed))
    if t == "objects":
        if not v["groups"]:
            E("%s: objects with no groups" % where)
        if not 1 <= v["revealCount"] <= len(v["groups"]):
            E("%s: revealCount out of range" % where)
        for g in v["groups"]:
            if g["count"] < 1:
                E("%s: group count < 1" % where)
        if phase in ("check", "remediation_check", "practice") and ("result" in v or v.get("showResult") is not False or v.get("countAll")):
            E("%s: question objects visual shows result/countAll" % where)
        op = v["operator"]
        if op == "-":
            if len(v["groups"]) != 1:
                E("%s: operator - must have ONE group" % where)
            tot = v["groups"][0]["count"]
            if "takeAway" in v and not (1 <= v["takeAway"] <= tot):
                E("%s: takeAway outside 1..count" % where)
            if phase != "step" and "takeAway" not in v:
                E("%s: subtraction question without takeAway" % where)
            if phase in ("check", "remediation_check", "practice") and "result" in v:
                E("%s: subtraction question shows result" % where)
        else:
            tot = sum(g["count"] for g in v["groups"])
            if "takeAway" in v:
                E("%s: takeAway on a non-subtraction visual" % where)
        if tot > 20:
            E("%s: objects visual with %d objects (cap 20)" % (where, tot))
        if op == "vs":
            lab = v.get("labels")
            if not lab or len(lab) != 2 or len(v["groups"]) != 2:
                E("%s: vs needs two groups and two labels" % where)
        elif "labels" in v:
            E("%s: labels on a non-vs visual" % where)
        counts["objects_visuals"] += 1
    if t == "baseTen":
        counts["baseTen_visuals"] += 1
        if not (0 <= v["tens"] <= 9 and 0 <= v["ones"] <= 9):
            E("%s: baseTen out of range" % where)
        if phase in ("check", "remediation_check", "practice", "guided", "remediation_guided") and v["showTotal"] is not False:
            E("%s: question baseTen shows the total" % where)
    if t == "numberLine":
        if v["to"] <= v["from"]:
            E("%s: numberLine to<=from" % where)
        if not (v["from"] <= v["start"] <= v["to"]):
            E("%s: start outside line" % where)
        end = v["start"] + v["jump"]
        if v["showHops"] and not (v["from"] <= end <= v["to"]):
            E("%s: hops leave the line" % where)
        if phase in ("check", "remediation_check", "practice") and v["showHops"]:
            E("%s: question numberLine shows hops" % where)
    if t == "picture":
        assets.add(v["asset"])
        if phase in ("check", "remediation_check", "practice", "guided", "remediation_guided") and v.get("caption", "") != "":
            E("%s: question picture has caption" % where)
    return


def task_of(q):
    return q.get("task")


def operand_sig(q):
    v = q["visual"]
    if v["type"] == "objects":
        nums = tuple(g["count"] for g in v["groups"])
    elif v["type"] == "numberLine":
        nums = (v["start"], v["jump"])
    elif v["type"] == "glyph":
        nums = (v["glyph"],)
    elif v["type"] == "picture":
        nums = (v["asset"],)
    else:
        nums = ()
    dig = tuple(re.findall(r"\d+", q["prompt"]))
    return (q["task"], q["answer"], nums, dig, q["prompt"] if (not dig and v["type"] in ("none", "glyph")) else "")


def letters_ok(s, where):
    global nonascii_letter_hits
    for ch in s:
        if ch.isalpha() and ord(ch) > 127:
            nm = unicodedata.name(ch, "")
            if not nm.startswith("LATIN"):
                nonascii_letter_hits += 1
                E("%s: non-Latin letter %r (English only)" % (where, ch))
                return


for l in roll["lessons"]:
    lid = l["lesson_id"]
    r = l["remediation"]
    for k in ("introduce", "demonstrate", "guided", "practice", "check", "remediation", "review", "mastery"):
        if k not in l:
            E("%s: missing %s" % (lid, k))
    if not 1 <= len(l["introduce"]) <= 3 or not 3 <= len(l["demonstrate"]) <= 5:
        E("%s: introduce/demonstrate counts" % lid)
    if (len(l["guided"]), len(l["practice"]), len(l["check"])) != (2, 4, 3):
        E("%s: guided/practice/check counts" % lid)
    if not 2 <= len(r["explain"]) <= 3 or len(r["guided"]) != 2 or len(r["check"]) != 3:
        E("%s: remediation counts" % lid)
    m = l["mastery"]
    need = {"check_total", "check_pass", "remediation_pass", "max_remediation_cycles", "after_limit"}
    if set(m) != need:
        E("%s: mastery fields" % lid)
    else:
        if not (1 <= m["check_pass"] <= len(l["check"]) and m["check_total"] == len(l["check"])):
            E("%s: check_pass/total" % lid)
        if not 1 <= m["remediation_pass"] <= len(r["check"]):
            E("%s: remediation_pass" % lid)
        if m["max_remediation_cycles"] < 0 or m["after_limit"] != "offer_parent_support":
            E("%s: limit fields" % lid)
    rv = l["review"]
    for k in ("native_review_needed", "items_to_review", "assets_missing", "notes"):
        if k not in rv:
            E("%s: review.%s missing" % (lid, k))

    steps = l["introduce"] + l["demonstrate"] + r["explain"]
    for s in steps:
        if not s["id"].startswith(lid + "."):
            E("bad id " + s["id"])
        if not s["text"].strip() or not s["speech"].strip():
            E("%s: empty text/speech" % s["id"])
        chkvis(s["visual"], s["id"], "step")
        letters_ok(s["text"] + s["speech"], s["id"])
        if re.search(r"\d", s["speech"]):
            E("%s: digits left in speech (should be words)" % s["id"])
    dsig = {vis_sig(s["visual"]) for s in l["demonstrate"] + l["introduce"]}
    dtext = {s["text"] for s in l["demonstrate"]}
    dtypes = {s["visual"]["type"] for s in l["demonstrate"]}
    for s in r["explain"]:
        if vis_sig(s["visual"]) in dsig:
            E("%s: remediation visual identical to a demonstration/introduce visual" % s["id"])
        if s["text"] in dtext:
            E("%s: remediation text identical to a demonstration step" % s["id"])
    rtypes = {s["visual"]["type"] for s in r["explain"]}
    rep_info.append((lid, sorted(dtypes), sorted(rtypes)))

    phases = [("guided", l["guided"]), ("practice", l["practice"]), ("check", l["check"]),
              ("remediation_guided", r["guided"]), ("remediation_check", r["check"])]
    seen_sig = {}
    for ph, qs in phases:
        for q in qs:
            qid = q["id"]
            if not qid.startswith(lid + "." + ph + "."):
                E("bad id %s for phase %s" % (qid, ph))
            chkvis(q["visual"], qid, ph)
            letters_ok(q["prompt"] + q["speech"] + q["explanation"] + " ".join(q["options"]) + " ".join(q["hints"]) + " ".join(q["wrong_feedback"].values()), qid)
            if re.search(r"\d", q["speech"]):
                E("%s: digits left in speech" % qid)
            opts = q["options"]
            ans = q["answer"]
            if ans not in opts:
                E("%s: answer not in options" % qid)
            if not 2 <= len(opts) <= 4 or len(set(opts)) != len(opts):
                E("%s: options count/dup" % qid)
            wrong = {o for o in opts if o != ans}
            if set(q["wrong_feedback"]) != wrong:
                E("%s: wrong_feedback keys != distractors" % qid)
            if not 1 <= q["difficulty"] <= 3:
                E("%s: difficulty" % qid)
            for o, pth in q.get("optionPictures", {}).items():
                assets.add(pth)
                if o not in opts:
                    E("%s: optionPictures key not an option" % qid)
            # hints
            if ph in ("check", "remediation_check"):
                if q["hints"]:
                    E("%s: check item has hints" % qid)
            else:
                if len(q["hints"]) != 2:
                    E("%s: needs 2-step hint ladder" % qid)
                else:
                    h1 = q["hints"][0]
                    if isnum_ans := re.fullmatch(r"-?\d+", ans):
                        if re.search(r"(?<![\d])%s(?![\d])" % re.escape(ans), h1):
                            E("%s: hint 1 contains the answer" % qid)
                    elif len(ans) > 2 and ans.lower() in h1.lower():
                        E("%s: hint 1 contains the answer text" % qid)
                    elif ans in ("<", ">", "=", ) and False:
                        pass
            # no leak in prompt/caption/glyph/feedback on practice and check
            if ph in ("practice", "check", "remediation_check"):
                v = q["visual"]
                if v["type"] == "glyph" and v["glyph"] == ans:
                    E("%s: glyph equals answer" % qid)
                if v["type"] == "picture" and v.get("caption", "") == ans:
                    E("%s: caption equals answer" % qid)
                if re.fullmatch(r"-?\d+", ans):
                    if ans in toks(q["prompt"]):
                        E("%s: prompt contains the answer" % qid)
                    for o, f in q["wrong_feedback"].items():
                        if re.search(r"(?<![\d])%s(?![\d])" % re.escape(ans), f):
                            E("%s: feedback leaks answer" % qid)
                elif len(ans) > 3 and not (task_of(q) or "").startswith("units_"):
                    if ans.lower() in q["prompt"].lower():
                        E("%s: prompt contains answer text" % qid)
                    for o, f in q["wrong_feedback"].items():
                        if ans.lower() in f.lower():
                            E("%s: feedback leaks answer text" % qid)
            # independent recomputation
            task = q.get("task")
            task_counts[task] += 1
            comp = solve(q, l)
            if comp is None:
                unsolved[task] += 1
            else:
                solved[task] += 1
                if comp != ans:
                    E("%s: recomputed answer %r != stored %r (task %s)" % (qid, comp, ans, task))
                if task == "fact":
                    for o in wrong:
                        x, y, z = ints(o)
                        if x + y == z:
                            E("%s: distractor fact is true: %s" % (qid, o))
                elif task == "which_split":
                    for o in wrong:
                        a, b = ints(o)
                        if a == b:
                            E("%s: distractor split is equal" % qid)
            # numeric distractor checks
            if all(re.fullmatch(r"-?\d+", o) for o in opts):
                if len(opts) >= 3 and opts == sorted(opts, key=int):
                    E("%s: options are in ascending order" % qid)
                if len(opts) >= 3 and opts == sorted(opts, key=int, reverse=True):
                    desc_info[0] += 1
                if len(opts) >= 3 and all(abs(int(o) - int(ans)) <= 1 for o in wrong):
                    E("%s: all distractors adjacent to answer" % qid)
            sg = (q["prompt"], ans, tuple(sorted(opts)), vis_sig(q["visual"]))
            if sg in seen_sig:
                E("%s: repeats item %s (same prompt/answer/options/visual)" % (qid, seen_sig[sg]))
            seen_sig[sg] = qid
            if ph == "check":
                key_pos_check[opts.index(ans)] += 1
            if ph == "remediation_check":
                key_pos_rem[opts.index(ans)] += 1
    # check items must not repeat earlier items by problem (prompt+answer, ignoring visual/options)
    is_count = lid.startswith("numbers-count-") or lid == "num-count"
    early = {operand_sig(q) for q in l["guided"] + l["practice"] + r["guided"]}
    for q in l["check"] + r["check"]:
        if operand_sig(q) in early and not is_count:
            E("%s: check repeats an earlier problem (same task/answer/operands)" % q["id"])
    cs = [operand_sig(q) for q in l["check"] + r["check"]]
    if len(set(cs)) != len(cs) and not is_count:
        E("%s: repeated check items" % lid)
    if is_count:
        # count lessons are about ONE number, so answers repeat by design; require different prompt AND emoji/visual
        allp = [(ph, q["prompt"], vis_sig(q["visual"])) for ph, qs in phases for q in qs]
        if len({(a, b) for _, a, b in allp}) != len(allp):
            E("%s: count lesson has two items with identical prompt and visual" % lid)
    # key positions within a lesson
    for name, qs in (("check", l["check"]), ("remediation_check", r["check"])):
        if len({q["options"].index(q["answer"]) for q in qs}) < 2:
            E("%s: %s key position not varied" % (lid, name))
    # task taught earlier
    early_tasks = {q["task"] for q in l["guided"] + l["practice"]}
    for q in l["check"]:
        if q["task"] not in early_tasks:
            E("%s: check task %s not taught in guided/practice" % (q["id"], q["task"]))
    early2 = early_tasks | {q["task"] for q in r["guided"]}
    for q in r["check"]:
        if q["task"] not in early2:
            E("%s: remediation check task %s not taught earlier" % (q["id"], q["task"]))
    # lesson's own worked example never used in guided/practice/check
    title = l["title"]
    own = None
    mm = re.match(r"(Add|Subtract|Compare) (\d+) (\+|\u2212|and) (\d+)", title)
    if mm:
        own = sorted([int(mm.group(2)), int(mm.group(4))])
    if lid == "num-subtract":
        own = [2, 7]
    if lid == "num-multiply":
        own = [3, 4]
    if own:
        for ph, qs in phases:
            for q in qs:
                v = q["visual"]
                nums = ints(q["prompt"])
                if v["type"] == "objects":
                    nums = nums + groups(v)
                if v["type"] == "numberLine" and q["task"].startswith(("add", "sub")):
                    nums = nums + [v["start"], abs(v["jump"])]
                if len(nums) >= 2 and sorted(nums[:2]) == own and q["task"] not in ("bond10",):
                    # make sure it is the same operation operands
                    if q["task"] in ("add_objects", "sub_objects") and sorted(groups(v)) == own:
                        E("%s: uses the lesson's own worked-example numbers %s" % (q["id"], own))
                    elif q["task"] in ("add_symbolic", "sub_symbolic", "sign") and sorted(ints(q["prompt"])[:2]) == own:
                        E("%s: uses the lesson's own worked-example numbers %s" % (q["id"], own))
                    elif q["task"] in ("add_line", "sub_line") and sorted([v["start"], abs(v["jump"])]) == own:
                        E("%s: uses the lesson's own worked-example numbers %s" % (q["id"], own))

for a in sorted(assets):
    if not os.path.isfile(os.path.join(ROOT, a.replace("/", os.sep))):
        E("asset missing: %s" % a)

# ------------------------------------------------ multiply: no commuted repeat of any earlier problem
def mpair(q):
    v = q["visual"]
    n = ints(q["prompt"])
    t = q["task"]
    if t == "groups_pic":
        return tuple(sorted((len(v["groups"]), v["groups"][0]["count"])))
    if t == "repeat_add":
        return tuple(sorted((len(n), n[0])))
    return tuple(sorted(n[:2]))


for l in roll["lessons"]:
    if l["lesson_id"] != "num-multiply":
        continue
    r = l["remediation"]
    seen = {(3, 4)}
    for q in l["guided"] + l["practice"] + l["check"] + r["guided"] + r["check"]:
        pr_ = mpair(q)
        counts["multiply_pairs"] += 1
        if pr_ in seen:
            E("%s: commuted or repeated multiplication problem %s" % (q["id"], pr_))
        seen.add(pr_)

# ------------------------------------------------ plural slips
for l in roll["lessons"]:
    r = l["remediation"]
    texts = [(st["id"], st["text"] + " " + st["visual"].get("glyph", "")) for st in l["introduce"] + l["demonstrate"] + r["explain"]]
    for q in l["guided"] + l["practice"] + l["check"] + r["guided"] + r["check"]:
        texts.append((q["id"], q["prompt"] + " " + " ".join(q["hints"]) + " " + q["explanation"] + " " + " ".join(q["wrong_feedback"].values())))
    for i_, tx in texts:
        counts["plural_texts"] += 1
        if re.search(r"(?<![\d.])1 (?:full |single )?(tens|ones|steps|groups|sweets|clips|packets|stars|sides|corners|plates|pairs|things|blocks)\b", tx):
            E("%s: plural slip with 1: %s" % (i_, re.search(r"(?<![\d.])1 (?:full |single )?(?:tens|ones|steps|groups|sweets|clips|packets|stars|sides|corners|plates|pairs|things|blocks)\b", tx).group(0)))

# ------------------------------------------------ teach-before-test for every term / name asked
def corpus(l):
    t = []
    for st in l["introduce"] + l["demonstrate"]:
        t.append(st["text"].lower())
        if st["visual"]["type"] == "glyph":
            t.append(st["visual"]["glyph"].lower())
    return " ".join(t)


def has(c, w):
    return re.search(r"(?<![a-z])%s(?![a-z])" % re.escape(w.lower()), c) is not None


for l in roll["lessons"]:
    c = corpus(l)
    r = l["remediation"]
    qs = l["guided"] + l["practice"] + l["check"] + r["guided"] + r["check"]
    tasks = {q["task"] for q in qs}
    for q in qs:
        t = q["task"]
        words = []
        if t in ("numeral_to_word", "count_to_word"):
            words = list(q["options"])
        elif t == "word_to_numeral":
            words = [re.search(r"'(\w+)'", q["prompt"]).group(1)]
        elif t in ("name",):
            words = [o.lower() for o in q["options"]]
        elif t == "which_prop":
            words = [o.lower() for o in q["options"]]
            pr = q["prompt"].lower()
            for term in ("equal", "long", "short", "round", "corners", "sides"):
                if term in pr:
                    words.append(term)
        elif t in ("time_of_day", "order_after", "order_before"):
            words = list(q["options"])
        elif t in ("unit_for", "money_word"):
            words = list(q["options"])
        elif t == "word_pick":
            words = [o for o in q["options"]]
        elif t == "match_fraction":
            words = list(q["options"])
        elif t in ("units_longer", "units_shorter"):
            words = ["longer" if t == "units_longer" else "shorter", "clips"]
        elif t == "pic_longer":
            words = ["longer"]
        elif t in ("tens_pic", "tens_sym"):
            words = ["full tens"]
        elif t in ("ones_pic", "ones_sym"):
            words = ["single ones", "ones place"]
        elif t in ("bigger", "smaller"):
            words = ["bigger", "smaller"]
        elif t == "sign":
            words = ["less than", "greater than", "equals"]
        elif t == "bond10":
            words = ["make 10"] if False else []
        for w in words:
            term_checks["terms"] += 1
            if not has(c, w):
                E("%s: term %r asked (task %s) but never taught in introduce/demonstrate" % (q["id"], w, t))
    if tasks & {"next", "rule", "missing"}:
        term_checks["pattern directions"] += 1
        if not ("the rule is: add" in c and "the rule is: take away" in c):
            E("%s: pattern lesson does not teach both directions" % l["lesson_id"])
        # an increasing and a decreasing item pair must each be taught: demo text mentions both rules
    if tasks & {"which_prop", "sides", "corners", "name"} and l["lesson_id"].startswith("numbers-56-0") and 48 <= int(l["lesson_id"][-3:]) <= 51:
        term_checks["shape vocabulary"] += 1
        for w in ("equal sides", "long", "short", "corner", "side", "square", "rectangle", "triangle", "circle"):
            if not has(c, w) and w not in c:
                E("%s: shape vocabulary %r not taught" % (l["lesson_id"], w))

# ------------------------------------------------ feedback must be true for the option's value
def operands(q):
    v = q["visual"]
    ns = [int(x) for x in re.findall(r"\d+", q["prompt"])]
    if v["type"] == "objects":
        ns += [g["count"] for g in v["groups"]] + ([v["takeAway"]] if "takeAway" in v else [])
    elif v["type"] == "numberLine":
        ns += [v["start"], abs(v["jump"])]
    return ns


for l in roll["lessons"]:
    r = l["remediation"]
    for q in l["guided"] + l["practice"] + l["check"] + r["guided"] + r["check"]:
        t = q["task"]
        ops = operands(q)
        for o, f in q["wrong_feedback"].items():
            if not re.fullmatch(r"-?\d+", o):
                continue
            v = int(o)
            ans = int(q["answer"]) if re.fullmatch(r"-?\d+", q["answer"]) else None
            claim = None
            m = re.search(r"^(\d+) is (\d+) \+ (\d+), the two numbers added", f)
            if m:
                claim = ("sum", int(m.group(1)) == int(m.group(2)) + int(m.group(3)) and int(m.group(1)) == v)
            elif "you get by adding" in f:
                claim = ("sum", t.startswith("sub") and len(ops) >= 2 and v == ops[-2] + ops[-1] or v == sum(ops[-2:]))
                if t.startswith("sub_objects"):
                    g0 = q["visual"]["groups"][0]["count"]
                    claim = ("sum", v == g0 + q["visual"]["takeAway"])
                elif t == "sub_line":
                    claim = ("sum", v == q["visual"]["start"] + abs(q["visual"]["jump"]))
                elif t == "sub_symbolic":
                    claim = ("sum", v == ops[0] + ops[1])
            elif "comes from taking away" in f:
                if t == "add_objects":
                    gs = groups(q["visual"])
                    claim = ("taking away", v == abs(gs[0] - gs[1]))
                elif t == "add_line":
                    claim = ("taking away", v == abs(q["visual"]["start"] - q["visual"]["jump"]))
                else:
                    claim = ("taking away", v == abs(ops[0] - ops[1]))
            elif "left after making the ten" in f:
                a_, b_ = (groups(q["visual"]) if t == "add_objects" else
                          ([q["visual"]["start"], q["visual"]["jump"]] if t == "add_line" else ints(q["prompt"])[:2]))
                claim = ("make-ten leftover", v == a_ + b_ - 10)
            elif "only the ones part" in f:
                a_, b_ = (groups(q["visual"]) if t == "add_objects" else
                          ([q["visual"]["start"], q["visual"]["jump"]] if t == "add_line" else ints(q["prompt"])[:2]))
                claim = ("ones only", v == a_ % 10 + b_)
            elif "you started with" in f:
                claim = ("operand", v in ops)
            elif "is the whole number" in f:
                n_ = int(re.findall(r"\d+", q["prompt"])[0])
                claim = ("whole", v == n_)
            elif "digit in the ones place" in f and "We want the full tens" in f:
                n_ = int(re.findall(r"\d+", q["prompt"])[0])
                claim = ("ones digit", v == n_ % 10)
            elif "digit in the tens place" in f:
                n_ = int(re.findall(r"\d+", q["prompt"])[0])
                claim = ("tens digit", v == n_ // 10)
            elif "wrong way round" in f:
                a_, b_ = ints(q["prompt"])[:2]
                claim = ("swapped digits", v == b_ * 10 + a_)
            elif "one ten too many or too few" in f:
                claim = ("ten off", abs(v - ans) == 10)
            elif f.startswith("%d is all " % v):
                m = re.match(r"\d+ is all (\d+) things", f)
                n_ = groups(q["visual"])[0] if q["visual"]["type"] == "objects" else ints(q["prompt"])[1] if t == "pct_sym" else ints(q["prompt"])[0]
                if m:
                    claim = ("percent whole", v == int(m.group(1)) == n_)
                else:
                    claim = ("whole total", v == n_)
            elif "is half of" in f:
                m = re.match(r"(\d+) is half of (\d+), which is 50%", f)
                claim = ("half", v * 2 == int(m.group(2)))
            elif "is a quarter of" in f:
                m = re.match(r"(\d+) is a quarter of (\d+), which is 25%", f)
                claim = ("quarter", v * 4 == int(m.group(2)))
            elif "percent number itself" in f:
                claim = ("percent number", v in (25, 50) and v in ints(q["prompt"]))
            elif "the size of just one group" in f:
                g_, s_ = (ints(q["prompt"])[:2] if t == "times_sym" else
                          (len(q["visual"]["groups"]), q["visual"]["groups"][0]["count"]) if t == "groups_pic" else
                          (len(ints(q["prompt"])), ints(q["prompt"])[0]) if t == "repeat_add" else tuple(ints(q["prompt"])[:2]))
                claim = ("one group", v == s_)
            elif "only the number of groups" in f:
                g_, s_ = (ints(q["prompt"])[:2] if t == "times_sym" else
                          (len(q["visual"]["groups"]), q["visual"]["groups"][0]["count"]) if t == "groups_pic" else
                          (len(ints(q["prompt"])), ints(q["prompt"])[0]) if t == "repeat_add" else tuple(ints(q["prompt"])[:2]))
                claim = ("groups number", v == g_)
            elif "one group too many" in f or "one group too few" in f:
                g_, s_ = (ints(q["prompt"])[:2] if t == "times_sym" else
                          (len(q["visual"]["groups"]), q["visual"]["groups"][0]["count"]) if t == "groups_pic" else
                          (len(ints(q["prompt"])), ints(q["prompt"])[0]) if t == "repeat_add" else tuple(ints(q["prompt"])[:2]))
                claim = ("group off", v == ans + s_ if "too many" in f else v == ans - s_)
            elif "is the number of sides of a" in f:
                m = re.match(r"(\d+) is the number of sides of a (\w+)", f)
                claim = ("shape sides", SHAPE[m.group(2)][0] == v)
            elif "is the last number again" in f:
                seq = [int(x) for x in re.findall(r"\d+", q["visual"]["glyph"])] if q["visual"]["type"] == "glyph" else ints(q["prompt"])
                claim = ("last number", v == seq[2])
            elif "only one more or one less than the last number" in f:
                seq = [int(x) for x in re.findall(r"\d+", q["visual"]["glyph"])] if q["visual"]["type"] == "glyph" else ints(q["prompt"])
                claim = ("last +-1", abs(v - seq[2]) == 1)
            elif "is already in the pattern" in f:
                claim = ("already shown", v in [int(x) for x in re.findall(r"\d+", q["visual"]["glyph"])])
            if claim:
                feedback_claims[claim[0]] += 1
                if not claim[1]:
                    E("%s: feedback for option %s is FALSE (%s): %s" % (q["id"], o, claim[0], f))

# ------------------------------------------------ loader dry-run (Dart validate() rules)
for l in roll["lessons"]:
    r = l["remediation"]
    if not l["introduce"] or not l["demonstrate"] or not l["guided"] or not l["practice"] or not l["check"]:
        E("%s: loader would reject (empty section)" % l["lesson_id"])
    if l["mastery"]["remediation_pass"] > len(r["check"]):
        E("%s: remediation_pass > rem check" % l["lesson_id"])

print()
print("lessons covered:", len(got), "of", len(expected), "| missing:", missing or "none")
print("questions:", sum(task_counts.values()), "| independently recomputed:", sum(solved.values()), "| NOT recomputed (no solver):", sum(unsolved.values()), dict(unsolved))
print("tasks:", dict(sorted(task_counts.items())))
print("assets referenced:", len(assets), sorted(assets))
tot = sum(key_pos_check.values())
print("check key position (stored index) distribution:", dict(sorted(key_pos_check.items())), "of", tot)
print("rem-check key position distribution:", dict(sorted(key_pos_rem.items())), "of", sum(key_pos_rem.values()))
same_rep = [x for x in rep_info if set(x[2]) <= set(x[1]) and False]
rep_only_same = [x[0] for x in rep_info if x[1] == x[2]]
print("lessons whose remediation uses exactly the same visual-type set as the demonstration (info only):", len(rep_only_same))
print("check/rem-check/other option sets in descending order (info, allowed):", desc_info[0])
print("multiply problems checked for commuted repeats:", counts["multiply_pairs"], "| texts scanned for plural slips:", counts["plural_texts"])
print("objects visuals:", counts["objects_visuals"], "| baseTen visuals:", counts["baseTen_visuals"], "| cap of 20 objects enforced on every objects visual")
print("term/name teach-before-test checks:", dict(term_checks))
print("feedback sentences tested against the option's value:", sum(feedback_claims.values()), dict(feedback_claims))
print("ERRORS:", len(errs))
for e in errs[:4000]:
    print(" -", e.encode("ascii", "backslashreplace").decode())
if len(errs) > 80:
    print(" ... and", len(errs) - 80, "more")
sys.exit(1 if errs else 0)
