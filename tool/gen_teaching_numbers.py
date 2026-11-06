# -*- coding: utf-8 -*-
"""Generator for content/teaching_pending/rollout_numbers.json (the source). The bundled copy content/teaching/rollout_numbers.json is written ONLY by promote(), after tool/check_rollout_numbers.py and the Dart parser test pass (rollout batch R1, Number Galaxy).

Written by content-creator. Status of the output: rollout_unverified.
Run:  python -X utf8 -I tool/gen_teaching_numbers.py

Every answer is computed here by code (never typed by hand). One template per
skill; each lesson gets its own numbers from its existing title/source.
Visual types used: objects, numberLine, glyph, picture, none (see
content/teaching/SCHEMA.md). English only.
"""
import json, os, random, re, sys

ROOT = r"E:\Aksharamala"
OUT = os.path.join(ROOT, "content", "teaching_pending", "rollout_numbers.json")  # the source
BUNDLED = os.path.join(ROOT, "content", "teaching", "rollout_numbers.json")  # written only by promote()
SRC56 = os.path.join(ROOT, "content", "age56", "numbers_age_5_6.json")

MASTERY = {"check_total": 3, "check_pass": 2, "remediation_pass": 2,
           "max_remediation_cycles": 2, "after_limit": "offer_parent_support"}

# ----------------------------------------------------------------- helpers
SMALL = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
         "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
         "sixteen", "seventeen", "eighteen", "nineteen"]
TENSW = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
         "eighty", "ninety"]


def nw(n):
    if n < 20:
        return SMALL[n]
    if n < 100:
        return TENSW[n // 10] + ("-" + SMALL[n % 10] if n % 10 else "")
    if n == 100:
        return "one hundred"
    return str(n)


def say(t):
    t = t.replace("\u2212", " minus ").replace("+", " plus ").replace("\u00d7", " times ")
    t = t.replace("\u00f7", " divided by ").replace("\u00bd", "one half ")
    t = t.replace("=", " equals ").replace("<", " is less than ").replace(">", " is greater than ")
    t = t.replace("%", " percent").replace("__", " blank ").replace("\u20b9", " rupees ")
    t = re.sub(r"\d+", lambda m: nw(int(m.group(0))), t)
    t = t.replace("\u2192", ",")
    return re.sub(r"\s+", " ", t).replace(" ,", ",").strip()


def seq_on(a, b):
    return ", ".join(str(a + i) for i in range(1, b + 1))


def seq_back(a, b):
    return ", ".join(str(a - i) for i in range(1, b + 1))


def obj(groups, reveal=None, countAll=False, op="+", result=None, q=False, take=None, labels=None):
    """objects visual. Cap: at most 20 objects in total across groups. operator "-" is ONE group
    with `takeAway` objects crossed out; operator "vs" carries `labels` for its two rows."""
    if op == "-":
        assert len(groups) == 1, "operator - needs ONE group"
        total = groups[0][1]
        assert take is None or take <= total
    else:
        total = sum(c for _, c in groups)
    assert total <= 20, "objects visual with %d objects" % total
    v = {"type": "objects",
         "groups": [{"emoji": e, "count": c} for e, c in groups],
         "operator": op, "revealCount": reveal or len(groups), "countAll": countAll}
    if take is not None:
        v["takeAway"] = take
    if labels is not None:
        v["labels"] = list(labels)
    if result is not None:
        v["result"] = result
        v["showResult"] = True
    elif q:
        v["showResult"] = False
    return v


def base10(n, show=False):
    """baseTen visual: one ten-bar per ten, single cubes for the ones."""
    return {"type": "baseTen", "tens": n // 10, "ones": n % 10, "showTotal": show}


class AnyKind(dict):
    """feedback table that answers every distractor kind with one function of the option value"""

    def __init__(self, f):
        super().__init__()
        self.f = f

    def __getitem__(self, k):
        return self.f


def line(frm, to, start, jump, hops):
    return {"type": "numberLine", "from": frm, "to": to, "start": start,
            "jump": jump, "showHops": hops}


def glyph(g):
    return {"type": "glyph", "glyph": fixp(g)}


def pic(asset, caption=""):
    return {"type": "picture", "asset": asset, "caption": caption}


NONE = {"type": "none"}

EMOJI = ["\U0001F34E", "\u2B50", "\U0001F31F", "\U0001F680", "\U0001F353",
         "\U0001F319", "\U0001F48E", "\U0001F34C", "\U0001F41F", "\U0001F36A",
         "\U0001F388", "\U0001F34A"]


class Ctx:
    def __init__(self, lid, idx):
        self.lid = lid
        self.idx = idx
        self.rng = random.Random("R1|" + lid)
        e = EMOJI[:]
        self.rng.shuffle(e)
        self.E = e  # demo=E[0], rem explain=E[1], guided E[2:4], practice E[4:8], check E[8:11]

    def emo(self, role, i=0):
        role = {"remediation_guided": "remg", "remediation_check": "remc"}.get(role, role)
        base = {"demo": 0, "rem": 1, "guided": 2, "practice": 4, "check": 8, "remg": 5,
                "remc": 9}[role]
        return self.E[(base + i) % len(self.E)] if role not in ("check", "remc") else \
            [x for x in self.E[8:] + self.E[1:2]][i % 4]


class Pool:
    def __init__(self, items, rng):
        self.items = list(items)
        self.rng = rng

    def take(self, *preds, remove=lambda x: [x]):
        for p in list(preds) + [None]:
            c = [x for x in self.items if (p is None or p(x))]
            if c:
                x = self.rng.choice(c)
                for r in remove(x):
                    if r in self.items:
                        self.items.remove(r)
                return x
        raise RuntimeError("pool exhausted")


def pick_dist(rng, ans, cands, lo=0, hi=10 ** 6, n=2):
    """cands: kind -> list of ints. Returns n (value, kind) all != ans, distinct,
    preferring different kinds and avoiding two neighbours of the answer."""
    valid = {}
    for k, vs in cands.items():
        vv = []
        for v in vs:
            if v != ans and lo <= v <= hi and v not in vv:
                vv.append(v)
        if vv:
            valid[k] = vv
    kinds = list(valid)
    rng.shuffle(kinds)
    chosen, used = [], set()

    def adj(v):
        return abs(v - ans) <= 1

    for relax in (False, True):
        for k in kinds:
            if len(chosen) == n:
                break
            vs = [v for v in valid[k] if v not in used]
            if not vs:
                continue
            v = rng.choice(vs)
            if not relax and adj(v) and any(adj(c[0]) for c in chosen):
                continue
            if any(c[1] == k for c in chosen) and not relax:
                continue
            chosen.append((v, k))
            used.add(v)
        if len(chosen) == n:
            break
    if len(chosen) < n:
        raise RuntimeError("not enough distractors for %r %r" % (ans, cands))
    return chosen


SING = {"tens": "ten", "ones": "one", "steps": "step", "groups": "group", "sweets": "sweet", "clips": "clip",
        "packets": "packet", "stars": "star", "sides": "side", "corners": "corner", "plates": "plate",
        "pairs": "pair", "things": "thing", "blocks": "block", "rocks": "rock", "apples": "apple",
        "mangoes": "mango", "pencils": "pencil", "marbles": "marble", "stickers": "sticker"}


def fixp(t):
    return re.sub(r"(?<![\d.])1 ((?:full |single )?)(%s)\b" % "|".join(SING), lambda m: "1 " + m.group(1) + SING[m.group(2)], t)


def step(lid, sec, i, text, visual, speech=None):
    text = fixp(text)
    return {"id": "%s.%s.%d" % (lid, sec, i), "text": text,
            "speech": say(fixp(speech)) if speech is not None else say(text), "visual": visual}


def isnum(s):
    return re.fullmatch(r"-?\d+", s) is not None


def mkq(ctx, phase, i, spec, kp):
    """Turn a question spec into the schema's QUESTION. All options and feedback
    come from the spec's computed distractors."""
    rng = random.Random("%s|%s|%d" % (ctx.lid, phase, i))
    ans = str(spec["answer"])
    dist = [(str(v), k) for v, k in spec["dist"]]
    rng.shuffle(dist)
    n = len(dist) + 1
    kp %= n

    def lay(d):
        o = [x for x, _ in d]
        o.insert(kp, ans)
        return o

    opts = lay(dist)
    if len(opts) >= 3 and all(isnum(x) for x in opts):
        t = 0
        while (opts == sorted(opts, key=int) or opts == sorted(opts, key=int, reverse=True)) and t < 12:
            rng.shuffle(dist)
            opts = lay(dist)
            t += 1
        if opts == sorted(opts, key=int):
            dist = dist[::-1]
            opts = lay(dist)

    wf = {}
    for v, k in dist:
        f = spec["fb"][k]
        wf[v] = f(v) if callable(f) else f.format(d=v)
    wf = {k: fixp(v) for k, v in wf.items()}
    pr = fixp(spec["prompt"])
    q = {"id": "%s.%s.%d" % (ctx.lid, phase, i), "prompt": pr,
         "speech": say(fixp(spec["speech"])) if spec.get("speech") else say(pr),
         "options": opts, "answer": ans, "visual": spec["visual"],
         "hints": [] if phase in ("check", "remediation_check") else [fixp(h) for h in spec["hints"]],
         "wrong_feedback": wf, "explanation": fixp(spec["expl"]),
         "difficulty": spec.get("diff", 2), "task": spec["task"]}
    if spec.get("optionPictures"):
        q["optionPictures"] = spec["optionPictures"]
    return q


# generic feedback texts, by kind
FB = {
    "start": "{d} is one of the numbers you started with. We want the answer to the whole problem.",
    "near": "Close, but not quite. Go back over it one step at a time.",
    "far": "That is a long way from the answer. Use the objects or the number line to work it out.",
    "whole": "{d} is the whole number. We want just the part the question asks for.",
    "wrong_op": "{d} comes from using the other operation. Read the sign again.",
}


def kp_for(ctx, phase, i):
    off = {"guided": 0, "practice": 1, "check": 0, "remediation_guided": 2,
           "remediation_check": 1}[phase]
    return (ctx.idx + i + off) % 3


# ------------------------------------------------------- skill: COUNT 0-10
def build_count(ctx, n, hi, pool_nums, legacy=False):
    """Number n lesson (numbers-count-00n) or the legacy 'num-count' (n=3, hi=5)."""
    rng = ctx.rng
    wrd = nw(n)
    thing = "star" if n == 1 else "stars"
    e0 = ctx.emo("demo")
    partner = n + 1 if n < hi else n - 1
    ask_big = (n % 2 == 0)
    lo_n = 0 if not legacy else 1
    zero = (n == 0)

    intro, demo, remx = [], [], []
    L = ctx.lid
    if zero:
        intro.append(step(L, "introduce", 1,
                          "This is the number 0. Zero means none at all: nothing is there.", glyph("0")))
        intro.append(step(L, "introduce", 2,
                          "A number line shows the numbers in order. Zero is where it starts.",
                          line(0, hi, 0, 1, False)))
        demo.append(step(L, "demonstrate", 1,
                         "Here is an empty box. How many stars are in it? None. There are 0 stars.", glyph("0")))
        demo.append(step(L, "demonstrate", 2,
                         "Now one star goes in. Now there is 1. When we take it out, we are back to none, which is 0.",
                         obj([(e0, 1)], 1, True)))
        demo.append(step(L, "demonstrate", 3,
                         "On the number line, we start at 0 and we have not moved at all. 0 is the first number.",
                         line(0, hi, 0, 0, True)))
    else:
        intro.append(step(L, "introduce", 1,
                          "This is the number %d. We say: %s." % (n, wrd), glyph(str(n))))
        intro.append(step(L, "introduce", 2,
                          "A number line shows the numbers in order, from 0 to %d. Bigger numbers are further to the right." % hi,
                          line(0, hi, 0, 1, False)))
        txt = ", ".join(str(k) for k in range(1, n + 1))
        demo.append(step(L, "demonstrate", 1,
                         "Count the things one by one, touching each one only once: %s. There are %d." % (txt, n),
                         obj([(e0, n)], 1, True)))
        e1 = ctx.emo("demo", 3)
        demo.append(step(L, "demonstrate", 2,
                         "Other things can be counted too. Here are %d more things. Count: %s. It is the same number, %d." % (n, txt, n),
                         obj([(e1, n)], 1, True)))
        demo.append(step(L, "demonstrate", 3,
                         "On the number line, start at 0 and take %d steps. We land on %d." % (n, n),
                         line(0, hi, 0, n, True)))
    # compare demo (the lesson's own partner)
    a, b = min(n, partner), max(n, partner)
    word_ask = "bigger" if ask_big else "smaller"
    ansc = b if ask_big else a
    demo.append(step(L, "demonstrate", len(demo) + 1,
                     "Which number is %s, %d or %d? On the number line, the number further to the right is bigger. So %d is %s."
                     % (word_ask, n, partner, ansc, word_ask),
                     line(0, hi, a, b - a, True)))
    # ---- remediation explain (different representation)
    e1 = ctx.emo("rem")
    if zero:
        remx.append(step(L, "remediation_explain", 1,
                         "Let us try again with a story. A plate has no apples on it. We can say: zero apples.",
                         glyph("0 apples")))
        remx.append(step(L, "remediation_explain", 2,
                         "Now one apple is put on the plate. 1 apple. Take it off again and there are none: 0.",
                         obj([(e1, 1)], 1, True)))
        remx.append(step(L, "remediation_explain", 3,
                         "On the number line, 0 is the very first number. Nothing is before it.",
                         line(0, hi, 0, 0, False)))
    else:
        s1 = n // 2 if n > 1 else n
        s2 = n - s1
        if s2 == 0:
            g = [(e1, n)]
        else:
            g = [(e1, s1), (e1, s2)]
        remx.append(step(L, "remediation_explain", 1,
                         "Let us count in two parts. Here are the first %d. Say %d." % (g[0][1], g[0][1]),
                         obj(g, 1, False)))
        if len(g) == 2:
            remx.append(step(L, "remediation_explain", 2,
                             "Now the other %d. Keep %d in your head and count on: %s. Altogether, %d." % (g[1][1], g[0][1], seq_on(g[0][1], g[1][1]), n),
                             obj(g, 2, False)))
        else:
            remx.append(step(L, "remediation_explain", 2,
                             "There is just 1. Say 1. It is the number 1.", obj(g, 1, True)))
        remx.append(step(L, "remediation_explain", 3,
                         "Show %d with your fingers and find %d on the number line. It is %s." % (n, n, wrd),
                         line(0, hi, n, 0, False)))
    # ---- question specs
    ctr = {"c": 0, "l": 0, "k": 0}
    COUNT_P = ["How many are there?", "Count them. How many?", "How many can you see?", "How many things are in this group?",
               "Count carefully. How many are there?", "Touch and count. How many?", "How many are in the picture?", "Tell how many there are."]
    LINE_P = ["What number is the marker on?", "Which number is the marker pointing at?", "The marker sits on a number. Which one?",
              "Where is the marker? Pick the number.", "Read the number under the marker.", "Which number has the marker on it?"]
    ZERO_P = ["A plate has no apples on it. How many apples are on the plate?", "There are no birds in the tree. How many birds are in the tree?",
              "The basket is empty. How many mangoes are in the basket?", "The box has nothing in it. How many toys are in the box?",
              "No stars are in the sky tonight. How many stars can you see?", "The cup is empty. How many sweets are in the cup?",
              "The nest has no eggs. How many eggs are in the nest?", "The bag has nothing inside. How many balls are in the bag?"]

    def count_spec(m, role, i, scaffold):
        e = ctx.emo(role, i)
        th = "star" if m == 1 else "stars"
        if m == 0:
            sc = ZERO_P[(ctr["c"] + ctx.idx) % len(ZERO_P)]
            ctr["c"] += 1
            vis = NONE
            ptxt = sc
        else:
            vis = obj([(e, m)], 1, False, q=True)
            ptxt = COUNT_P[(ctr["c"] + ctx.idx) % len(COUNT_P)]
            ctr["c"] += 1
        cands = {"near": [m - 1, m + 1], "far": [m + 3, m - 3, m + 4], "other": [m + 2, m - 2]}
        dist = pick_dist(rng_i(ctx, role, i), m, cands, 0 if not legacy else 1, hi)
        return {"task": "count", "prompt": ptxt, "visual": vis, "answer": m, "dist": dist,
                "fb": {"near": "Almost. Count again and touch each one only once.",
                       "far": "That is quite far off. Touch each one as you say the numbers.",
                       "other": "Not quite. Count again, one at a time."},
                "hints": ["Touch each one only once as you say the numbers." if m > 0 else "Look inside. Is anything there?",
                          ("Count: " + ", ".join(str(k) for k in range(1, m + 1)) + ". There are %d." % m)
                          if m > 0 else "Nothing is there, so the number is 0."],
                "expl": ("There are %d, so the answer is %d." % (m, m)) if m > 0 else "Nothing is there, so the answer is 0.",
                "diff": 1}

    def line_spec(m, role, i, scaffold):
        cands = {"near": [m - 1, m + 1], "far": [m + 3, m - 3, m + 4], "other": [m + 2, m - 2]}
        dist = pick_dist(rng_i(ctx, role, i), m, cands, 0 if not legacy else 0, hi)
        if scaffold:
            vis = line(0, hi, 0, m, True)
            prompt = "We start at 0 and take %d steps. Which number do we land on?" % m
        else:
            vis = line(0, hi, m, 0, False)
            prompt = LINE_P[(ctr["l"] + ctx.idx) % len(LINE_P)]
            ctr["l"] += 1
        return {"task": "line", "prompt": prompt, "visual": vis, "answer": m, "dist": dist,
                "fb": {"near": "Close. Count the steps from the start of the line one at a time.",
                       "far": "That is a long way from the marker. Count along the line from the start.",
                       "other": "Not quite. Start at the left end and count the steps along the line."},
                "hints": ["Start at the left end of the line and count each step along the line.",
                          "Count: " + ", ".join(str(k) for k in range(0, m + 1)) + ". The marker is on %d." % m],
                "expl": "The marker is on %d." % m, "diff": 1 if scaffold else 2}

    def cmp_spec(role, i, big):
        r = rng_i(ctx, role, i)
        others = [k for k in range(0 if not legacy else 1, hi + 1) if k != n]
        r.shuffle(others)
        trio = [n, others[0], others[1]]
        ans = max(trio) if big else min(trio)
        wrong = [x for x in trio if x != ans]
        word = "biggest" if big else "smallest"
        side = "right" if big else "left"
        CP = ["Which number is the %s?", "Which of these numbers is the %s?", "Pick the %s number.", "Find the %s number."]
        cp = CP[(ctr["k"] + ctx.idx) % len(CP)] % word
        ctr["k"] += 1
        return {"task": "compare3", "prompt": cp,
                "visual": NONE, "answer": ans,
                "dist": [(w, "notbest") for w in wrong],
                "fb": {"notbest": lambda d, side=side, word=word: "%s is not the %s. On the number line, the %s number is the one furthest to the %s." % (d, word, word, side)},
                "hints": ["Think of the number line. The %s number is furthest to the %s." % (word, side),
                          "Look at each number on the line. The %s one is %d." % (word, ans)],
                "expl": "%d is the %s of the three numbers." % (ans, word), "diff": 2}

    near_m = [k for k in (n - 1, n + 1, n - 2, n + 2) if (0 if not legacy else 1) <= k <= hi and k != n]
    r0 = ctx.rng
    m_other = near_m[(ctx.idx) % len(near_m)] if not zero else 1
    if legacy:
        m_other = [2, 1, 4][ctx.idx % 3]
    guided = [count_spec(n, "guided", 0, True), line_spec(n, "guided", 1, True)]
    practice = [count_spec(m_other, "practice", 0, False),
                line_spec(n, "practice", 1, False),
                cmp_spec("practice", 2, not ask_big),
                count_spec(n, "practice", 3, False)]
    rot = ctx.idx % 3
    chk = [count_spec(n, "check", 0, False), line_spec(n, "check", 1, False), cmp_spec("check", 2, ask_big)]
    chk = chk[rot:] + chk[:rot]
    rg = [count_spec(m_other, "remg", 0, False), line_spec(m_other, "remg", 1, True)]
    rc = [count_spec(n, "remc", 1, False), line_spec(n, "remc", 2, False), cmp_spec("remc", 3, not ask_big)]
    return dict(intro=intro, demo=demo, guided=guided, practice=practice, check=chk,
                remx=remx, remg=rg, remc=rc)


def rng_i(ctx, role, i):
    return random.Random("%s|%s|%d|d" % (ctx.lid, role, i))


# ------------------------------------------------------------- skill: ADD
def build_add(ctx, A, B, M=20):
    rng = ctx.rng
    L = ctx.lid
    S = A + B
    make_ten = A < 10 and B < 10
    own = {(A, B), (B, A)}
    if make_ten:
        pool = Pool([(a, b) for a in range(2, 10) for b in range(2, 10) if 10 <= a + b <= 18 and (a, b) not in own], rng)
    else:
        pool = Pool([(a, b) for a in range(11, 18) for b in range(1, 10) if a + b <= 20 and (a, b) not in own], rng)

    def draw(lo, hi, pred=None):
        ps = []
        if pred:
            ps.append(lambda p: lo <= sum(p) <= hi and pred(p))
        ps.append(lambda p: lo <= sum(p) <= hi)
        ps.append(lambda p: abs(sum(p) - (lo + hi) / 2) <= 4)
        return pool.take(*ps, remove=lambda p: [p, (p[1], p[0])])

    intro, demo, remx = [], [], []
    e0 = ctx.emo("demo")
    intro.append(step(L, "introduce", 1,
                      "Today we add numbers up to 20. A number line can go all the way from 0 to 20.",
                      line(0, 20, 0, 1, False)))
    if make_ten:
        intro.append(step(L, "introduce", 2,
                          "A full ten is 10 ones. A full ten is quick: we just say 10.",
                          obj([(e0, 10)], 1, True)))
        t = 10 - A
        r = S - 10
        demo.append(step(L, "demonstrate", 1, "Here are %d things." % A, obj([(e0, A), (e0, B)], 1)))
        demo.append(step(L, "demonstrate", 2,
                         "Now we add %d more. Counting every one again is slow. Let us make a ten instead." % B,
                         obj([(e0, A), (e0, B)], 2)))
        if r > 0:
            demo.append(step(L, "demonstrate", 3,
                             "%d needs %d more to make 10. Take %d from the %d and put them with the %d. Now we have 10 and %d left over."
                             % (A, t, t, B, A, r), obj([(e0, A), (e0, t), (e0, r)], 3)))
            demo.append(step(L, "demonstrate", 4,
                             "10 and %d more make %d. So %d + %d = %d." % (r, S, A, B, S),
                             obj([(e0, 10), (e0, r)], 2, result=S)))
        else:
            demo.append(step(L, "demonstrate", 3,
                             "%d and %d together make exactly 10, a full ten. That is a number bond to ten." % (A, B),
                             obj([(e0, 10)], 1, True)))
            demo.append(step(L, "demonstrate", 4, "So %d + %d = %d." % (A, B, S), glyph("%d + %d = %d" % (A, B, S))))
    else:
        o = A - 10
        os_ = o + B
        if o == 0:
            intro.append(step(L, "introduce", 2, "A full ten is 10 ones. The number 10 is one ten and no ones.",
                              obj([(e0, 10)], 1, True)))
            demo.append(step(L, "demonstrate", 1, "Here is %d: one full ten and no ones." % A, obj([(e0, 10), (e0, B)], 1)))
            demo.append(step(L, "demonstrate", 2, "Now we add %d more things." % B, obj([(e0, 10), (e0, B)], 2)))
            demo.append(step(L, "demonstrate", 3,
                             "There are no ones in %d yet, so the %d ones just join the ten: 10 and %d." % (A, B, B),
                             obj([(e0, 10), (e0, B)], 2, result=S)))
            demo.append(step(L, "demonstrate", 4, "10 and %d make %d. So %d + %d = %d." % (B, S, A, B, S), glyph("%d + %d = %d" % (A, B, S))))
        else:
            intro.append(step(L, "introduce", 2,
                              "A number like %d is a ten and some ones. %d is 10 and %d." % (A, A, o),
                              obj([(e0, 10), (e0, o)], 2)))
            demo.append(step(L, "demonstrate", 1, "Here are %d things: a ten and %d ones." % (A, o),
                             obj([(e0, 10), (e0, o), (e0, B)], 2)))
            demo.append(step(L, "demonstrate", 2, "Now we add %d more things." % B,
                             obj([(e0, 10), (e0, o), (e0, B)], 3)))
            demo.append(step(L, "demonstrate", 3,
                             "Add the ones first: %d + %d = %d.%s" % (o, B, os_, " That makes another ten." if os_ == 10 else ""),
                             obj([(e0, o), (e0, B)], 2, result=os_)))
            demo.append(step(L, "demonstrate", 4, "Now put the ten back: 10 + %d = %d. So %d + %d = %d." % (os_, S, A, B, S),
                             obj([(e0, 10), (e0, os_)], 2, result=S)))
    demo.append(step(L, "demonstrate", 5,
                     "Check on the number line: start at %d and count on %d steps. We land on %d." % (A, B, S),
                     line(0, 20, A, B, True)))

    # ---- specs
    used_bond = set()
    used_ones = set()

    def hint2(a, b):
        s = a + b
        if a < 10 and b < 10 and s > 10:
            return "Make a ten: %d needs %d more. Take %d from %d. 10 and %d make %d." % (a, 10 - a, 10 - a, b, s - 10, s)
        if a < 10 and b < 10:
            return "%d and %d make a full ten: %d." % (a, b, s)
        return "%d is 10 and %d. Add the ones: %d + %d = %d. Then add the ten: %d." % (a, a - 10, a - 10, b, a - 10 + b, s)

    def cands(a, b):
        s = a + b
        c = {"start": [a, b], "near": [s - 1, s + 1, s - 2, s + 2],
             "wrong_op": [abs(a - b)] if a != b else [], "far": [s + 10, s - 5, s + 4]}
        if make_ten:
            c["carry"] = [s - 10] if s > 10 else []
        else:
            c["carry"] = [(a % 10) + b]
        return c

    fb_add = {
        "start": FB["start"], "near": "Close, but not quite. Go back over it one step at a time.",
        "far": "That is a long way from the answer. Use the objects or the number line.",
        "wrong_op": "{d} comes from taking away. Here we are adding the two numbers.",
        "carry": ("{d} is what is left after making the ten. The ten has to be added back." if make_ten
                  else "{d} is only the ones part. The ten has to be added as well."),
    }

    def spec_obj(p, role, i, diff):
        a, b = p
        s = a + b
        e = ctx.emo(role, i)
        return {"task": "add_objects", "prompt": "How many altogether?",
                "speech": "%s plus %s. How many altogether?" % (nw(a), nw(b)),
                "visual": obj([(e, a), (e, b)], 2, q=True), "answer": s,
                "dist": pick_dist(rng_i(ctx, role, i), s, cands(a, b), 0, 29),
                "fb": fb_add,
                "hints": ["Count the first group. Then count on the second group.", hint2(a, b)],
                "expl": "%d and %d more make %d altogether, so %d + %d = %d." % (a, b, s, a, b, s), "diff": diff}

    def spec_line(p, role, i, diff, hops):
        a, b = p
        s = a + b
        return {"task": "add_line", "prompt": "%d + %d = ?" % (a, b),
                "speech": "%s plus %s. Use the number line. What number is it?" % (nw(a), nw(b)),
                "visual": line(0, 20, a, b, hops), "answer": s,
                "dist": pick_dist(rng_i(ctx, role, i), s, cands(a, b), 0, 29), "fb": fb_add,
                "hints": ["Put your finger on %d. Count on %d steps to the right, one at a time." % (a, b),
                          "Count on from %d: %s." % (a, seq_on(a, b))],
                "expl": "Start at %d, count on %d steps and you land on %d, so %d + %d = %d." % (a, b, s, a, b, s),
                "diff": diff}

    def spec_sym(p, role, i, diff):
        a, b = p
        s = a + b
        h1 = ("Keep the bigger number in your head and count on the smaller one." if make_ten
              else "Add the ones first, then put the ten back.")
        return {"task": "add_symbolic", "prompt": "%d + %d = ?" % (a, b),
                "speech": "%s plus %s equals what?" % (nw(a), nw(b)), "visual": NONE, "answer": s,
                "dist": pick_dist(rng_i(ctx, role, i), s, cands(a, b), 0, 29), "fb": fb_add,
                "hints": [h1, hint2(a, b)],
                "expl": "%d + %d = %d." % (a, b, s), "diff": diff}

    def spec_bond(role, i):
        choices = [x for x in range(1, 10) if x not in used_bond and x != 10 - B and x != 10 - A]
        a = rng_i(ctx, role, i).choice(choices)
        used_bond.add(a)
        ans = 10 - a
        return {"task": "bond10", "prompt": "%d + ? = 10" % a,
                "speech": "%s plus what makes ten?" % nw(a),
                "visual": line(0, 10, a, 0, False), "answer": ans,
                "dist": pick_dist(rng_i(ctx, role, i), ans, {"start": [a], "near": [ans - 1, ans + 1], "far": [ans + 3, ans - 3, 10]}, 0, 10),
                "fb": {"start": "{d} is the number you started with. How many MORE do you need to reach 10?",
                       "near": "Close. Count on from %d to 10 one step at a time." % a if False else "Close. Count the steps up to 10 one at a time.",
                       "far": "That is a long way off. Count the steps from the marker to 10."},
                "hints": ["Look at where the marker is. How many steps does it take to reach 10?",
                          "%d + %d = 10." % (a, ans)],
                "expl": "%d needs %d more to make 10, so %d + %d = 10." % (a, ans, a, ans), "diff": 2}

    def spec_ones(role, i, p):
        a, b = p
        o = a - 10
        ans = o + b
        e = ctx.emo(role, i)
        return {"task": "add_ones", "prompt": "In %d + %d, add the ones first. What is %d + %d?" % (a, b, o, b),
                "speech": "In %s plus %s, add the ones first. What is %s plus %s?" % (nw(a), nw(b), nw(o), nw(b)),
                "visual": obj([(e, o), (e, b)], 2, q=True), "answer": ans,
                "dist": pick_dist(rng_i(ctx, role, i), ans, {"start": [o, b], "whole": [a + b], "near": [ans - 1, ans + 1], "far": [ans + 3, ans - 3]}, 0, 29),
                "fb": {"start": FB["start"], "whole": "{d} is the answer to the whole problem. Here we only add the ones.",
                       "near": "Close. Count on from the ones digit one step at a time.", "far": "That is a long way off. Count on from the ones digit."},
                "hints": ["Look only at the ones digit of %d. Count on %d from it." % (a, b),
                          "%d + %d = %d." % (o, b, ans)],
                "expl": "The ones are %d and %d: %d + %d = %d." % (o, b, o, b, ans), "diff": 2}

    def one_or_bond(role, i):
        if make_ten:
            return spec_bond(role, i)
        p = draw(11, 19)
        return spec_ones(role, i, p)

    g = [spec_obj(draw(10, 13), "guided", 0, 1), spec_line(draw(10, 14), "guided", 1, 1, True)]
    pr = [one_or_bond("practice", 0), spec_obj(draw(12, 15), "practice", 1, 2),
          spec_line(draw(13, 16), "practice", 2, 2, False), spec_sym(draw(14, 18), "practice", 3, 3)]
    ck_all = [lambda i: spec_obj(draw(12, 18), "check", i, 2), lambda i: spec_line(draw(13, 18), "check", i, 2, False),
              lambda i: spec_sym(draw(12, 19), "check", i, 3), lambda i: one_or_bond("check", i)]
    variants = [[0, 1, 2], [2, 0, 3], [1, 3, 2]]
    vs = variants[ctx.idx % 3]
    ck = [ck_all[v](i) for i, v in enumerate(vs)]
    # remediation: a different representation: start from the bigger number and count on
    if make_ten:
        rp = pool.take(lambda p: p[0] < p[1] and 11 <= sum(p) <= 15, remove=lambda p: [p, (p[1], p[0])])
        small, big = rp
    else:
        rp = pool.take(lambda p: 11 <= sum(p) <= 17, remove=lambda p: [p])
        big, small = rp
    s_r = big + small
    er = ctx.emo("rem")
    remx = [
        step(L, "remediation_explain", 1,
             "Here is another way. Look at %d and %d. Start with the bigger number, %d. Do not count it again: just say %d." % (small, big, big, big),
             obj([(er, big), (er, small)], 1)),
        step(L, "remediation_explain", 2,
             "Now count on %d from %d: %s. We land on %d." % (small, big, seq_on(big, small), s_r),
             line(0, 20, big, small, True)),
        step(L, "remediation_explain", 3,
             "So %d + %d = %d. The order does not change the total: %d + %d is also %d." % (big, small, s_r, small, big, s_r),
             glyph("%d + %d = %d" % (big, small, s_r))),
    ]
    rg = [spec_obj(draw(10, 13), "remediation_guided", 0, 1), spec_line(draw(10, 14), "remediation_guided", 1, 1, True)]
    rc = [spec_obj(draw(11, 16), "remediation_check", 0, 2), spec_line(draw(12, 17), "remediation_check", 1, 2, False),
          spec_sym(draw(11, 18), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ------------------------------------------------------------- skill: SUB
def build_sub(ctx, A, B, M):
    rng = ctx.rng
    L = ctx.lid
    R = A - B
    own = {(A, B)}
    lo_a = 9 if M == 20 else 4
    pool = Pool([(a, b) for a in range(lo_a, M + 1) for b in range(1, 10 if M == 20 else a)
                 if b < a and (a - b) != b and (a - b) >= 1 and (a, b) not in own and (a - b) != a and
                 (M == 10 or b >= 2)], rng)

    def draw(lo, hi):
        return pool.take(lambda p: lo <= p[0] <= hi, lambda p: abs(p[0] - (lo + hi) / 2) <= 3)

    e0 = ctx.emo("demo")
    intro = [
        step(L, "introduce", 1, "Subtracting means taking away. We start with some things and take some away. What is left is the answer.",
             obj([(e0, A)], 1, True)),
        step(L, "introduce", 2, "On a number line, we take away by going back, to the left.", line(0, M, A, 0, False)),
    ]
    demo = [
        step(L, "demonstrate", 1, "We start with %d things." % A, obj([(e0, A)], 1, op="-")),
        step(L, "demonstrate", 2, "Take away %d. These %d things are crossed out: they go away." % (B, B),
             obj([(e0, A)], 1, op="-", take=B)),
        step(L, "demonstrate", 3, "Count what is left: %d. So %d \u2212 %d = %d. The \u2212 sign means: take away." % (R, A, B, R),
             obj([(e0, A)], 1, op="-", take=B, result=R)),
        step(L, "demonstrate", 4, "On the number line, count back %d steps from %d: %s. We land on %d." % (B, A, seq_back(A, B), R),
             line(0, M, A, -B, True)),
        step(L, "demonstrate", 5, "Check by adding: start at %d and count on %d: we get back to %d. So %d + %d = %d. Subtracting and adding are partners." % (R, B, A, R, B, A),
             line(0, M, R, B, True)),
    ]

    def cands(a, b):
        r = a - b
        return {"start": [a, b], "near": [r - 1, r + 1, r - 2, r + 2], "wrong_op": [a + b], "far": [r + 4, r + 10, r - 4]}

    fb = {"start": FB["start"], "near": "Close, but not quite. Go back over it one step at a time.",
          "far": "That is a long way from the answer. Use the objects or the number line.",
          "wrong_op": "{d} is what you get by adding. Here we take away."}

    def hint_back(a, b):
        return "Count back from %d: %s." % (a, seq_back(a, b))

    def s_obj(p, role, i, diff):
        a, b = p
        r = a - b
        e = ctx.emo(role, i)
        return {"task": "sub_objects", "prompt": "How many are left?",
                "speech": "%s take away %s. How many are left?" % (nw(a), nw(b)),
                "visual": obj([(e, a)], 1, op="-", take=b, q=True), "answer": r,
                "dist": pick_dist(rng_i(ctx, role, i), r, cands(a, b), 0, 30), "fb": fb,
                "hints": ["Start with the first group. Take away the second group. Count what is left.", hint_back(a, b)],
                "expl": "%d take away %d leaves %d, so %d \u2212 %d = %d." % (a, b, r, a, b, r), "diff": diff}

    def s_line(p, role, i, diff, hops):
        a, b = p
        r = a - b
        return {"task": "sub_line", "prompt": "%d \u2212 %d = ?" % (a, b),
                "speech": "%s minus %s. Use the number line. What number is it?" % (nw(a), nw(b)),
                "visual": line(0, M, a, -b, hops), "answer": r,
                "dist": pick_dist(rng_i(ctx, role, i), r, cands(a, b), 0, 30), "fb": fb,
                "hints": ["Put your finger on %d. Count back %d steps to the left, one at a time." % (a, b), hint_back(a, b)],
                "expl": "Start at %d, count back %d steps and you land on %d, so %d \u2212 %d = %d." % (a, b, r, a, b, r),
                "diff": diff}

    def s_sym(p, role, i, diff):
        a, b = p
        r = a - b
        return {"task": "sub_symbolic", "prompt": "%d \u2212 %d = ?" % (a, b),
                "speech": "%s minus %s equals what?" % (nw(a), nw(b)), "visual": NONE, "answer": r,
                "dist": pick_dist(rng_i(ctx, role, i), r, cands(a, b), 0, 30), "fb": fb,
                "hints": ["Think: which number plus %d makes %d?" % (b, a), hint_back(a, b)],
                "expl": "%d \u2212 %d = %d." % (a, b, r), "diff": diff}

    def s_fact(p, role, i, diff):
        a, b = p
        r = a - b
        rr = rng_i(ctx, role, i)
        cand = [x for x in (r - 1, r + 1, r - 2, r + 2) if x >= 0 and x != r]
        rr.shuffle(cand)
        d1, d2 = cand[0], cand[1]
        fmt = lambda x: "%d + %d = %d" % (x, b, a)
        return {"task": "fact", "prompt": "Which addition fact checks %d \u2212 %d?" % (a, b),
                "speech": "Which addition fact checks %s minus %s?" % (nw(a), nw(b)),
                "visual": NONE, "answer": fmt(r),
                "dist": [(fmt(d1), "nottrue"), (fmt(d2), "nottrue")],
                "fb": {"nottrue": lambda d, a=a: "That sum does not make %d. Try adding the numbers in it." % a},
                "hints": ["Subtracting and adding are partners. The answer plus %d must make %d." % (b, a),
                          "Try each fact: which one really makes %d?" % a],
                "expl": "%d + %d = %d, so %d \u2212 %d = %d." % (r, b, a, a, b, r), "diff": diff}

    g = [s_obj(draw(M - 4 if M == 20 else 6, M if M == 20 else 8), "guided", 0, 1) if M == 20 else s_obj(draw(5, 8), "guided", 0, 1),
         s_line(draw(10, 15) if M == 20 else draw(6, 9), "guided", 1, 1, True)]
    hi_r = 20 if M == 20 else 10
    pr = [s_fact(draw(10, 16) if M == 20 else draw(5, 9), "practice", 0, 2),
          s_obj(draw(11, 16) if M == 20 else draw(6, 9), "practice", 1, 2),
          s_line(draw(12, 18) if M == 20 else draw(7, 10), "practice", 2, 2, False),
          s_sym(draw(13, 20) if M == 20 else draw(7, 10), "practice", 3, 3)]
    mk = [lambda i: s_obj(draw(12, hi_r), "check", i, 2), lambda i: s_line(draw(12, hi_r), "check", i, 2, False),
          lambda i: s_sym(draw(12, hi_r), "check", i, 3), lambda i: s_fact(draw(12, hi_r), "check", i, 3)]
    if M == 10:
        mk = [lambda i: s_obj(draw(6, 10), "check", i, 2), lambda i: s_line(draw(7, 10), "check", i, 2, False),
              lambda i: s_sym(draw(7, 10), "check", i, 3), lambda i: s_fact(draw(7, 10), "check", i, 3)]
    variants = [[0, 1, 2], [2, 3, 0], [1, 2, 3]]
    ck = [mk[v](i) for i, v in enumerate(variants[ctx.idx % 3])]
    rp = draw(11, 17) if M == 20 else draw(6, 9)
    ra, rb = rp
    rr_ = ra - rb
    er = ctx.emo("rem")
    remx = [
        step(L, "remediation_explain", 1,
             "Here is another way: think of adding. To find %d \u2212 %d, ask: how many do we add to %d to get to %d?" % (ra, rb, rb, ra),
             obj([(er, rb), (er, rr_)], 1)),
        step(L, "remediation_explain", 2,
             "Start at %d and count up to %d: %s. That is %d steps." % (rb, ra, seq_on(rb, rr_), rr_),
             line(0, M, rb, rr_, True)),
        step(L, "remediation_explain", 3,
             "We added %d to get from %d to %d, so %d \u2212 %d = %d. We can check: %d + %d = %d." % (rr_, rb, ra, ra, rb, rr_, rr_, rb, ra),
             glyph("%d \u2212 %d = %d" % (ra, rb, rr_))),
    ]
    rg = [s_obj(draw(8, 12) if M == 20 else draw(5, 8), "remediation_guided", 0, 1),
          s_line(draw(10, 15) if M == 20 else draw(6, 9), "remediation_guided", 1, 1, True)]
    rc = [s_obj(draw(11, 16) if M == 20 else draw(6, 10), "remediation_check", 0, 2),
          s_line(draw(11, 17) if M == 20 else draw(6, 10), "remediation_check", 1, 2, False),
          s_sym(draw(11, 18) if M == 20 else draw(6, 10), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ------------------------------------------------------ skill: IDENTIFY TENS
def blocks(n, te, oe):
    t, o = divmod(n, 10)
    g = [(te, 10)] * t
    if o:
        g.append((oe, o))
    return g


def build_tens(ctx, N):
    rng = ctx.rng
    L = ctx.lid
    T, O = divmod(N, 10)
    pool = Pool([n for n in range(11, 100) if n != N and n // 10 != n % 10 and n % 10 != 0] +
                [n for n in range(20, 100, 10) if n != N and n // 10 != n % 10], rng)

    def draw(pic_ok=True):
        if pic_ok:
            return pool.take(lambda n: n % 10 != 0)
        return pool.take(lambda n: True)

    intro = [step(L, "introduce", 1, "Bigger numbers are made of tens and ones. Ten ones make one ten. This bar is one full ten.",
                  base10(10)),
             step(L, "introduce", 2, "A number with two digits has a tens digit on the left and a ones digit on the right.",
                  glyph("%d" % N))]
    demo = [
        step(L, "demonstrate", 1, "Here is the number %d. First, the full tens. Each bar is one full ten. There are %d full tens." % (N, T),
             base10(T * 10)),
        step(L, "demonstrate", 2, "Then the single ones that are left after the tens. Each cube is one single one. There are %d single ones left." % O,
             base10(N)),
        step(L, "demonstrate", 3, "The digit on the left, %d, tells the full tens. The digit in the ones place, on the right, %d, tells the single ones left after the tens." % (T, O),
             glyph("%d" % N)),
        step(L, "demonstrate", 4, "So %d is %d tens and %d ones. Ten ones make one ten, so %d tens is %d." % (N, T, O, T, T * 10),
             base10(N, True)),
        step(L, "demonstrate", 5, "We can write it like this: %d = %d tens + %d ones." % (N, T, O),
             glyph("%d = %d tens + %d ones" % (N, T, O))),
    ]

    def digits_c(m, which):
        t, o = divmod(m, 10)
        if which == "tens":
            return {"ones": [o], "near": [t - 1, t + 1], "whole": [m], "far": [t + 3, t - 3, t + 2]}
        return {"tens": [t], "near": [o - 1, o + 1], "whole": [m], "far": [o + 3, o - 3, o + 2]}

    fb_t = {"ones": "{d} is the digit in the ones place. We want the full tens, the digit on the left.",
            "near": "Close. Count the bars again.", "whole": "{d} is the whole number. We want only the full tens.",
            "far": "That is not close. Count how many full tens there are."}
    fb_o = {"tens": "{d} is the digit in the tens place. We want the single ones, the digit on the right.",
            "near": "Close. Count the single cubes again.", "whole": "{d} is the whole number. We want only the single ones left after the tens.",
            "far": "That is not close. Look at the digit in the ones place."}
    fb_t_sym = dict(fb_t, near="Close. Look at the digit on the left again.", far="That is not close. Look at the digit on the left.")
    fb_o_sym = dict(fb_o, near="Close. Look at the digit on the right again.", far="That is not close. Look at the digit on the right.")

    def s_tens(m, role, i, pic):
        t, o = divmod(m, 10)
        dist = pick_dist(rng_i(ctx, role, i), t, digits_c(m, "tens"), 0, 99)
        return {"task": "tens_pic" if pic else "tens_sym", "prompt": "In %d, how many full tens are there?" % m,
                "visual": base10(m) if pic else NONE, "answer": t, "dist": dist, "fb": fb_t if pic else fb_t_sym,
                "hints": ["Look at the digit on the left. It tells the full tens." if not pic else "Count the bars. Each bar is one full ten.",
                          "%d is %d tens and %d ones." % (m, t, o)],
                "expl": "%d is %d tens and %d ones, so there are %d full tens." % (m, t, o, t), "diff": 1 if pic else 2}

    def s_ones(m, role, i, pic):
        t, o = divmod(m, 10)
        dist = pick_dist(rng_i(ctx, role, i), o, digits_c(m, "ones"), 0, 99)
        return {"task": "ones_pic" if pic else "ones_sym", "prompt": "In %d, how many single ones are left after the tens?" % m,
                "visual": base10(m) if pic else NONE, "answer": o, "dist": dist, "fb": fb_o if pic else fb_o_sym,
                "hints": ["Look at the digit in the ones place, on the right." if not pic else "Count only the single cubes, not the bars.",
                          "%d is %d tens and %d ones." % (m, t, o)],
                "expl": "%d is %d tens and %d ones, so there are %d single ones left after the tens." % (m, t, o, o), "diff": 1 if pic else 2}

    def s_build(m, role, i):
        t, o = divmod(m, 10)
        sw = o * 10 + t
        c = {"swap": [sw] if o > 0 else [], "near": [m - 1, m + 1], "tenoff": [m + 10, m - 10], "far": [m + 20, m - 20, t + o]}
        dist = pick_dist(rng_i(ctx, role, i), m, c, 1, 99)

        def fbf(d):
            d = int(d)
            if d == sw:
                return "The digits are the wrong way round. The tens digit goes first."
            if abs(d - m) == 10:
                return "That is one ten too many or too few. Count the tens again."
            return "Not quite. Write the tens digit first, then the ones digit."
        return {"task": "build", "prompt": "Which number is %d tens and %d ones?" % (t, o),
                "speech": "Which number is %s tens and %s ones?" % (nw(t), nw(o)), "visual": NONE, "answer": m,
                "dist": [(v, "x") for v, _ in dist], "fb": {"x": fbf},
                "hints": ["The tens digit goes on the left. The ones digit goes on the right.", "%d tens is %d, and %d more ones makes %d." % (t, t * 10, o, m)],
                "expl": "%d tens and %d ones is %d." % (t, o, m), "diff": 2}

    g = [s_tens(draw(), "guided", 0, True), s_ones(draw(), "guided", 1, True)]
    pr = [s_tens(draw(False), "practice", 0, False), s_ones(draw(False), "practice", 1, False),
          s_build(draw(), "practice", 2), s_tens(draw(), "practice", 3, True)]
    mkc = [lambda i: s_tens(draw(), "check", i, True), lambda i: s_ones(draw(False), "check", i, False),
           lambda i: s_build(draw(), "check", i), lambda i: s_tens(draw(False), "check", i, False),
           lambda i: s_ones(draw(), "check", i, True)]
    variants = [[0, 1, 2], [3, 2, 4], [4, 3, 2]]
    ck = [mkc[v](i) for i, v in enumerate(variants[ctx.idx % 3])]
    rn = draw()
    rt, ro = divmod(rn, 10)
    remx = [
        step(L, "remediation_explain", 1,
             "Let us try another way. Look at the number %d. The digit on the left tells how many full tens. Cover the digit on the right with your finger and read the tens." % rn,
             glyph("%d" % rn)),
        step(L, "remediation_explain", 2,
             "Think of sweets in packets of 10. The bars are the full packets. The cubes are the loose sweets. Here are %d full packets and %d loose sweets." % (rt, ro),
             base10(rn)),
        step(L, "remediation_explain", 3, "So %d is %d tens and %d ones. The loose ones are the single ones left after the tens." % (rn, rt, ro),
             glyph("%d = %d tens + %d ones" % (rn, rt, ro))),
    ]
    rg = [s_tens(draw(), "remediation_guided", 0, True), s_ones(draw(), "remediation_guided", 1, True)]
    rc = [s_tens(draw(False), "remediation_check", 0, False), s_ones(draw(), "remediation_check", 1, True),
          s_build(draw(), "remediation_check", 2)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ------------------------------------------------------------ skill: COMPARE
def build_compare(ctx, A, B):
    rng = ctx.rng
    L = ctx.lid
    te, oe = "\U0001F7E6", "\U0001F7E1"
    own = {(A, B), (B, A)}

    def cat_of(x, y):
        tx, ox, ty, oy = x // 10, x % 10, y // 10, y % 10
        if x == y:
            return "equal"
        if tx == oy and ty == ox:
            return "swap"
        if abs(x - y) == 1 and tx != ty:
            return "boundary"
        if tx != ty and ((tx < ty) == (ox > oy)):
            return "trap"
        if tx == ty:
            return "same_tens"
        return "tens"

    allp = [(x, y) for x in range(10, 100) for y in range(10, 100) if (x, y) not in own and abs(x - y) <= 30]
    # keep pools small and varied
    rng.shuffle(allp)
    used = set()

    def draw(cat):
        for p in allp:
            if p in used or (p[1], p[0]) in used:
                continue
            if cat_of(*p) == cat:
                used.add(p)
                return p
        raise RuntimeError("no pair for " + cat)

    tA, oA, tB, oB = A // 10, A % 10, B // 10, B % 10
    intro = [step(L, "introduce", 1, "To compare two numbers, we ask: which is more, which is less, or are they the same? We use three signs: less than <, greater than >, and equals =.",
                  glyph("<   >   =")),
             step(L, "introduce", 2, "The mouth of the sign opens towards the bigger number. And = is only for two numbers that are exactly the same.",
                  glyph("2 < 5     5 > 2"))]
    e0 = ctx.emo("demo")
    sign = "=" if A == B else ("<" if A < B else ">")
    demo = [
        step(L, "demonstrate", 1, "Here is %d: %d tens and %d ones." % (A, tA, oA), base10(A)),
        step(L, "demonstrate", 2, "And here is %d: %d tens and %d ones." % (B, tB, oB), base10(B)),
    ]
    if A == B:
        t3 = "Compare the tens first: %d tens and %d tens are the same. Then the ones: %d and %d are the same. So the numbers are exactly the same." % (tA, tB, oA, oB)
    elif tA != tB:
        bigger_t = "more" if tA > tB else "fewer"
        t3 = "Compare the tens first. %d has %d tens and %d has %d tens. %d has %s tens, so %d is %s than %d. We do not need the ones." % (
            A, tA, B, tB, A, bigger_t, A, "greater" if A > B else "less", B)
    else:
        t3 = "Compare the tens first: both have %d tens. The tens are the same, so look at the ones: %d and %d. %d ones is %s than %d ones." % (
            tA, oA, oB, oA, "more" if oA > oB else "fewer", oB)
    demo.append(step(L, "demonstrate", 3, t3, glyph("%d  __  %d" % (A, B))))
    demo.append(step(L, "demonstrate", 4, "So we write %d %s %d." % (A, sign, B), glyph("%d %s %d" % (A, sign, B))))
    lo = (min(A, B) // 10) * 10
    hi = min(100, (max(A, B) // 10 + 1) * 10)
    if A == B:
        t5 = "On a number line the two numbers are on exactly the same spot, so neither is further right. Neither is the bigger number and neither is the smaller number: they are the same number."
    else:
        t5 = "On a number line, the number further to the right is bigger. %d is further right than %d, so %d is the bigger number and %d is the smaller number." % (
            max(A, B), min(A, B), max(A, B), min(A, B))
    demo.append(step(L, "demonstrate", 5, t5, line(lo, hi, min(A, B), abs(A - B), True)))

    fbsign = {"rev": "The mouth of the sign should open towards the bigger number. Check which number is bigger.",
              "eq": "= is only for two numbers that are exactly the same. These are not the same.",
              "same": "These two numbers are exactly the same, so neither is less or greater."}

    def s_sign(p, role, i, diff, scaffold=False):
        x, y = p
        ans = "=" if x == y else ("<" if x < y else ">")
        others = [s for s in ("<", ">", "=") if s != ans]
        dist = []
        for s in others:
            if ans == "=":
                dist.append((s, "same"))
            elif s == "=":
                dist.append((s, "eq"))
            else:
                dist.append((s, "rev"))
        if scaffold:
            vis = line((min(x, y) // 10) * 10, min(100, (max(x, y) // 10 + 1) * 10), min(x, y), abs(x - y), True)
        else:
            vis = NONE
        return {"task": "sign", "prompt": "Choose the sign: %d __ %d" % (x, y),
                "speech": "Choose the sign. %s blank %s." % (nw(x), nw(y)), "visual": vis, "answer": ans,
                "dist": dist, "fb": fbsign,
                "hints": ["Compare the tens first. Only if the tens are the same, look at the ones.",
                          "%d has %d tens and %d ones. %d has %d tens and %d ones." % (x, x // 10, x % 10, y, y // 10, y % 10)],
                "expl": "%d %s %d." % (x, ans, y), "diff": diff}

    def s_big(p, role, i, diff, big):
        x, y = p
        r = rng_i(ctx, role, i)
        zs = [z for z in range(max(10, min(x, y) - 12), min(99, max(x, y) + 12) + 1) if z not in (x, y)]
        z = r.choice(zs)
        trio = [x, y, z]
        ans = max(trio) if big else min(trio)
        word = "biggest" if big else "smallest"
        side = "more" if big else "fewer"
        return {"task": "bigger" if big else "smaller", "prompt": "Which number is the %s?" % word,
                "visual": NONE, "answer": ans, "dist": [(w, "no") for w in trio if w != ans],
                "fb": {"no": lambda d, word=word, side=side: "%s is not the %s. Compare the tens first: the %s number has %s tens, or the same tens and %s ones." % (d, word, word, side, side)},
                "hints": ["Compare the tens of each number first.", ("All the tens are the same, so compare the ones." if len({t // 10 for t in trio}) == 1 else
                          ("Look at the number with the %s tens." % ("most" if big else "fewest")) +
                          (" If two numbers share those tens, compare their ones." if sum(1 for t in trio if t // 10 == (max if big else min)(u // 10 for u in trio)) > 1 else ""))],
                "expl": "%d is the %s of the three numbers." % (ans, word), "diff": diff}

    g = [s_sign(draw("tens"), "guided", 0, 1, True), s_big(draw("same_tens"), "guided", 1, 1, True)]
    pr = [s_sign(draw("equal"), "practice", 0, 1), s_big(draw("swap"), "practice", 1, 2, False),
          s_sign(draw("trap"), "practice", 2, 2), s_big(draw("boundary"), "practice", 3, 3, True)]
    chk_variants = [
        [lambda i: s_sign(draw("trap"), "check", i, 2), lambda i: s_big(draw("swap"), "check", i, 2, True),
         lambda i: s_big(draw("same_tens"), "check", i, 3, False)],
        [lambda i: s_big(draw("boundary"), "check", i, 3, False), lambda i: s_sign(draw("same_tens"), "check", i, 2),
         lambda i: s_sign(draw("equal"), "check", i, 2)],
        [lambda i: s_big(draw("trap"), "check", i, 2, True), lambda i: s_sign(draw("swap"), "check", i, 2),
         lambda i: s_big(draw("tens"), "check", i, 3, False)],
    ]
    ck = [f(i) for i, f in enumerate(chk_variants[ctx.idx % 3])]
    rp = draw("trap")
    rx, ry = rp
    rsign = "<" if rx < ry else ">"
    big_r, small_r = (rx, ry) if rx > ry else (ry, rx)
    remx = [
        step(L, "remediation_explain", 1,
             "Let us use the number line. Numbers go up as we move to the right. Here are %d and %d." % (rx, ry),
             line((min(rx, ry) // 10) * 10, min(100, (max(rx, ry) // 10 + 1) * 10), min(rx, ry), 0, False)),
        step(L, "remediation_explain", 2,
             "Start at %d and count up to %d. We move to the right, so %d is bigger than %d." % (small_r, big_r, big_r, small_r),
             line((min(rx, ry) // 10) * 10, min(100, (max(rx, ry) // 10 + 1) * 10), small_r, big_r - small_r, True)),
        step(L, "remediation_explain", 3,
             "Tip: look at the tens digit first. %d has %d tens and %d has %d tens. So %d %s %d." % (rx, rx // 10, ry, ry // 10, rx, rsign, ry),
             glyph("%d %s %d" % (rx, rsign, ry))),
    ]
    rg = [s_sign(draw("tens"), "remediation_guided", 0, 1, True), s_big(draw("same_tens"), "remediation_guided", 1, 1, True)]
    rc = [s_sign(draw("swap"), "remediation_check", 0, 2), s_big(draw("trap"), "remediation_check", 1, 2, False),
          s_sign(draw("equal"), "remediation_check", 2, 2)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ------------------------------------------------------------ skill: PATTERN
def build_pattern(ctx, seq):
    rng = ctx.rng
    L = ctx.lid
    s0, s1, s2 = seq
    d = abs(s1 - s0)
    inc = s1 > s0
    sg = "+" if inc else "\u2212"
    own = (s0, d, inc)
    fam = []
    for dd in (1, 2, 3, 4, 5, 10):
        for st in range(1, 41):
            if st + 3 * dd <= 50 and (st <= 12 or (dd == 10 and st % 10 == 0) or st % dd == 0):
                fam.append((st, dd, True))
    for dd in (1, 2, 3, 5, 10):
        for st in range(8, 41):
            if st - 3 * dd >= 0 and (st >= 3 * dd + 1):
                fam.append((st, dd, False))
    fam = [f for f in fam if f != own]
    pool = Pool(fam, rng)

    def draw(inc_pref=None, big=None):
        ps = []
        if inc_pref is not None:
            ps.append(lambda f: f[2] == inc_pref and (big is None or (f[1] >= 4) == big))
            ps.append(lambda f: f[2] == inc_pref)
        return pool.take(*ps)

    def terms(f, n=5):
        st, dd, ic = f
        return [st + (dd if ic else -dd) * k for k in range(n)]

    def sg_of(f):
        return "+" if f[2] else "\u2212"

    e0 = ctx.emo("demo")
    intro = [step(L, "introduce", 1, "A pattern follows a rule. Colours can make a pattern: red, blue, red, blue. Numbers can make a pattern too.",
                  glyph("\U0001F534 \U0001F535 \U0001F534 \U0001F535")),
             step(L, "introduce", 2, "In a number pattern, each number comes from the one before by the same rule. Look at how the numbers change.",
                  glyph("%d, %d, %d, ..." % (s0, s1, s2)))]
    s3 = s2 + (d if inc else -d)
    demo = []
    to_ = max(10, s0, s1, s2, s3)
    if inc and s0 + 2 * d <= 20:
        grp = [(e0, s0)] + [(e0, d)] * 2
        v1, v2 = obj(grp, 2, True), obj(grp, 3, True)
    else:
        v1, v2 = line(0, to_, s0, d if inc else -d, True), line(0, to_, s1, d if inc else -d, True)
    word = "Add %d" % d if inc else "Count back %d" % d
    demo.append(step(L, "demonstrate", 1, "Start with %d. %s. Now we have %d." % (s0, word, s1), v1))
    demo.append(step(L, "demonstrate", 2, "%s again. Now we have %d. The rule is: %s each time." % (word, s2, "add %d" % d if inc else "take away %d" % d), v2))
    if inc:
        demo.append(step(L, "demonstrate", 3, "Patterns can also go down. This one shrinks: 12, 10, 8. Each number is 2 less than the one before. The rule is: take away 2 each time.",
                         line(0, 20, 12, -2, True)))
    else:
        demo.append(step(L, "demonstrate", 3, "Patterns can also go up. This one grows: 2, 4, 6. Each number is 2 more than the one before. The rule is: add 2 each time.",
                         obj([(e0, 2)] * 3, 3, True)))
    demo.append(step(L, "demonstrate", 4, "To find the next number, use the rule: %d %s %d = %d. The pattern continues: %d, %d, %d, %d." % (s2, sg, d, s3, s0, s1, s2, s3),
                     glyph("%d, %d, %d, __" % (s0, s1, s2))))
    demo.append(step(L, "demonstrate", 5, "A number can also be missing from the middle. Use the rule: %d %s %d = %d, and it fits: %d, %d, %d." % (s0, sg, d, s1, s0, s1, s2),
                     glyph("%d, __, %d" % (s0, s2))))

    def s_next(f, role, i, diff, scaffold=False):
        t = terms(f, 4)
        a = t[3]
        sgn = 1 if f[2] else -1
        c = {"ones": [t[2] + sgn], "repeat": [t[2]], "stepoff": [t[2] + sgn * (f[1] + 1), t[2] + sgn * max(1, f[1] - 1)],
             "wrongdir": [t[2] - sgn * f[1]]}
        dist = pick_dist(rng_i(ctx, role, i), a, c, 0, 99)
        if scaffold and f[2] and t[0] + 2 * f[1] <= 20:
            vis = obj([(ctx.emo(role, i), t[0])] + [(ctx.emo(role, i), f[1])] * 2, 3, True)
        elif scaffold and f[2]:
            vis = line(0, max(10, a), t[2], f[1], True)
        elif scaffold:
            vis = line(0, max(t[0], 10), t[2], -f[1], True)
        else:
            vis = glyph("%d, %d, %d, __" % (t[0], t[1], t[2]))
        prompt = "What number comes next?" if not scaffold else "What number comes next: %d, %d, %d, __ ?" % (t[0], t[1], t[2])
        return {"task": "next", "prompt": prompt, "visual": vis, "answer": a, "dist": dist,
                "fb": {"ones": "{d} is only one more or one less than the last number. The rule here changes the numbers by more than that, so check the gap.",
                       "repeat": "{d} is the last number again. The pattern must keep going.",
                       "stepoff": "Not quite. Check the gap between the first two numbers; it stays the same every time.",
                       "wrongdir": "That goes the wrong way. Look: do the numbers go up or down?"},
                "hints": ["Look at how much each number changes from the one before.",
                          "The numbers %s by %d each time: %d %s %d = %d." % ("go up" if f[2] else "go down", f[1], t[2], sg_of(f), f[1], a)],
                "expl": "The rule is %s%d, so %d %s %d = %d." % ("+" if f[2] else "\u2212", f[1], t[2], sg_of(f), f[1], a), "diff": diff}

    def s_rule(f, role, i, diff):
        t = terms(f, 3)
        dd = f[1]
        sgs = sg_of(f)
        ans = "%s%d" % (sgs, dd)
        opp = "\u2212" if f[2] else "+"
        c = []
        for v in (dd + 1, dd - 1, 2 * dd):
            if v >= 1 and v != dd:
                c.append(("%s%d" % (sgs, v), "stepoff"))
        c.append(("%s%d" % (opp, dd), "wrongdir"))
        rr = rng_i(ctx, role, i)
        by = {}
        for v, k in c:
            by.setdefault(k, []).append((v, k))
        picks = [rr.choice(by["wrongdir"]), rr.choice(by["stepoff"])] if rr.random() < 0.6 else rr.sample(c, 2)
        if picks[0][0] == picks[1][0]:
            picks = [by["wrongdir"][0], by["stepoff"][0]]
        return {"task": "rule", "prompt": "What is the rule for this pattern?",
                "visual": glyph("%d, %d, %d, ..." % tuple(t)), "answer": ans, "dist": picks,
                "fb": {"stepoff": "Not quite. Work out how much the first number changes to become the second.",
                       "wrongdir": "That goes the wrong way. Do the numbers go up or down?"},
                "hints": ["Look at how the first number becomes the second number.",
                          "From %d to %d the number %s by %d." % (t[0], t[1], "goes up" if f[2] else "goes down", dd)],
                "expl": "The numbers %s by %d each time, so the rule is %s." % ("go up" if f[2] else "go down", dd, ans), "diff": diff}

    def s_missing(f, role, i, diff):
        t = terms(f, 4)
        a = t[1]
        c = {"copy": [t[0], t[2]], "near": [a - 1, a + 1], "ones": [t[0] + 1, t[0] - 1], "far": [a + 5, a - 5]}
        dist = pick_dist(rng_i(ctx, role, i), a, c, 0, 99)
        return {"task": "missing", "prompt": "Which number goes in the blank?",
                "visual": glyph("%d, __, %d, %d" % (t[0], t[2], t[3])), "answer": a, "dist": dist,
                "fb": {"copy": "{d} is already in the pattern. The blank needs a different number that fits the rule.",
                       "near": "Close. Check the gap on each side of the blank; it must be the same.",
                       "ones": "Not quite. Work out the gap between the numbers you can see.",
                       "far": "That is too far. Check the gap between the numbers."},
                "hints": ["Look at the gap between the numbers you can see.",
                          "%d %s %d = %d, and %d %s %d = %d." % (t[0], sg_of(f), f[1], a, a, sg_of(f), f[1], t[2])],
                "expl": "The rule is %s%d, so the missing number is %d." % ("+" if f[2] else "\u2212", f[1], a), "diff": diff}

    g = [s_next(draw(inc), "guided", 0, 1, True), s_missing(draw(inc, False), "guided", 1, 1)]
    pr = [s_next(draw(inc, False), "practice", 0, 1), s_rule(draw(inc), "practice", 1, 2),
          s_missing(draw(not inc), "practice", 2, 2), s_next(draw(not inc), "practice", 3, 3)]
    mk = [lambda i: s_next(draw(), "check", i, 2), lambda i: s_rule(draw(), "check", i, 2),
          lambda i: s_missing(draw(), "check", i, 3)]
    rot = ctx.idx % 3
    ck = [mk[(k + rot) % 3](i) for i, k in enumerate(range(3))]
    # remediation: gap view (an arrow chain), then skip counting by objects or number line
    rf = draw(inc)
    rt = terms(rf, 4)
    remx = [step(L, "remediation_explain", 1,
                 "Let us look at the gaps. Each arrow shows how the number changes: %d to %d is %s%d. %d to %d is also %s%d." % (
                     rt[0], rt[1], sg_of(rf), rf[1], rt[1], rt[2], sg_of(rf), rf[1]),
                 glyph("%d \u2192 %d \u2192 %d" % (rt[0], rt[1], rt[2])))]
    if rf[2] and 3 * rf[1] <= 20:
        er = ctx.emo("rem")
        remx.append(step(L, "remediation_explain", 2,
                         "Now with objects. Each group has %d. We add one group each time." % rf[1],
                         obj([(er, rf[1])] * 3, 3, False)))
    elif rf[2]:
        remx.append(step(L, "remediation_explain", 2,
                         "Now on the number line. Count on %d from %d. We land on %d." % (rf[1], rt[0], rt[1]),
                         line(0, max(10, rt[3]), rt[0], rf[1], True)))
    else:
        remx.append(step(L, "remediation_explain", 2,
                         "Now on the number line. Count back %d from %d. We land on %d." % (rf[1], rt[0], rt[1]),
                         line(0, max(rt[0], 10), rt[0], -rf[1], True)))
    remx.append(step(L, "remediation_explain", 3,
                     "The gap stays the same. So the next number is %d %s %d = %d." % (rt[2], sg_of(rf), rf[1], rt[3]),
                     glyph("%d, %d, %d, %d" % tuple(rt))))
    rg = [s_next(draw(inc), "remediation_guided", 0, 1, True), s_missing(draw(inc), "remediation_guided", 1, 1)]
    rc = [s_next(draw(), "remediation_check", 0, 2), s_rule(draw(), "remediation_check", 1, 2),
          s_missing(draw(), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ------------------------------------------------------------- skill: SHAPES
SHAPES = {"triangle": dict(name="Triangle", sides=3, corners=3, art="assets/images/age56/triangle.webp",
                           p1="Which shape has 3 straight sides?", p2="Which shape has 3 corners?",
                           eg="\U0001F355 a slice of pizza"),
          "square": dict(name="Square", sides=4, corners=4, art="assets/images/age56/square.webp",
                         p1="Which shape has 4 corners and all its sides the same length?", p2="Which shape has 4 equal sides?",
                         eg="\U0001F5BC\uFE0F a picture frame"),
          "rectangle": dict(name="Rectangle", sides=4, corners=4, art="assets/images/age56/rectangle.webp",
                            p1="Which shape has 4 sides, 2 long and 2 short?", p2="Which shape has 4 corners and 2 long sides?",
                            eg="\U0001F6AA a door"),
          "circle": dict(name="Circle", sides=0, corners=0, art="assets/images/age56/circle.webp",
                         p1="Which shape is round and has no straight sides?", p2="Which shape has no corners?",
                         eg="\U0001F36A a biscuit")}


def build_shape(ctx, key):
    rng = ctx.rng
    L = ctx.lid
    S = SHAPES[key]
    others = [k for k in SHAPES if k != key]
    used = set()  # (task, shape, variant)

    def fresh(task, shape, var=0):
        used.add((task, shape, var))

    def left(task, shape, var=0):
        return (task, shape, var) not in used

    fresh("sides", key)
    fresh("corners", key)
    fresh("name", key)
    nm = S["name"]
    intro = [step(L, "introduce", 1, "Shapes are all around us. Today we look closely at the %s. A side is a straight line. A corner is where two sides meet." % nm.lower(), pic(S["art"], nm)),
             step(L, "introduce", 2, "Four shapes to know: triangle, square, rectangle and circle. A triangle has 3 sides. A circle is round, with no straight sides and no corners.",
                  glyph("triangle   square   rectangle   circle")),
             step(L, "introduce", 3, "A square has 4 equal sides: all the same length. A rectangle has 4 sides: 2 long sides and 2 short sides.",
                  glyph("square: 4 equal sides     rectangle: 2 long + 2 short sides"))]
    demo = [step(L, "demonstrate", 1, "This shape is a %s." % nm.lower(), pic(S["art"], nm))]
    if S["sides"]:
        demo.append(step(L, "demonstrate", 2, "Count the straight sides with your finger. A %s has %d straight sides." % (nm.lower(), S["sides"]),
                         pic(S["art"], "%d sides" % S["sides"])))
        demo.append(step(L, "demonstrate", 3, "Now count the corners, where two sides meet. A %s has %d corners." % (nm.lower(), S["corners"]),
                         pic(S["art"], "%d corners" % S["corners"])))
    else:
        demo.append(step(L, "demonstrate", 2, "Trace around it with your finger. A circle has no straight sides. It is one round line.",
                         pic(S["art"], "no straight sides")))
        demo.append(step(L, "demonstrate", 3, "A circle has no corners either. Nothing sticks out. It is smooth and round.",
                         pic(S["art"], "no corners")))
    demo.append(step(L, "demonstrate", 4, "Now look at the square. All 4 of its sides are the same length. We call them equal sides. A square has 4 corners.",
                     pic(SHAPES["square"]["art"], "equal sides")))
    demo.append(step(L, "demonstrate", 5, "Now look at the rectangle. It also has 4 sides and 4 corners, but 2 sides are long and 2 sides are short.",
                     pic(SHAPES["rectangle"]["art"], "2 long sides, 2 short sides")))
    o1 = others[0]
    if SHAPES[o1]["sides"] == S["sides"]:
        o1 = [k for k in others if SHAPES[k]["sides"] != S["sides"]][0]

    def num_opts(ans, role, i, extra):
        c = {"near": [ans - 1, ans + 1], "other": [x for x in (0, 3, 4, 5, 6) if x != ans], "far": [ans + 2, ans + 3]}
        return pick_dist(rng_i(ctx, role, i), ans, c, 0, 6)

    def fbnum(d, kind):
        d = int(d)
        who = [k for k in SHAPES if SHAPES[k]["sides"] == d]
        if d == 0:
            return "A shape with no straight sides is round, like a circle. Count the straight lines again."
        if who:
            return "%d is the number of sides of a %s. Count the sides of this shape again, touching each one only once." % (d, SHAPES[who[0]]["name"].lower())
        return "Not quite. Count again, touching each one only once."

    def s_count(k, role, i, what, diff):
        n = SHAPES[k][what]
        dist = num_opts(n, role, i, None)
        rep = "sides" if what == "sides" else "corners"
        return {"task": what, "prompt": "How many %s %s does this shape have?" % ("straight" if what == "sides" else "", rep) if what == "sides" else "How many corners does this shape have?",
                "visual": pic(SHAPES[k]["art"], ""), "answer": n, "dist": [(v, "x") for v, _ in dist],
                "fb": {"x": (lambda d, w=what: fbnum(d, w) if w == "sides" else
                             ("A shape with no corners is round. Count where two sides meet." if int(d) == 0 else
                              "Not quite. Count the corners, where two sides meet, one at a time."))},
                "hints": ["Trace around the shape with your finger and count each %s once." % ("straight side" if what == "sides" else "corner"),
                          ("It has %d." % n) if n > 0 else "Trace it: there is nothing straight and nothing pointed, so the number is zero."],
                "expl": "A %s has %s." % (SHAPES[k]["name"].lower(), ("%d %s" % (n, rep)) if n else "no " + rep), "diff": diff}

    def s_name(k, role, i, diff):
        ops = [k] + rng_i(ctx, role, i).sample([x for x in SHAPES if x != k], 2)
        return {"task": "name", "prompt": "What is the name of this shape?", "visual": pic(SHAPES[k]["art"], ""),
                "answer": SHAPES[k]["name"], "dist": [(SHAPES[x]["name"], "no") for x in ops if x != k],
                "fb": {"no": lambda d: "That is not this shape. Count the sides and corners and think about its name."},
                "hints": ["Count the sides and the corners. Then think of the shape names we learned.",
                          "It has %s. That is a %s." % (word_s(k), SHAPES[k]["name"].lower())],
                "expl": "This shape is a %s." % SHAPES[k]["name"].lower(), "diff": diff}

    def word_s(k):
        s = SHAPES[k]["sides"]
        return "no straight sides" if s == 0 else "%d sides" % s

    def s_which(k, var, role, i, diff):
        if k == "square":
            opts = ["square", "triangle", "circle", "rectangle"]
        elif k == "rectangle":
            opts = ["rectangle", "triangle", "circle"]
        else:
            opts = [x for x in SHAPES if x != "rectangle" or k != "triangle" or True]
        rr = rng_i(ctx, role, i)
        if k == "square":
            wrong = rr.sample(["triangle", "circle", "rectangle"], 2)
        elif k == "rectangle":
            wrong = rr.sample(["triangle", "circle"], 2)
        elif k == "triangle":
            wrong = rr.sample(["circle", "square", "rectangle"], 2)
        else:
            wrong = rr.sample(["triangle", "square", "rectangle"], 2)
        names = [SHAPES[w]["name"] for w in wrong]
        pics = {SHAPES[x]["name"]: SHAPES[x]["art"] for x in [k] + wrong}

        def fbw(d):
            kk = [x for x in SHAPES if SHAPES[x]["name"] == d][0]
            if kk == "rectangle" and k == "square":
                return "A rectangle has 2 long sides and 2 short sides. They are not all the same length."
            if kk == "square" and k == "rectangle":
                return "All the sides of a square are the same length. We want 2 long and 2 short sides."
            return "A %s has %s. That does not match." % (d.lower(), word_s(kk))
        return {"task": "which_prop", "prompt": S_P(k, var), "visual": NONE, "answer": SHAPES[k]["name"],
                "dist": [(n, "no") for n in names], "fb": {"no": fbw}, "optionPictures": pics,
                "hints": ["Think about the sides and corners of each shape in the pictures.", "The answer is the %s." % SHAPES[k]["name"].lower()],
                "expl": "The %s matches: it has %s." % (SHAPES[k]["name"].lower(), word_s(k)), "diff": diff}

    def S_P(k, var):
        return SHAPES[k]["p1" if var == 0 else "p2"]

    # which_prop uses variant 0 in demo? the demo teaches property by sides/corners; use var 1 for check
    fresh("which_prop", key, 0)  # keep p1 for guided/practice of OTHER shapes only
    # guided: name (own shape, caption-less) + sides (other shape)
    ga = o1
    g = [s_name(key, "guided", 0, 1), s_count(ga, "guided", 1, "sides", 1)]
    fresh("name", key, 0)
    fresh("sides", ga)
    pr_sh = [x for x in others if x != ga]
    pr = [s_count(key, "practice", 0, "corners", 1) if False else s_count(pr_sh[0], "practice", 0, "corners", 1),
          s_which(pr_sh[1] if len(pr_sh) > 1 else ga, 0, "practice", 1, 2),
          s_count(pr_sh[1] if len(pr_sh) > 1 else ga, "practice", 2, "sides", 2),
          s_name(pr_sh[0], "practice", 3, 2)]
    fresh("corners", pr_sh[0])
    # check: own corners, which_prop own (variant 2), sides of another shape; rotate order
    ck_items = [s_count(key, "check", 0, "corners", 2), s_which(key, 1, "check", 1, 2),
                s_count(pr_sh[0], "check", 2, "sides", 3)]
    rot = ctx.idx % 3
    ck_items = ck_items[rot:] + ck_items[:rot]
    ck = ck_items
    for i, q in enumerate(ck):
        pass
    # remediation: sticks and dots (a different model) then a contrast picture
    sticks = "\U0001F962"
    dot = "\u26AB"
    if S["sides"]:
        remx = [step(L, "remediation_explain", 1,
                     "Let us build a %s from sticks. Each stick is one side. We need %d sticks." % (nm.lower(), S["sides"]),
                     obj([(sticks, S["sides"])], 1, True)),
                step(L, "remediation_explain", 2,
                     "Each place where two sticks meet is a corner. Here are the %d corners as dots." % S["corners"],
                     obj([(dot, S["corners"])], 1, True)),
                step(L, "remediation_explain", 3,
                     "So a %s has %d sides and %d corners. Now look at the picture again and count them." % (nm.lower(), S["sides"], S["corners"]),
                     pic(S["art"], "%d sides, %d corners" % (S["sides"], S["corners"])))]
    else:
        remx = [step(L, "remediation_explain", 1, "Let us try with a string. A string can lie in a round loop. It has no straight sticks in it.",
                     glyph("\u2B55")),
                step(L, "remediation_explain", 2, "A loop has no corners where two straight lines meet. So a circle has 0 corners and 0 straight sides.",
                     pic(S["art"], "")),
                step(L, "remediation_explain", 3, "So a circle is round, with no straight sides and no corners.", pic(S["art"], "round, no corners"))]
    rg = [s_name(pr_sh[1] if len(pr_sh) > 1 else ga, "remediation_guided", 0, 1) if False else s_count(pr_sh[1] if len(pr_sh) > 1 else ga, "remediation_guided", 0, "corners", 1),
          s_which(o1, 1, "remediation_guided", 1, 2)]
    fresh("corners", pr_sh[1] if len(pr_sh) > 1 else ga)
    rc = [s_count(o1, "remediation_check", 0, "corners", 2), s_name(ga if ga != key else pr_sh[0], "remediation_check", 1, 2),
          s_count(pr_sh[1] if len(pr_sh) > 1 else ga, "remediation_check", 2, "sides", 2) if False else s_which(pr_sh[0], 1, "remediation_check", 2, 2)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ----------------------------------------------------- skill: MULTIPLY etc.
def build_multiply(ctx, g0, s0):
    rng = ctx.rng
    L = ctx.lid
    own = {(g0, s0), (s0, g0)}
    pool = Pool([(g, s) for g in range(2, 8) for s in range(2, 8) if (g, s) not in own and g * s <= 30], rng)

    def draw(lo, hi):
        return pool.take(lambda p: lo <= p[0] * p[1] <= hi, lambda p: True)

    e0 = ctx.emo("demo")
    P = g0 * s0
    e1 = ctx.emo("demo", 3)
    intro = [step(L, "introduce", 1, "Equal groups have the same number of things in each group. Here are 3 groups with 2 in each group.",
                  obj([(e1, 2)] * 3, 3)),
             step(L, "introduce", 2, "When we add the same number again and again, we can count in equal groups. 2 + 2 + 2 is 3 groups of 2.",
                  glyph("2 + 2 + 2"))]
    demo = [step(L, "demonstrate", 1, "Here is 1 group of %d." % s0, obj([(e0, s0)] * g0, 1)),
            step(L, "demonstrate", 2, "Here are %d groups of %d. Every group has the same number." % (g0, s0), obj([(e0, s0)] * g0, g0)),
            step(L, "demonstrate", 3, "Count them all, one by one: 1, 2, 3, ... up to %d. There are %d altogether." % (P, P),
                 obj([(e0, s0)] * g0, g0, True)),
            step(L, "demonstrate", 4, "%s. We write this as %d \u00d7 %d = %d. The \u00d7 sign means: groups of." % (
                " + ".join([str(s0)] * g0) + " = %d" % P, g0, s0, P), obj([(e0, s0)] * g0, g0, result=P)),
            step(L, "demonstrate", 5, "So %d groups of %d is %d. Adding the same number again and again is multiplying." % (g0, s0, P),
                 glyph("%d \u00d7 %d = %d" % (g0, s0, P)))]

    def cands(g, s):
        p = g * s
        return {"sum": [g + s], "one": [s, g], "off": [p + s, p - s], "near": [p - 1, p + 1], "far": [p + 10, p - 10]}

    def fbm_for(g, s):
        p = g * s

        def f(d):
            v = int(d)
            if v == g + s:
                return "%d is %d + %d, the two numbers added. We want %d groups of %d: add %d again and again." % (v, g, s, g, s, s)
            if v == s:
                return "%d is the size of just one group. We want all %d groups together." % (v, g)
            if v == g:
                return "%d is only the number of groups. We want the total of the things in all the groups." % v
            if v == p + s:
                return "%d is one group too many. Count the groups again." % v
            if v == p - s:
                return "%d is one group too few. Count the groups again." % v
            if abs(v - p) == 1:
                return "Close, but not quite. Count the groups one at a time."
            return "Not quite. Add the group size once for every group."
        return AnyKind(f)

    RM = lambda p: [p, (p[1], p[0])]

    def drawv(lo, hi):
        return pool.take(lambda p: lo <= p[0] * p[1] <= min(hi, 20), lambda p: p[0] * p[1] <= 20, remove=RM)

    def drawb(lo, hi):
        return pool.take(lambda p: p[0] * p[1] > 20 and lo <= p[0] * p[1] <= hi, lambda p: p[0] * p[1] > 20,
                         lambda p: lo <= p[0] * p[1] <= hi, lambda p: True, remove=RM)

    fbm = {"sum": "{d} is what you get by adding the two numbers. We want groups of: add the group size again and again.",
           "one": "{d} is only one group, or just one of the numbers. We want all the groups together.",
           "off": "Close. That is one group too many or too few. Count all the groups again.",
           "near": "Close, but not quite. Count the groups one at a time.",
           "far": "That is a long way off. Add the group size once for every group."}

    def m_pic(p, role, i, diff):
        g, s = p
        e = ctx.emo(role, i)
        P = g * s
        return {"task": "groups_pic", "prompt": "How many altogether?", "speech": "%s groups of %s. How many altogether?" % (nw(g), nw(s)),
                "visual": obj([(e, s)] * g, g, q=True), "answer": P, "dist": pick_dist(rng_i(ctx, role, i), P, cands(g, s), 0, 60),
                "fb": fbm_for(g, s), "hints": ["Count how many in one group. Then count on for each group.",
                                     "Count on by %d each time: %s." % (s, ", ".join(str(s * k) for k in range(1, g + 1)))],
                "expl": "%d groups of %d make %d, so %d \u00d7 %d = %d." % (g, s, P, g, s, P), "diff": diff}

    def m_add(p, role, i, diff):
        g, s = p
        P = g * s
        return {"task": "repeat_add", "prompt": "%s = ?" % " + ".join([str(s)] * g), "visual": NONE, "answer": P,
                "dist": pick_dist(rng_i(ctx, role, i), P, cands(g, s), 0, 60), "fb": fbm_for(g, s),
                "hints": ["Add the numbers one at a time: add the first two, then the next.", "Count on: %s." % ", ".join(str(s * k) for k in range(1, g + 1))],
                "expl": "%s = %d, which is %d groups of %d." % (" + ".join([str(s)] * g), P, g, s), "diff": diff}

    def m_times(p, role, i, diff):
        g, s = p
        P = g * s
        return {"task": "times_sym", "prompt": "%d \u00d7 %d = ?" % (g, s), "speech": "%s times %s equals what?" % (nw(g), nw(s)),
                "visual": NONE, "answer": P, "dist": pick_dist(rng_i(ctx, role, i), P, cands(g, s), 0, 60), "fb": fbm_for(g, s),
                "hints": ["\u00d7 means groups of. Think: %d groups of %d." % (g, s), "Count on by %d each time: %s." % (s, ", ".join(str(s * k) for k in range(1, g + 1)))],
                "expl": "%d \u00d7 %d = %d." % (g, s, P), "diff": diff}

    things = ["plates", "boxes", "bags", "baskets", "shelves", "tables"]
    holds = ["apples", "pencils", "sweets", "flowers", "books", "balls"]

    def m_story(p, role, i, diff):
        g, s = p
        P = g * s
        r = rng_i(ctx, role, i)
        th, ho = r.choice(things), r.choice(holds)
        return {"task": "story", "prompt": "There are %d %s. Each one has %d %s. How many %s are there altogether?" % (g, th, s, ho, ho),
                "visual": NONE, "answer": P, "dist": pick_dist(rng_i(ctx, role, i), P, cands(g, s), 0, 60), "fb": fbm_for(g, s),
                "hints": ["Each %s has the same number. Think of %d equal groups." % (th[:-1], g), "Count on by %d each time: %s." % (s, ", ".join(str(s * k) for k in range(1, g + 1)))],
                "expl": "%d groups of %d make %d." % (g, s, P), "diff": diff}

    g = [m_pic(drawv(4, 12), "guided", 0, 1), m_add(drawb(6, 15), "guided", 1, 1)]
    pr = [m_story(drawb(6, 12), "practice", 0, 2), m_times(drawb(8, 16), "practice", 1, 2), m_pic(drawv(10, 20), "practice", 2, 2),
          m_add(drawb(12, 24), "practice", 3, 3)]
    mk = [lambda i: m_pic(drawv(12, 20), "check", i, 2), lambda i: m_times(drawb(12, 30), "check", i, 3),
          lambda i: m_story(drawb(10, 24), "check", i, 2), lambda i: m_add(drawb(10, 24), "check", i, 3)]
    variants = [[0, 2, 1], [2, 1, 0], [1, 0, 2]]
    ck = [mk[v](i) for i, v in enumerate(variants[ctx.idx % 3])]
    rp = drawv(6, 15)
    rg_, rs_ = rp
    rP = rg_ * rs_
    er = ctx.emo("rem")
    remx = [step(L, "remediation_explain", 1, "Let us think of adding the same number again and again: %s." % " + ".join([str(rs_)] * rg_),
                 glyph(" + ".join([str(rs_)] * rg_) + " = %d" % rP)),
            step(L, "remediation_explain", 2, "Now count every thing in ones: there are %d groups of %d, so we count 1, 2, 3 ... up to %d." % (rg_, rs_, rP),
                 obj([(er, rs_)] * rg_, rg_, True)),
            step(L, "remediation_explain", 3, "We can also skip count by %d: %s. That is %d \u00d7 %d = %d." % (rs_, ", ".join(str(rs_ * k) for k in range(1, rg_ + 1)), rg_, rs_, rP),
                 glyph("%d \u00d7 %d = %d" % (rg_, rs_, rP)))]
    rg = [m_pic(drawv(4, 10), "remediation_guided", 0, 1), m_add(drawb(6, 14), "remediation_guided", 1, 1)]
    rc = [m_pic(drawv(8, 18), "remediation_check", 0, 2), m_times(drawb(10, 24), "remediation_check", 1, 2),
          m_story(drawb(8, 24), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


def build_divide(ctx, T0, d0):
    rng = ctx.rng
    L = ctx.lid
    q0 = T0 // d0
    pool = Pool([(d * q, d) for d in range(2, 7) for q in range(2, 7) if d != q and (d * q, d) != (T0, d0) and d * q <= 30], rng)

    def draw(lo, hi):
        return pool.take(lambda p: lo <= p[0] <= hi, lambda p: True)

    def drawv(lo, hi):
        return pool.take(lambda p: lo <= p[0] <= min(hi, 20), lambda p: p[0] <= 20)

    def drawb(lo, hi):
        return pool.take(lambda p: p[0] > 20 and lo <= p[0] <= hi, lambda p: p[0] > 20, lambda p: lo <= p[0] <= hi, lambda p: True)

    e0 = ctx.emo("demo")
    e1 = ctx.emo("demo", 3)
    intro = [step(L, "introduce", 1, "To share equally means every person gets the same number. Here are 2 plates with 2 cookies on each plate. This is a fair share.",
                  obj([(e1, 2)] * 2, 2)),
             step(L, "introduce", 2, "We use the \u00f7 sign for sharing equally. It is the opposite of making equal groups.",
                  glyph("\u00f7"))]
    demo = [step(L, "demonstrate", 1, "Here are %d sweets. We will share them equally among %d plates." % (T0, d0), obj([(e0, T0)], 1)),
            step(L, "demonstrate", 2, "Give one sweet to each plate, again and again, until none are left. Each round, every plate gets 1.",
                 obj([(e0, 1)] * d0, d0)),
            step(L, "demonstrate", 3, "When all the sweets are shared, each plate has %d. The groups are all equal." % q0,
                 obj([(e0, q0)] * d0, d0, True)),
            step(L, "demonstrate", 4, "%d sweets shared equally among %d plates is %d each. We write %d \u00f7 %d = %d." % (T0, d0, q0, T0, d0, q0),
                 obj([(e0, q0)] * d0, d0, result=q0)),
            step(L, "demonstrate", 5, "We can also ask: how many plates of %d can we fill from %d sweets? We make groups of %d, and we get %d groups. Same numbers, same sum: %d \u00f7 %d = %d." % (
                d0, T0, d0, q0, T0, d0, q0), obj([(e0, d0)] * q0, q0))]

    def cands(T, d):
        q = T // d
        return {"divisor": [d], "total": [T], "near": [q - 1, q + 1], "wrong_op": [T - d], "far": [q + 4, q + 6]}

    fbd = {"divisor": "{d} is the number you share among. We want how many each one gets.",
           "total": "{d} is all the sweets, before sharing. We want how many each gets.",
           "near": "Close, but not quite. Share one at a time and count again.",
           "wrong_op": "{d} comes from taking away. Here we share equally.",
           "far": "That is a long way off. Share the items one at a time between the groups."}

    def d_share(p, role, i, diff):
        T, d = p
        q = T // d
        e = ctx.emo(role, i)
        return {"task": "share", "prompt": "Share equally among %d plates. How many on each plate?" % d,
                "visual": obj([(e, T)], 1, q=True), "answer": q, "dist": pick_dist(rng_i(ctx, role, i), q, cands(T, d), 0, 40), "fb": fbd,
                "hints": ["Give one to each plate, again and again, until none are left.", "Each plate gets %s." % ", then ".join(["1"] * 1) + " Keep going until all %d are shared." % T],
                "expl": "%d shared equally among %d is %d each, so %d \u00f7 %d = %d." % (T, d, q, T, d, q), "diff": diff}

    kids = ["children", "friends", "boxes", "bags"]
    stuff = ["stickers", "marbles", "pencils", "mangoes"]

    def d_story(p, role, i, diff):
        T, d = p
        q = T // d
        r = rng_i(ctx, role, i)
        k, s = r.choice(kids), r.choice(stuff)
        return {"task": "share_story", "prompt": "%d %s are shared equally among %d %s. How many does each one get?" % (T, s, d, k),
                "visual": NONE, "answer": q, "dist": pick_dist(rng_i(ctx, role, i), q, cands(T, d), 0, 40), "fb": fbd,
                "hints": ["Think of %d equal groups. Share one at a time." % d, "Count how many each group gets until all %d are used." % T],
                "expl": "%d \u00f7 %d = %d, so each one gets %d." % (T, d, q, q), "diff": diff}

    def d_sym(p, role, i, diff):
        T, d = p
        q = T // d
        return {"task": "sym", "prompt": "%d \u00f7 %d = ?" % (T, d), "speech": "%s divided by %s equals what?" % (nw(T), nw(d)),
                "visual": NONE, "answer": q, "dist": pick_dist(rng_i(ctx, role, i), q, cands(T, d), 0, 40), "fb": fbd,
                "hints": ["\u00f7 means share equally. Share %d into %d equal groups." % (T, d), "Think: %d times what number makes %d?" % (d, T)],
                "expl": "%d \u00f7 %d = %d." % (T, d, q), "diff": diff}

    def d_bags(p, role, i, diff):
        T, d = p
        q = T // d
        e = ctx.emo(role, i)
        return {"task": "bags", "prompt": "Put %d sweets into bags of %d. How many bags?" % (T, d),
                "visual": obj([(e, T)], 1, q=True), "answer": q, "dist": pick_dist(rng_i(ctx, role, i), q, cands(T, d), 0, 40), "fb": fbd,
                "hints": ["Make a bag of %d, then another, until none are left." % d, "Count the bags you can make. Each bag takes %d away." % d],
                "expl": "%d sweets in bags of %d make %d bags, so %d \u00f7 %d = %d." % (T, d, q, T, d, q), "diff": diff}

    g = [d_share(drawv(6, 15), "guided", 0, 1), d_bags(drawv(8, 16), "guided", 1, 1)]
    pr = [d_story(drawb(8, 16), "practice", 0, 2), d_sym(drawb(10, 20), "practice", 1, 2), d_share(drawv(12, 20), "practice", 2, 2),
          d_bags(drawv(12, 24), "practice", 3, 3)]
    mk = [lambda i: d_share(drawv(10, 24), "check", i, 2), lambda i: d_sym(drawb(12, 30), "check", i, 3),
          lambda i: d_bags(drawv(10, 24), "check", i, 2), lambda i: d_story(drawb(10, 24), "check", i, 2)]
    variants = [[0, 1, 2], [3, 2, 1], [1, 3, 0]]
    ck = [mk[v](i) for i, v in enumerate(variants[ctx.idx % 3])]
    rp = drawv(8, 18)
    rT, rd = rp
    rq = rT // rd
    er = ctx.emo("rem")
    remx = [step(L, "remediation_explain", 1,
                 "Let us try another way: take away the same number again and again. Start with %d. Take away %d each time. Count how many times until none are left." % (rT, rd),
                 glyph(" \u2212 ".join([str(rT)] + [str(rd)] * rq) + " = 0")),
            step(L, "remediation_explain", 2, "Make bags of %d. Each bag takes %d away. We can make %d bags." % (rd, rd, rq),
                 obj([(er, rd)] * rq, rq, True)),
            step(L, "remediation_explain", 3, "We took away %d exactly %d times, so %d \u00f7 %d = %d." % (rd, rq, rT, rd, rq),
                 glyph("%d \u00f7 %d = %d" % (rT, rd, rq)))]
    rg = [d_share(drawv(6, 14), "remediation_guided", 0, 1), d_bags(drawv(6, 15), "remediation_guided", 1, 1)]
    rc = [d_share(drawv(8, 20), "remediation_check", 0, 2), d_sym(drawb(10, 24), "remediation_check", 1, 2),
          d_story(drawb(10, 24), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


def build_fraction(ctx, N0):
    rng = ctx.rng
    L = ctx.lid
    pool = Pool([n for n in range(2, 41, 2) if n != N0], rng)

    def draw(lo, hi):
        return pool.take(lambda n: lo <= n <= hi, (lambda n: n <= hi) if hi <= 24 else (lambda n: n >= lo))

    def drawv(lo, hi):
        return pool.take(lambda n: lo <= n <= min(hi, 20), lambda n: n <= 20)

    def drawb(lo, hi):
        return pool.take(lambda n: n > 20 and lo <= n <= hi, lambda n: n > 20, lambda n: lo <= n <= hi, lambda n: True)

    e0 = ctx.emo("demo")
    h0 = N0 // 2
    intro = [step(L, "introduce", 1, "A half is one of two equal parts. Here are 6 cookies in two equal groups of 3. Each group is one half.",
                  obj([(ctx.emo("demo", 3), 3)] * 2, 2)),
             step(L, "introduce", 2, "We write one half as \u00bd. To find a half of a set, we share the set equally into 2 groups.",
                  glyph("\u00bd"))]
    demo = [step(L, "demonstrate", 1, "Here is a set of %d things. This is the whole set." % N0, obj([(e0, N0)], 1)),
            step(L, "demonstrate", 2, "Share them equally into 2 groups. Each group has %d. Each group is one half of the set." % h0,
                 obj([(e0, h0)] * 2, 2)),
            step(L, "demonstrate", 3, "One half of %d is %d. We write \u00bd of %d = %d." % (N0, h0, N0, h0),
                 obj([(e0, h0)] * 2, 1, result=h0)),
            step(L, "demonstrate", 4, "Check: %d + %d = %d. Two halves make the whole set." % (h0, h0, N0), obj([(e0, h0)] * 2, 2, result=N0)),
            step(L, "demonstrate", 5, "Careful: the two groups must be equal. %d and %d are not equal, so they are not halves." % (h0 + 1, h0 - 1),
                 obj([(e0, h0 + 1), (e0, h0 - 1)], 2))]

    def cands(N):
        h = N // 2
        return {"whole": [N], "near": [h - 1, h + 1], "wrong_op": [N - 2, N + 2], "far": [h + 4, h - 4, 2], "double": [N * 2]}

    fbf = {"whole": "{d} is the whole set. A half is only part of it.", "near": "Close. Share into 2 equal groups and count one group.",
           "wrong_op": "{d} is not one of two equal parts. Share the set equally into 2 groups.",
           "far": "That is a long way off. Split the set into 2 equal groups.",
           "double": "{d} is double the set. A half is smaller than the whole."}

    def f_set(N, role, i, diff):
        e = ctx.emo(role, i)
        h = N // 2
        return {"task": "half_set", "prompt": "What is half of this set?", "speech": "What is one half of this set?",
                "visual": obj([(e, N)], 1, q=True), "answer": h, "dist": pick_dist(rng_i(ctx, role, i), h, cands(N), 0, 99), "fb": fbf,
                "hints": ["Share the set equally into two groups.", "Give one to each group in turn until none are left. One group is the half."],
                "expl": "Half of %d is %d, because 2 groups of %d make %d." % (N, h, h, N), "diff": diff}

    def f_sym(N, role, i, diff):
        h = N // 2
        return {"task": "half_sym", "prompt": "\u00bd of %d = ?" % N, "speech": "One half of %s equals what?" % nw(N), "visual": NONE, "answer": h,
                "dist": pick_dist(rng_i(ctx, role, i), h, cands(N), 0, 99), "fb": fbf,
                "hints": ["A half means sharing into two equal groups.", "Which number added to itself makes %d?" % N],
                "expl": "\u00bd of %d = %d." % (N, h), "diff": diff}

    stuffs = ["mangoes", "stickers", "marbles", "stars"]

    def f_story(N, role, i, diff):
        h = N // 2
        s = rng_i(ctx, role, i).choice(stuffs)
        return {"task": "half_story", "prompt": "You have %d %s and you share them equally with one friend. How many does each of you get?" % (N, s),
                "visual": NONE, "answer": h, "dist": pick_dist(rng_i(ctx, role, i), h, cands(N), 0, 99), "fb": fbf,
                "hints": ["There are two people, so share into two equal groups.", "Give one to each person in turn until none are left."],
                "expl": "Each gets half of %d, which is %d." % (N, h), "diff": diff}

    def f_split(N, role, i, diff):
        h = N // 2
        r = rng_i(ctx, role, i)
        ds = r.sample([1, 2, 3], 2)
        fmt = lambda a, b: "%d and %d" % (a, b)
        return {"task": "which_split", "prompt": "%d sweets are split into two groups. Which split gives two equal halves?" % N,
                "visual": NONE, "answer": fmt(h, h), "dist": [(fmt(h + x, h - x), "uneq") for x in ds if h - x >= 0],
                "fb": {"uneq": lambda d: "The two groups, %s, are not equal, so they are not halves." % d},
                "hints": ["Halves are two groups that are exactly the same size.", "Which two groups add up to %d and are the same size?" % N],
                "expl": "%d and %d are equal and make %d, so they are halves." % (h, h, N), "diff": diff}

    g = [f_set(drawv(4, 12), "guided", 0, 1), f_split(drawb(6, 14), "guided", 1, 1)]
    pr = [f_story(drawb(6, 16), "practice", 0, 2), f_sym(drawb(8, 20), "practice", 1, 2), f_set(drawv(10, 20), "practice", 2, 2),
          f_split(drawb(10, 22), "practice", 3, 3)]
    mk = [lambda i: f_set(drawv(8, 20), "check", i, 2), lambda i: f_sym(drawb(10, 40), "check", i, 3),
          lambda i: f_split(drawb(10, 30), "check", i, 2), lambda i: f_story(drawb(10, 30), "check", i, 2)]
    variants = [[0, 1, 2], [3, 2, 1], [1, 0, 3]]
    ck = [mk[v](i) for i, v in enumerate(variants[ctx.idx % 3])]
    rN = drawv(6, 14)
    rh = rN // 2
    er = ctx.emo("rem")
    remx = [step(L, "remediation_explain", 1, "Let us try with pairs. Put the things in pairs, one for you and one for a friend. Here are %d things." % rN,
                 obj([(er, 1)] * rh + [(er, 1)] * 0 if False else [(er, 2)] * rh, rh)),
            step(L, "remediation_explain", 2, "There are %d pairs. In each pair, one is for you and one is for your friend. So you get %d and your friend gets %d." % (rh, rh, rh),
                 glyph("%d + %d = %d" % (rh, rh, rN))),
            step(L, "remediation_explain", 3, "So half of %d is the number of pairs, %d. Half is the opposite of doubling: %d + %d = %d." % (rN, rh, rh, rh, rN),
                 glyph("\u00bd of %d = %d" % (rN, rh)))]
    rg = [f_set(drawv(4, 12), "remediation_guided", 0, 1), f_split(drawb(6, 14), "remediation_guided", 1, 1)]
    rc = [f_set(drawv(8, 20), "remediation_check", 0, 2), f_sym(drawb(10, 30), "remediation_check", 1, 2),
          f_story(drawb(10, 30), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


def build_percent(ctx, P0, N0):
    rng = ctx.rng
    L = ctx.lid
    items = [(25, n) for n in range(4, 41, 4)] + [(50, n) for n in range(4, 41, 2)]
    items = [x for x in items if x != (P0, N0)]
    pool = Pool(items, rng)

    def drawv(lo, hi, pct=None):
        return pool.take(lambda x: lo <= x[1] <= min(hi, 20) and (pct is None or x[0] == pct), lambda x: x[1] <= 20)

    def drawb(lo, hi, pct=None):
        return pool.take(lambda x: x[1] > 20 and (pct is None or x[0] == pct), lambda x: x[1] > 20,
                         lambda x: lo <= x[1] <= hi, lambda x: True)

    def draw(lo, hi, pct=None):
        return pool.take(lambda x: lo <= x[1] <= hi and (pct is None or x[0] == pct), lambda x: lo <= x[1] <= hi,
                         (lambda x: x[1] <= hi) if hi <= 24 else (lambda x: x[1] >= lo))

    e0 = ctx.emo("demo")
    q0 = N0 // 4
    intro = [step(L, "introduce", 1, "Percent means out of 100 parts. 100% is the whole set, one whole. We write percent with the sign %.", glyph("100%")),
             step(L, "introduce", 2, "Some percents are easy fractions. 50% is the same as one half. 25% is the same as one quarter.",
                  glyph("50% = \u00bd     25% = \u00bc"))]
    demo = [step(L, "demonstrate", 1, "Here is a set of %d things. The whole set is 100%%." % N0, obj([(e0, N0)], 1)),
            step(L, "demonstrate", 2, "Split the whole set into 4 equal groups. Each group has %d. Each group is 25%% of the set." % q0,
                 obj([(e0, q0)] * 4, 4)),
            step(L, "demonstrate", 3, "One group is 25%% of the set. So 25%% of %d is %d." % (N0, q0), obj([(e0, q0)] * 4, 1, result=q0)),
            step(L, "demonstrate", 4, "Two groups make 50%%, which is one half. 50%% of %d is %d." % (N0, 2 * q0), obj([(e0, q0)] * 4, 2, result=2 * q0)),
            step(L, "demonstrate", 5, "To find 25%% of a number, share it into 4 equal groups: %d \u00f7 4 = %d." % (N0, q0), glyph("25%% of %d = %d \u00f7 4 = %d" % (N0, N0, q0)))]
    # percent distractors
    def val(x):
        p, n = x
        return n // 4 if p == 25 else n // 2

    def cands(x):
        p, n = x
        a = val(x)
        other = n // 2 if p == 25 else n // 4
        return {"other": [other], "whole": [n], "near": [a - 1, a + 1], "far": [a + 5, a - 5, a + 4], "pct": [p]}

    fbp = {"other": lambda d: "{d} is for the other percent. Check which fraction the percent is.".format(d=d),
           "whole": "{d} is the whole set (100%). We want only part of it.", "near": "Close. Share into equal groups and count one group again.",
           "far": "That is a long way off. Split the whole set into equal groups first.",
           "pct": "{d} is the percent number itself. We want that percent of the set."}

    def fbp_for(x):
        p, n = x
        a = val(x)

        def f(d):
            v = int(d)
            if v == n:
                return "%d is all %d things, the whole set (100%%). We want only %d%% of it." % (v, n, p)
            if v == n // 2 and p != 50:
                return "%d is half of %d, which is 50%%. We want %d%%." % (v, n, p)
            if v == n // 4 and p != 25:
                return "%d is a quarter of %d, which is 25%%. We want %d%%." % (v, n, p)
            if v == p:
                return "%d is the percent number itself, not an amount from the set." % v
            if abs(v - a) == 1:
                return "Close. Share the set into equal groups and count one group again."
            return "Not quite. Share the set into equal groups first."
        return AnyKind(f)

    def parts(p):
        return (4, "25%", "four equal groups") if p == 25 else (2, "50%", "two equal groups")

    def p_set(x, role, i, diff):
        p, n = x
        a = val(x)
        e = ctx.emo(role, i)
        k = 4 if p == 25 else 2
        return {"task": "pct_set", "prompt": "What is %d%% of this set?" % p, "speech": "What is %s percent of this set?" % nw(p),
                "visual": obj([(e, n)], 1, q=True), "answer": a, "dist": pick_dist(rng_i(ctx, role, i), a, cands(x), 1, 99), "fb": fbp_for(x),
                "hints": ["%d%% is %s. Share the set into %s equal groups." % (p, "one quarter" if p == 25 else "one half", nw(k)),
                          "One group is the answer. Divide %d by %d." % (n, k)],
                "expl": "%d%% of %d is %d, because %d \u00f7 %d = %d." % (p, n, a, n, k, a), "diff": diff}

    def p_sym(x, role, i, diff):
        p, n = x
        a = val(x)
        k = 4 if p == 25 else 2
        return {"task": "pct_sym", "prompt": "%d%% of %d = ?" % (p, n), "speech": "%s percent of %s equals what?" % (nw(p), nw(n)),
                "visual": NONE, "answer": a, "dist": pick_dist(rng_i(ctx, role, i), a, cands(x), 1, 99), "fb": fbp_for(x),
                "hints": ["%d%% is the same as %s." % (p, "one quarter" if p == 25 else "one half"), "Divide %d by %d." % (n, k)],
                "expl": "%d%% of %d = %d \u00f7 %d = %d." % (p, n, n, k, a), "diff": diff}

    fr = ["mangoes", "balloons", "stickers", "pencils"]

    def p_story(x, role, i, diff):
        p, n = x
        a = val(x)
        k = 4 if p == 25 else 2
        s = rng_i(ctx, role, i).choice(fr)
        return {"task": "pct_story", "prompt": "A box has %d %s. %d%% of them are red. How many are red?" % (n, s, p),
                "visual": NONE, "answer": a, "dist": pick_dist(rng_i(ctx, role, i), a, cands(x), 1, 99), "fb": fbp_for(x),
                "hints": ["%d%% means %s of the %s." % (p, "one quarter" if p == 25 else "one half", s), "Share the %d into %s equal groups." % (n, nw(k))],
                "expl": "%d%% of %d is %d." % (p, n, a), "diff": diff}

    def p_match(pv, role, i, diff):
        name = {25: "one quarter", 50: "one half", 100: "one whole"}[pv]
        allopts = ["one quarter", "one half", "one whole"]
        return {"task": "match_fraction", "prompt": "%d%% is the same as which fraction?" % pv, "speech": "%s percent is the same as which fraction?" % nw(pv),
                "visual": NONE, "answer": name, "dist": [(o, "no") for o in allopts if o != name],
                "fb": {"no": lambda d: "%s is a different amount. Think about how many equal parts 100%% is split into." % d.capitalize()},
                "hints": ["Think about how many equal groups the whole set is split into.", "%d%% means %s of the whole." % (pv, name)],
                "expl": "%d%% is the same as %s." % (pv, name), "diff": diff}

    matchq = [50, 100, 25]
    g = [p_set(drawv(8, 20, 50), "guided", 0, 1), p_sym(drawb(8, 20, 25), "guided", 1, 1)]
    mpr = p_match(50 if P0 == 25 else 25, "practice", 0, 2)
    pr = [p_story(drawb(8, 20), "practice", 0, 2), p_sym(drawb(10, 24), "practice", 1, 2), mpr, p_set(drawv(12, 24), "practice", 3, 3)]
    chk_match = p_match(100, "check", 1, 2)
    mk = [lambda i: p_set(drawv(12, 28), "check", i, 2), lambda i: p_sym(drawb(12, 40), "check", i, 3),
          lambda i: chk_match, lambda i: p_story(drawb(12, 32), "check", i, 2)]
    variants = [[0, 1, 2], [3, 2, 1], [1, 0, 3]]
    # the match item must also have been practised: it was (task match_fraction in practice)
    ck = [mk[v](i) for i, v in enumerate(variants[ctx.idx % 3])]
    rx = drawv(8, 20, 50)
    rp_, rn_ = rx
    ra = rn_ // 2
    er = ctx.emo("rem")
    remx = [step(L, "remediation_explain", 1, "Let us start from a half. 50%% is one half. Here are %d things in two equal halves of %d." % (rn_, ra),
                 obj([(er, ra)] * 2, 2)),
            step(L, "remediation_explain", 2, "A quarter is half of a half. Split each half in two. Now there are 4 equal groups. Each group is a quarter, 25%.",
                 obj([(er, ra // 2 if ra % 2 == 0 else ra)] * (4 if ra % 2 == 0 else 2), 4 if ra % 2 == 0 else 2)),
            step(L, "remediation_explain", 3, "So 50%% of %d is %d (one half), and 25%% is half of that." % (rn_, ra), glyph("50% = \u00bd   25% = \u00bc"))] if False else [
        step(L, "remediation_explain", 1, "Let us start from a half. 50%% is one half. Here are %d things in two equal halves of %d." % (rn_, ra), obj([(er, ra)] * 2, 2)),
        step(L, "remediation_explain", 2, "A quarter is half of a half. Splitting each half in two gives 4 equal groups. Each group is 25%, one quarter.",
             glyph("\u00bd of \u00bd = \u00bc")),
        step(L, "remediation_explain", 3, "So 50%% of %d is %d, one half. And 25%% is one quarter. To find a percent, split the whole into equal groups." % (rn_, ra),
             glyph("\u00bd = 50%     \u00bc = 25%"))]
    rg = [p_set(drawv(8, 16, 50), "remediation_guided", 0, 1), p_sym(drawb(8, 20, 25), "remediation_guided", 1, 1)]
    rc = [p_set(drawv(8, 24), "remediation_check", 0, 2), p_sym(drawb(10, 30), "remediation_check", 1, 2),
          p_match(25 if P0 != 25 else 50, "remediation_check", 2, 2) if False else p_story(drawb(10, 32), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# --------------------------------------------------------- skill: NUM NAMES
def build_names(ctx, n0):
    rng = ctx.rng
    L = ctx.lid
    nums = [k for k in range(1, 11)]
    seen_k, seen_tk = set(), set()
    e0 = ctx.emo("demo")
    w0 = nw(n0)

    def draw(task, *preds):
        ok = [k for k in nums if k != n0 and (not preds or all(p(k) for p in preds))]
        fresh = [k for k in ok if k not in seen_k]
        cand = fresh or [k for k in ok if (task, k) not in seen_tk]
        k = rng.choice(cand)
        seen_k.add(k)
        seen_tk.add((task, k))
        return k

    intro = [step(L, "introduce", 1, "Every number has a name. We can say it and we can write it with a word. Today we learn the names of the numbers one to ten, starting with the number %d." % n0, glyph(str(n0))),
             step(L, "introduce", 2, "We will count first, then match the number to its name.", obj([(e0, n0)], 1, True))]
    demo = [step(L, "demonstrate", 1, "Count the things: %s. There are %d. The name of %d is the word '%s'." % (", ".join(str(k) for k in range(1, n0 + 1)), n0, n0, w0), obj([(e0, n0)], 1, True)),
            step(L, "demonstrate", 2, "This is the number %d. It is a numeral, written with a digit. Its name is the word '%s'." % (n0, w0), glyph("%d  %s" % (n0, w0))),
            step(L, "demonstrate", 3, "Here are the names of the numbers one to five: one, two, three, four, five. Say each one as you look at it.",
                 glyph("1 one     2 two     3 three     4 four     5 five")),
            step(L, "demonstrate", 4, "And here are the names of the numbers six to ten: six, seven, eight, nine, ten. Say each one as you look at it.",
                 glyph("6 six     7 seven     8 eight     9 nine     10 ten")),
            step(L, "demonstrate", 5, "On the number line, start at 0 and take %d steps. We land on %d, and the name is '%s'. Each number has its own name." % (n0, n0, w0), line(0, 10, 0, n0, True))]

    words = {k: nw(k) for k in range(0, 11)}

    def cands_w(k):
        return {"near": [k - 1, k + 1], "other": [k + 2, k - 2, k + 3], "far": [k + 4, k - 4, k + 5]}

    def n_to_w(k, role, i, diff):
        dist = pick_dist(rng_i(ctx, role, i), k, cands_w(k), 1, 10)
        return {"task": "numeral_to_word", "prompt": "Which word is the name of this number?", "visual": glyph(str(k)), "answer": words[k],
                "dist": [(words[v], kk) for v, kk in dist],
                "fb": {"near": "That is the name of the number next to it. Count to find the right one.",
                       "other": "That is the name of a different number. Count up to the number and say it.",
                       "far": "That is the name of a much different number. Count up to this number and say it."},
                "hints": ["Count up to the number out loud: 1, 2, 3 ... The last number you say is the name.",
                          "Count: %s. The name is '%s'." % (", ".join(str(j) for j in range(1, k + 1)), words[k])],
                "expl": "The number %d is called %s." % (k, words[k]), "diff": diff}

    def w_to_n(k, role, i, diff):
        dist = pick_dist(rng_i(ctx, role, i), k, cands_w(k), 1, 10)
        return {"task": "word_to_numeral", "prompt": "Which number is '%s'?" % words[k], "speech": "Which number is %s?" % words[k], "visual": NONE, "answer": k,
                "dist": dist, "fb": {"near": "Close, but that is the number next to it. Count up and say the names.",
                                     "other": "That is a different number. Count up and say the names as you go.",
                                     "far": "That is a much different number. Count up and say the names as you go."},
                "hints": ["Count up out loud: one, two, three ... Stop when you say the word.", "Count: %s. The number is %d." % (", ".join(words[j] for j in range(1, k + 1)), k)],
                "expl": "'%s' is the number %d." % (words[k], k), "diff": diff}

    def c_to_w(k, role, i, diff):
        e = ctx.emo(role, i)
        dist = pick_dist(rng_i(ctx, role, i), k, cands_w(k), 1, 10)
        return {"task": "count_to_word", "prompt": "Count the things. Which word tells how many?", "visual": obj([(e, k)], 1, q=True), "answer": words[k],
                "dist": [(words[v], kk) for v, kk in dist],
                "fb": {"near": "Close. Count again, touching each one only once, and say the last number.",
                       "other": "That is the name of a different number. Count again.", "far": "That is the name of a much different number. Count again."},
                "hints": ["Touch every thing, a single time, as you count.", "Count: %s. The word is '%s'." % (", ".join(str(j) for j in range(1, k + 1)), words[k])],
                "expl": "There are %d, and %d is called %s." % (k, k, words[k]), "diff": diff}

    g = [c_to_w(draw("c", lambda k: k <= 6), "guided", 0, 1), n_to_w(draw("n", lambda k: k >= 6), "guided", 1, 1)]
    pr = [w_to_n(draw("w"), "practice", 0, 2), n_to_w(draw("n"), "practice", 1, 2), c_to_w(draw("c"), "practice", 2, 2), w_to_n(draw("w"), "practice", 3, 3)]
    # check includes the lesson's own number (objective) in a new form, plus other numbers
    mk = [lambda i: c_to_w(n0, "check", i, 2) if False else n_to_w(n0, "check", i, 2), lambda i: w_to_n(draw("w"), "check", i, 2),
          lambda i: c_to_w(draw("c"), "check", i, 3), lambda i: w_to_n(n0, "check", i, 2)]
    # the own number appears once in check, in a representation different from the demo count
    variants = [[0, 1, 2], [1, 3, 2], [2, 0, 1]]
    ck = [mk[v](i) for i, v in enumerate(variants[ctx.idx % 3])]
    rk = draw("r", lambda k: k >= 3)
    er = ctx.emo("rem")
    remx = [step(L, "remediation_explain", 1, "Let us try with the number line. Start at 0. Count steps and say the numbers: %s." % ", ".join(words[j] for j in range(1, rk + 1)),
                 line(0, 10, 0, rk, True)),
            step(L, "remediation_explain", 2, "We land on %d. The name of %d is '%s'." % (rk, rk, words[rk]), glyph("%d  %s" % (rk, words[rk]))),
            step(L, "remediation_explain", 3, "Now count %d things and say the name: %s." % (rk, ", ".join(words[j] for j in range(1, rk + 1))), obj([(er, rk)], 1, True))]
    rg = [c_to_w(draw("c"), "remediation_guided", 0, 1), w_to_n(draw("w"), "remediation_guided", 1, 1)]
    rc = [n_to_w(draw("n"), "remediation_check", 0, 2), c_to_w(draw("c"), "remediation_check", 1, 2), w_to_n(draw("w"), "remediation_check", 2, 3)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ----------------------------------------------------------- EVERYDAY maths
PARTS = ["morning", "afternoon", "evening", "night"]
PART_EMO = {"morning": "\U0001F305", "afternoon": "\u2600\uFE0F", "evening": "\U0001F307", "night": "\U0001F319"}
SCEN = {
    "morning": ["You wake up when the sun is just coming up.", "You brush your teeth and get ready for school after waking up.", "You hear the birds singing as the day begins.", "You eat breakfast before school."],
    "afternoon": ["You eat lunch when the sun is high in the sky.", "You play outside after lunch, while the sun is still high.", "You have a short rest after lunch, in the middle of the day."],
    "evening": ["The sun is going down and you play in the park.", "The sky turns orange and you have tea and snacks.", "Your family sits together as the sun sets."],
    "night": ["You see the moon and the stars and you go to bed.", "It is dark outside and you are fast asleep.", "Everyone is asleep and the stars are out."],
}


def build_morning(ctx):
    rng = ctx.rng
    L = ctx.lid
    used = {("breakfast",)}
    sc_pool = Pool([(p, t) for p in PARTS for t in SCEN[p] if "breakfast" not in t], rng)
    rel = {"after": [("morning", "afternoon"), ("afternoon", "evening"), ("evening", "night"), ("night", "morning")],
           "before": [("afternoon", "morning"), ("evening", "afternoon"), ("night", "evening"), ("morning", "night")]}
    rel_pool = {k: Pool(v, rng) for k, v in rel.items()}
    intro = [step(L, "introduce", 1, "The day has parts. The first part is the morning. This is a child waking up in the morning.", pic("assets/images/age56/morning.webp", "Morning")),
             step(L, "introduce", 2, "We do different things in different parts of the day.", glyph("\U0001F305 \u2600\uFE0F \U0001F307 \U0001F319"))]
    demo = [step(L, "demonstrate", 1, "In the morning, the sun comes up and we wake up.", pic("assets/images/age56/morning.webp", "Morning")),
            step(L, "demonstrate", 2, "We eat breakfast in the morning. Breakfast is the first meal of the day.", glyph("\U0001F373")),
            step(L, "demonstrate", 3, "The day has four parts: morning, afternoon, evening and night, in that order.", glyph("\U0001F305 \u2192 \u2600\uFE0F \u2192 \U0001F307 \u2192 \U0001F319")),
            step(L, "demonstrate", 4, "After the morning comes the afternoon, when the sun is high and we eat lunch. Before the morning comes the night.", glyph("\U0001F305 \u2192 \u2600\uFE0F")),
            step(L, "demonstrate", 5, "To tell the part of the day, look at the clue: the sun rising is morning, the sun high is afternoon, the sun going down is evening, and the moon and stars mean night.",
                 glyph("\U0001F305 \u2600\uFE0F \U0001F307 \U0001F319"))]

    def times(p, role, i, diff, picture):
        part, text = p
        others = [x for x in PARTS if x != part]
        rr = rng_i(ctx, role, i)
        d = rr.sample(others, 2)
        fbp_ = {"no": lambda dd, part=part: "That is not the part of the day we want. Look at the clue again: where is the sun, or is it dark?"}
        return {"task": "time_of_day", "prompt": text + " What part of the day is it?", "visual": glyph(PART_EMO[part]) if picture else NONE, "answer": part,
                "dist": [(x, "no") for x in d], "fb": fbp_,
                "hints": ["Think about the sun: is it rising, high, going down, or gone?", "The clue tells us it is the %s." % part],
                "expl": "This happens in the %s." % part, "diff": diff}

    def relq(kind, role, i, diff, scaffold=False):
        a, b = rel_pool[kind].take()
        word = "after" if kind == "after" else "before"
        part_given, ans = a, b
        others = [x for x in PARTS if x not in (ans, part_given)]
        rr = rng_i(ctx, role, i)
        d = [part_given] + [rr.choice(others)] if rr.random() < .5 else rr.sample(others, 2) if len(others) >= 2 else [part_given, others[0]]
        d = list(dict.fromkeys(d))[:2]
        if len(d) < 2:
            d.append([x for x in PARTS if x not in d and x != ans][0])
        return {"task": "order_" + kind, "prompt": "Which part of the day comes %s the %s?" % (word, part_given),
                "visual": glyph("\U0001F305 \u2192 \u2600\uFE0F \u2192 \U0001F307 \u2192 \U0001F319") if scaffold else NONE, "answer": ans,
                "dist": [(x, "no") for x in d], "fb": {"no": lambda dd, w=word, g=part_given: "That is not the part that comes %s the %s. Say the parts of the day in order and listen for which one follows it." % (w, g)},
                "hints": ["Say the parts of the day in order, from the first one, and find the one given.", "The parts go round and round, and after the last part the day starts again."],
                "expl": "The %s comes %s the %s." % (ans, word, part_given), "diff": diff}

    g = [times(sc_pool.take(lambda x: x[0] == "afternoon"), "guided", 0, 1, True), relq("after", "guided", 1, 1, True)]
    pr = [times(sc_pool.take(lambda x: x[0] == "night"), "practice", 0, 1, True), times(sc_pool.take(lambda x: x[0] == "evening"), "practice", 1, 2, False),
          relq("before", "practice", 2, 2), relq("after", "practice", 3, 3)]
    ck_all = [lambda i: times(sc_pool.take(lambda x: x[0] in ("morning",)), "check", i, 2, False),
              lambda i: times(sc_pool.take(lambda x: x[0] in ("afternoon", "evening", "night")), "check", i, 3, False),
              lambda i: relq("after", "check", i, 2), lambda i: relq("before", "check", i, 3)]
    order = [[0, 2, 1], [1, 0, 3], [3, 1, 0]][ctx.idx % 3] if False else [0, 2, 1]
    ck = [ck_all[k](i) for i, k in enumerate(order)]
    remx = [step(L, "remediation_explain", 1, "Let us use clues. When the sun is low and just coming up, it is the morning. We wake up.", glyph("\U0001F305")),
            step(L, "remediation_explain", 2, "When the sun is high, it is the afternoon. When the sun is going down, the sky turns orange and it is the evening.", glyph("\u2600\uFE0F   \U0001F307")),
            step(L, "remediation_explain", 3, "When it is dark and we can see the moon and stars, it is night. We sleep at night.", glyph("\U0001F319"))]
    rg = [times(sc_pool.take(lambda x: x[0] == "evening"), "remediation_guided", 0, 1, True), relq("before", "remediation_guided", 1, 1, True)]
    rc = [times(sc_pool.take(lambda x: x[0] == "night"), "remediation_check", 0, 2, False), relq("after", "remediation_check", 1, 2),
          times(sc_pool.take(lambda x: x[0] == "afternoon"), "remediation_check", 2, 2, False)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


def build_longer(ctx):
    rng = ctx.rng
    L = ctx.lid
    asset = "assets/images/age56/longer.webp"
    pairs = Pool([(x, y) for x in range(2, 10) for y in range(2, 10) if x != y], rng)
    names = ["rope", "ribbon", "stick", "pencil", "string", "scarf"]
    npool = Pool([(a, b) for a in names for b in names if a != b], rng)
    wp = Pool([(a, b, w) for a in names for b in names if a != b for w in ("longer", "shorter")], rng)
    intro = [step(L, "introduce", 1, "Length tells us how long something is. Here are two pencils.", pic(asset, "Two pencils")),
             step(L, "introduce", 2, "We can say one is longer and the other is shorter.", pic(asset, "Two pencils"))]
    demo = [step(L, "demonstrate", 1, "The top pencil is longer than the bottom pencil. Longer means it has more length.", pic(asset, "Longer: the top pencil")),
            step(L, "demonstrate", 2, "The bottom pencil is shorter than the top pencil. Shorter means it has less length.", pic(asset, "Shorter: the bottom pencil")),
            step(L, "demonstrate", 3, "To compare lengths, put the ends of the two things together, at the same starting line. Then we can see which one reaches further.",
                 glyph("\U0001F4CF")),
            step(L, "demonstrate", 4, "We can also measure with the same small units, like paper clips. A rope of 6 clips and a rope of 4 clips: the rope with more clips is longer.",
                 obj([("\U0001F4CE", 6), ("\U0001F4CE", 4)], 2, op="vs", labels=["First rope", "Second rope"])),
            step(L, "demonstrate", 5, "So 6 clips is longer, and 4 clips is shorter. A word we use to compare length is 'longer'. Longer, not lighter or heavier.", glyph("longer  \u2194  shorter"))]

    def units(p, role, i, diff, longer):
        x, y = p
        a, b = npool.take()
        ans_n = a if (x > y) == longer else b
        wrong = [b if ans_n == a else a, "same"]
        em = "\U0001F4CE"
        word = "longer" if longer else "shorter"
        return {"task": "units_" + word, "prompt": "The %s is %d clips long. The %s is %d clips long. Which is %s?" % (a, x, b, y, word),
                "visual": obj([(em, x), (em, y)], 2, op="vs", q=True, labels=["The " + a, "The " + b]), "answer": "The " + ans_n,
                "dist": [("The " + wrong[0], "other"), ("They are the same length", "same")],
                "fb": {"other": "Count the clips for each one. The one with %s clips is %s." % ("more" if longer else "fewer", word),
                       "same": "The numbers of clips are not the same, so the lengths are not the same."},
                "hints": ["Count the clips for each one. Compare the two numbers.", "The one with %s clips is %s." % ("more" if longer else "fewer", word)],
                "expl": "%d clips is %s than %d clips." % (max(x, y) if longer else min(x, y), word, min(x, y) if longer else max(x, y)), "diff": diff}

    def word_pick(role, i, diff):
        a, b, w = wp.take()
        ans = "shorter" if w == "longer" else "longer"
        third = "lighter" if rng_i(ctx, role, i).random() < .5 else "heavier"
        return {"task": "word_pick", "prompt": "The %s is %s than the %s. So the %s is ___" % (a, w, b, b), "speech": "The %s is %s than the %s. So the %s is what?" % (a, w, b, b),
                "visual": NONE, "answer": ans, "dist": [(w, "same"), (third, "weight")],
                "fb": {"same": "That is the word for the other one. The %s is the opposite." % b if False else "That is the word for the first one. The other one is the opposite.",
                       "weight": "%s is about weight, not length. We are comparing length." % third.capitalize()},
                "hints": ["Think about the opposite of the word in the sentence.", "If one is %s, the other has the opposite length." % w],
                "expl": "If the %s is %s, the %s is %s." % (a, w, b, ans), "diff": diff}

    def pic_q(role, i, diff):
        return {"task": "pic_longer", "prompt": "Which pencil is longer?", "visual": pic(asset, ""), "answer": "The top pencil",
                "dist": [("The bottom pencil", "bottom"), ("They are the same length", "same")],
                "fb": {"bottom": "Look where the pencils end. The bottom one stops sooner, so it is shorter.", "same": "The ends do not line up on the right. One reaches further."},
                "hints": ["Look at where each pencil starts and where each one ends.", "The one that reaches further is longer."], "expl": "The top pencil reaches further, so it is longer.", "diff": diff}

    def how(role, i, diff):
        return {"task": "how_compare", "prompt": "How do we compare the lengths of two things?", "visual": NONE, "answer": "Put their ends together",
                "dist": [("Look at their colours", "no"), ("Weigh them", "weigh")],
                "fb": {"no": "Colour does not tell us the length. Think about how to line the two things up.", "weigh": "Weighing tells us how heavy, not how long. We are comparing length."},
                "hints": ["Think about how to line the two things up fairly.", "We put them side by side, with the same starting line."], "expl": "We put the ends together and see which one reaches further.", "diff": diff}

    g = [pic_q("guided", 0, 1), word_pick("guided", 1, 1)]
    pr = [how("practice", 0, 1), units(pairs.take(), "practice", 1, 2, True), units(pairs.take(), "practice", 2, 2, False), word_pick("practice", 3, 2)]
    ck_all = [lambda i: units(pairs.take(), "check", i, 2, True), lambda i: word_pick("check", i, 2), lambda i: units(pairs.take(), "check", i, 3, False)]
    rot = ctx.idx % 3
    ck = [ck_all[(k + rot) % 3](i) for i, k in enumerate(range(3))]
    remx = [step(L, "remediation_explain", 1, "Let us line things up. Two things start at the same line. We look to see which one goes further.", glyph("\U0001F4CF  \U0001F4CF")),
            step(L, "remediation_explain", 2, "Count the blocks in the first line: 1, 2, 3, 4, 5, 6. It is 6 blocks long.", obj([("\U0001F9F1", 6), ("\U0001F9F1", 4)], 1, True, op="vs", labels=["First line", "Second line"])),
            step(L, "remediation_explain", 3, "The second line is 4 blocks long. 4 is fewer than 6, so the second line is shorter and the first line is longer.", obj([("\U0001F9F1", 6), ("\U0001F9F1", 4)], 2, op="vs", labels=["First line", "Second line"]))]
    rg = [units(pairs.take(), "remediation_guided", 0, 1, True), word_pick("remediation_guided", 1, 1)]
    rc = [units(pairs.take(), "remediation_check", 0, 2, False), word_pick("remediation_check", 1, 2), units(pairs.take(), "remediation_check", 2, 2, True)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


UNITS = {"rupees": "money", "metres": "length", "litres": "how much liquid"}
THINGS = {"rupees": ["the price of a toffee", "the price of a pencil", "the price of a banana", "the price of a bus ticket", "the price of a toy car"],
          "metres": ["how long a rope is", "how long a road is", "how long a table is", "how tall a pole is", "how long a ribbon is"],
          "litres": ["how much milk is in a jug", "how much water is in a bucket", "how much juice is in a bottle", "how much oil is in a can", "how much water is in a tank"]}


def build_rupees(ctx):
    rng = ctx.rng
    L = ctx.lid
    art = "assets/images/age56/rupees.webp"
    tp = {u: Pool(v, rng) for u, v in THINGS.items()}
    intro = [step(L, "introduce", 1, "In India we pay for things with coins and notes. This is money.", pic(art, "Coins and notes")),
             step(L, "introduce", 2, "Different things are measured with different units. Money has its own unit.", glyph("\u20b9"))]
    demo = [step(L, "demonstrate", 1, "We use coins and notes to pay for things in a shop.", pic(art, "Coins and notes")),
            step(L, "demonstrate", 2, "The unit for money in India is the rupee. We write rupees with the sign \u20b9. A toffee costs some rupees.", glyph("\u20b9")),
            step(L, "demonstrate", 3, "We do not measure money in metres. Metres measure length, like how long a rope is.", glyph("\U0001F4CF")),
            step(L, "demonstrate", 4, "We do not measure money in litres. Litres measure how much liquid there is, like milk or water.", glyph("\U0001F95B")),
            step(L, "demonstrate", 5, "So: rupees for money, metres for length, and litres for liquids. To choose the unit, ask what we are measuring.", glyph("\u20b9      m      L"))]
    names = {"rupees": "rupees", "metres": "metres", "litres": "litres"}
    fbu = {"rupees": "Rupees are for money. Is this about money?", "metres": "Metres measure length, how long something is.", "litres": "Litres measure how much liquid there is."}

    def unit_for(u, role, i, diff):
        t = tp[u].take()
        others = [x for x in names if x != u]
        return {"task": "unit_for", "prompt": "Which unit do we use to tell %s?" % t, "visual": NONE, "answer": u,
                "dist": [(o, o) for o in others], "fb": {o: fbu[o] for o in others},
                "hints": ["Ask: is it money, length or liquid?", "%s is %s, so the unit is %s." % (t.capitalize(), UNITS[u], u)],
                "expl": "%s is about %s, so we use %s." % (t.capitalize(), UNITS[u], u), "diff": diff}

    def money_word(role, i, diff):
        return {"task": "money_word", "prompt": "Which unit is used for money in India?", "visual": pic(art, ""), "answer": "rupees",
                "dist": [("metres", "metres"), ("litres", "litres")], "fb": {"metres": fbu["metres"], "litres": fbu["litres"]},
                "hints": ["Look at the picture. What do we pay with?", "Money in India is counted in rupees."], "expl": "Money in India is counted in rupees.", "diff": diff}

    pays = [("Which of these can we pay with in a shop?", "coins and notes", ["stones and leaves", "shoes and hats"]),
            ("What do you give the shopkeeper to buy a toy?", "money", ["water", "paper boats"]),
            ("Which of these is money?", "a coin", ["a pebble", "a button"]),
            ("How do we pay for a ticket at the bus stop?", "with notes and coins", ["with stones", "with feathers"])]
    pp = Pool(pays, rng)

    def pay(role, i, diff):
        pr_, ans, wr = pp.take()
        return {"task": "pay_with", "prompt": pr_, "visual": NONE, "answer": ans, "dist": [(w, "no") for w in wr],
                "fb": {"no": "We cannot pay with that. Think about what the shopkeeper accepts: coins and notes."},
                "hints": ["Think about what you give the shopkeeper.", "In India we pay with money: coins and notes."], "expl": "We pay with money: coins and notes.", "diff": diff}

    g = [money_word("guided", 0, 1), unit_for("metres", "guided", 1, 1)]
    pr = [unit_for("rupees", "practice", 0, 1), pay("practice", 1, 2), unit_for("litres", "practice", 2, 2), unit_for("rupees", "practice", 3, 3)]
    ck_all = [lambda i: unit_for("rupees", "check", i, 2), lambda i: unit_for("litres" if ctx.idx % 2 else "metres", "check", i, 2), lambda i: pay("check", i, 3),
              lambda i: unit_for("metres" if ctx.idx % 2 else "litres", "check", i, 3)]
    ck = [ck_all[0](0), ck_all[1](1), ck_all[2](2)]
    remx = [step(L, "remediation_explain", 1, "Let us think of three things in a shop. A toffee costs money, so we use rupees.", glyph("\u20b9  \u20b9  \u20b9")),
            step(L, "remediation_explain", 2, "A ribbon has a length, so we use metres. A jug of milk is a liquid, so we use litres.", glyph("m      L")),
            step(L, "remediation_explain", 3, "Ask yourself each time: money, length, or liquid? Money is rupees, length is metres, and liquid is litres.", pic(art, "Money"))]
    rg = [unit_for("rupees", "remediation_guided", 0, 1), unit_for("metres", "remediation_guided", 1, 1)]
    rc = [unit_for("litres", "remediation_check", 0, 2), pay("remediation_check", 1, 2), unit_for("rupees", "remediation_check", 2, 2)]
    return dict(intro=intro, demo=demo, guided=g, practice=pr, check=ck, remx=remx, remg=rg, remc=rc)


# ------------------------------------------------------------- assembly
def assemble(ctx, meta, parts, review_items, notes):
    L = ctx.lid
    guided = [mkq(ctx, "guided", i + 1, s, kp_for(ctx, "guided", i)) for i, s in enumerate(parts["guided"])]
    practice = [mkq(ctx, "practice", i + 1, s, kp_for(ctx, "practice", i)) for i, s in enumerate(parts["practice"])]
    check = [mkq(ctx, "check", i + 1, s, kp_for(ctx, "check", i)) for i, s in enumerate(parts["check"])]
    rg = [mkq(ctx, "remediation_guided", i + 1, s, kp_for(ctx, "remediation_guided", i)) for i, s in enumerate(parts["remg"])]
    rc = [mkq(ctx, "remediation_check", i + 1, s, kp_for(ctx, "remediation_check", i)) for i, s in enumerate(parts["remc"])]
    d = {"lesson_id": L, "world": "numbers", "level": meta["level"], "locale": "en-IN", "title": meta["title"],
         "objective": meta["objective"], "mastery": dict(MASTERY), "prerequisites": meta["prereq"],
         "introduce": parts["intro"], "demonstrate": parts["demo"], "guided": guided, "practice": practice, "check": check,
         "remediation": {"explain": parts["remx"], "guided": rg, "check": rc},
         "review": {"native_review_needed": False, "items_to_review": review_items,
                    "assets_missing": [], "notes": notes}}
    return d


COMMON_REVIEW = [
    "Educator review of the concrete -> pictorial -> symbolic progression, strategies taught, item difficulty and pass marks (all UNVERIFIED).",
    "en-IN TTS reading of number words and the words 'plus', 'minus', 'times', 'divided by', 'equals' (not heard).",
    "Emoji rendering of the object groups on the target device and the new schema fields (revealCount, countAll, result, showResult, showHops) are not implemented/verified in any UI.",
]
COMMON_NOTES = [
    "All answers and distractors are computed by code in tool/gen_teaching_numbers.py; every distractor is wrong; the key position is rotated and options are stored in mixed order (UI should still shuffle).",
    "Check and remediation-check items carry no hints, objects visuals set showResult false and number lines set showHops false so the answer is not drawn.",
    "After a failed check: remediation (different explanation, 2 guided, 3 alternate check items) at most max_remediation_cycles times, then offer_parent_support.",
    "Every problem instance (numbers/shape/word) is used once in the lesson, and never equals the lesson's own worked example.",
]


def main():
    src56 = json.load(open(SRC56, encoding="utf-8"))["lessons"]
    out = []
    idx = 0

    def add(meta, ctx, parts, extra_review=(), extra_notes=()):
        out.append(assemble(ctx, meta, parts, list(extra_review) + COMMON_REVIEW, list(extra_notes) + COMMON_NOTES))

    # --- numbers-count-000..010
    for n in range(11):
        lid = "numbers-count-%03d" % n
        ctx = Ctx(lid, idx)
        idx += 1
        meta = {"level": 1, "title": "Number %d" % n, "objective": "Count objects: %d" % n,
                "prereq": [] if n == 0 else ["numbers-count-%03d" % (n - 1)]}
        parts = build_count(ctx, n, 10, None)
        rv = ["Objective text is taken from the pack record numbers-count-%03d ('Count objects: %d'); the Dart lesson itself carries only the default 'Complete the guided lesson sequence.'." % (n, n),
              "The existing lesson also has a tracing step ('Trace the number %d') which this plan does not replace; writing is not a teaching-plan visual type." % n]
        nt = ["Scope: number %d only, with its neighbours inside 0-10. Plan covers recognise, count and compare; tracing stays in the existing write step." % n]
        if n == 0:
            rv.append("Zero cannot be shown by an objects group with count 0 (rendering unknown), so zero uses short stories with visual none. A better visual: an empty box or plate picture (missing asset).")
        add(meta, ctx, parts, rv, nt)
    # --- legacy lessons in curriculum order, but numbers-56 follow
    legacy = {}
    # numbers-56
    for les in src56:
        lid = les["id"]
        ctx = Ctx(lid, idx)
        idx += 1
        sk = les["skill"]
        title = les["title"]
        meta = {"level": les["level"], "title": title, "objective": les["objective"], "prereq": list(les.get("prerequisites", []))}
        rv, nt = [], ["Source skill: %s (content/age56/numbers_age_5_6.json). The existing lesson has one teach step and one practice question; this plan replaces that with a full teaching sequence." % sk]
        if sk == "identify_tens":
            N = int(title.split(":")[0])
            parts = build_tens(ctx, N)
            rv.append("Uses the NEW visual type baseTen {tens, ones, showTotal} (a bar per ten, a cube per one); the UI agent is adding it, not yet verified. Questions use showTotal false. The ones question is always worded: In N, how many single ones are left after the tens? and it is taught in demonstrate 2-3 first.")
        elif sk == "add_within_20":
            m = re.match(r"Add (\d+) \+ (\d+)", title)
            parts = build_add(ctx, int(m.group(1)), int(m.group(2)))
            rv.append("Commutativity (start from the bigger number) is used in remediation only for make-ten lessons; educator to confirm.")
        elif sk == "subtract_within_20":
            m = re.match(r"Subtract (\d+) \u2212 (\d+)", title)
            parts = build_sub(ctx, int(m.group(1)), int(m.group(2)), 20)
            rv.append("Subtraction objects visuals use operator '-' with ONE group and takeAway (the last takeAway objects crossed out), and a NEGATIVE jump on numberLine (hops go left). Agreed with the coordinator, not yet implemented/verified in a UI.")
        elif sk == "compare_two_digit_numbers":
            m = re.match(r"Compare (\d+) and (\d+)", title)
            parts = build_compare(ctx, int(m.group(1)), int(m.group(2)))
            rv.append("Place-value blocks use one group of 10 per ten (up to 8 groups). Number-line demonstration for ranges such as 70-80 uses from/to in tens.")
        elif sk == "continue_number_pattern":
            seq = [int(x) for x in re.findall(r"\d+", title)]
            parts = build_pattern(ctx, seq)
            rv.append("Number patterns are shown as text glyphs, objects groups for skip counting, or a number line; a better visual would be a pattern strip with a blank box (missing). Decreasing patterns use a negative numberLine jump (not in SCHEMA.md).")
        elif sk == "identify_shape_properties":
            parts = build_shape(ctx, title.split(":")[1].strip())
            rv.append("Introduce step 2 names all four shapes and states their sides (3 / 4 equal / 4 with 2 long and 2 short / none); demonstrate 4 and 5 teach equal sides and long sides with the square and rectangle pictures before any item asks for them. The earlier everyday-example step was removed to make room.")
            rv.append("Shape pictures are flat colour shapes (assets/images/age56/*.webp); a square and a rectangle are treated as different shapes, as in the source lesson.")
        elif sk == "understand_everyday_math":
            if title == "morning":
                parts = build_morning(ctx)
                rv.append("Scope: the source lesson only says breakfast is in the morning. The plan adds the four parts of the day (morning, afternoon, evening, night) so the concept can be tested; educator to confirm this stays within the lesson. No clock is shown.")
            elif title == "longer":
                parts = build_longer(ctx)
                rv.append("Length comparison with units uses two object groups joined by operator 'vs' with labels (the names of the two things); the UI must draw two labelled rows lined up at one start. Unverified.")
            else:
                parts = build_rupees(ctx)
                rv.append("Scope: the source lesson only says money is in rupees. The plan adds metres and litres as the contrasting units from its own options and the idea that we pay with coins and notes; no amounts or coin values are used.")
        else:
            print("UNCOVERED skill", sk)
            continue
        add(meta, ctx, parts, rv, nt)
    # --- legacy
    leg = [
        ("num-count", 1, "Count the Stars", "Count a group of three objects.", []),
        ("num-names", 1, "Number Names", "Match the number 5 to its English name.", ["num-count"]),
        ("num-subtract", 2, "Moon Subtraction", "Subtract within ten without negative results.", ["num-add"]),
        ("num-multiply", 3, "Array Multiplication", "Model multiplication as equal groups.", ["num-subtract"]),
        ("num-divide", 3, "Share Equally", "Interpret division as equal sharing.", ["num-multiply"]),
        ("num-fraction", 4, "Fractions of a Set", "Calculate a unit fraction of a whole-number set.", ["num-divide"]),
        ("num-percent", 4, "Percent Power", "Calculate a familiar percentage of a quantity.", ["num-fraction"]),
    ]
    for lid, lvl, title, obj_, pre in leg:
        ctx = Ctx(lid, idx)
        idx += 1
        meta = {"level": lvl, "title": title, "objective": obj_, "prereq": pre}
        rv, nt = [], []
        if lid == "num-count":
            parts = build_count(ctx, 3, 5, None, legacy=True)
            rv.append("Scope: the existing lesson counts three stars. Practice adds counts of 1, 2 or 4 and distractors up to 5; educator to confirm.")
        elif lid == "num-names":
            parts = build_names(ctx, 5)
            rv.append("Scope: the existing lesson matches only the number 5 to 'five'. The plan teaches all ten names (demonstrate 3 and 4: one to five, six to ten) and then uses them; the app already has the names 1-10; educator to confirm.")
        elif lid == "num-subtract":
            parts = build_sub(ctx, 7, 2, 10)
            rv.append("Subtraction objects visuals use operator '-' with ONE group and takeAway, and a NEGATIVE jump on numberLine (UI unverified).")
        elif lid == "num-multiply":
            parts = build_multiply(ctx, 4, 3)
            rv.append("Scope: equal groups with group counts and sizes from 2 to 7 (product up to 30; 7 is needed so that no problem is used twice, even in the other order). No arrays are drawn in rows and columns, only groups; a true array picture is missing.")
        elif lid == "num-divide":
            parts = build_divide(ctx, 12, 3)
            rv.append("Scope: totals up to 30 with divisors 2 to 6 and whole-number answers only. Both sharing and grouping meanings are taught.")
        elif lid == "num-fraction":
            parts = build_fraction(ctx, 10)
            rv.append("Scope: the existing lesson covers one half of 10. The plan uses halves of even numbers up to 40 so that there are enough distinct problems; educator to confirm. No other fractions (quarters, thirds) are taught.")
        else:
            parts = build_percent(ctx, 25, 20)
            rv.append("Scope: the existing lesson covers 25% of 20. The plan also covers 50% (taught as one half, from the fraction lesson) and names 100% as the whole; no other percentages. Totals up to 40.")
        add(meta, ctx, parts, rv, nt)
    plan = {"schema_version": 1, "status": "rollout_unverified", "lessons": out}
    assert os.path.normpath(os.path.dirname(OUT)).endswith("teaching_pending")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(plan, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("wrote", OUT, "lessons:", len(out))
    if "--no-promote" in sys.argv:
        print("not promoted (--no-promote); bundled copy left as it is")
        return
    promote()


def promote():
    """Copy pending -> bundled only when the checker AND the real Dart parser pass."""
    import shutil
    import subprocess
    chk = subprocess.run([sys.executable, "-X", "utf8", "-I", os.path.join(ROOT, "tool", "check_rollout_numbers.py")],
                         capture_output=True, text=True, encoding="utf-8", errors="replace")
    print(chk.stdout[-900:])
    if chk.returncode != 0:
        print("CHECKER FAILED: bundled copy NOT written")
        sys.exit(1)
    flutter = os.environ.get("FLUTTER_BAT", r"E:\flutter-sdk\bin\flutter.bat")
    t = subprocess.run([flutter, "test", "test/teaching/rollout_visuals_test.dart"], cwd=ROOT,
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    lines = [l for l in t.stdout.splitlines() if "rollout_numbers.json:" in l or "All tests passed" in l]
    print("\n".join(lines))
    ok = t.returncode == 0 and any("0 issues" in l and "rollout_numbers.json" in l for l in lines)
    if not ok:
        print("DART PARSER FAILED: bundled copy NOT written")
        sys.exit(1)
    shutil.copyfile(OUT, BUNDLED)
    print("promoted to", BUNDLED)


if __name__ == "__main__":
    main()
