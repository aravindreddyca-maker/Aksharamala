# -*- coding: utf-8 -*-
"""Rollout R3 generator: teaching plans for the Level 1-4 word / sentence / story / syllable lessons
(English, Telugu, Hindi, Tamil).  Author: content-creator.  Output is UNVERIFIED.

Run:  python -X utf8 -I tool/gen_teaching_words.py
Reads (nothing under lib/ is modified):
  content/age56/{english,telugu,hindi,tamil}_age_5_6.json   -> id, level, title, objective, prerequisites, skill, examples
  lib/src/curriculum.dart                                   -> legacy word lessons and story lessons
  lib/src/batch/age56_content.dart                          -> which picture files each age 5-6 lesson already uses
  lib/src/alphabet/alphabet_data.dart                       -> picture words known to the app
Writes ONLY:
  content/teaching_pending/rollout_words.json
  audit/ROLLOUT_R3_WORDS_SPECS.md
It never writes into content/teaching/.
"""
import itertools
import json
import os
import re
import sys
import unicodedata

ROOT = r"E:\Aksharamala"
OUT_JSON = ROOT + r"\content\teaching_pending\rollout_words.json"
OUT_MD = ROOT + r"\audit\ROLLOUT_R3_WORDS_SPECS.md"
WORLDS = ["english", "telugu", "hindi", "tamil"]
SHORT = {"english": "en", "telugu": "te", "hindi": "hi", "tamil": "ta"}
LOCALE = {"english": "en-US", "telugu": "te-IN", "hindi": "hi-IN", "tamil": "ta-IN"}
LANGNAME = {"english": "English", "telugu": "Telugu", "hindi": "Hindi", "tamil": "Tamil"}
MASTERY = {"check_total": 3, "check_pass": 2, "remediation_pass": 2, "max_remediation_cycles": 2,
           "after_limit": "offer_parent_support"}
PHASES = ["introduce", "demonstrate", "guided", "practice", "check", "remediation_explain", "remediation_guided",
          "remediation_check"]
LEGACY = {  # id -> (world, template)
    "en-word": ("english", "word"), "te-word": ("telugu", "word"), "hi-word": ("hindi", "word"),
    "ta-word": ("tamil", "word"),
    "en-story": ("english", "story"), "english-story-002": ("english", "story"),
    "te-story": ("telugu", "story"), "telugu-story-001": ("telugu", "story"),
    "hi-story": ("hindi", "story"), "hindi-story-002": ("hindi", "story"),
    "ta-story": ("tamil", "story"), "tamil-story-002": ("tamil", "story"),
}
STAGE_LEVEL = {"explorer": 1, "creator": 2, "scholar": 3, "champion": 4}


def exists(p):
    return bool(p) and os.path.isfile(os.path.join(ROOT, p.replace("/", os.sep)))


def asc(s):
    return s.encode("ascii", "backslashreplace").decode()


# ====================================================================== sources
def load_age56():
    out = {}
    for w in WORLDS:
        d = json.load(open(ROOT + r"\content\age56\%s_age_5_6.json" % w, encoding="utf-8"))
        for l in d["lessons"]:
            if l["id"].startswith(w + "-56-"):
                out[l["id"]] = dict(l, world=w)
    return out


def load_age56_media():
    """id -> {word: picture path} for pictures that exist as files (parsed from the generated Dart)."""
    t = open(ROOT + r"\lib\src\batch\age56_content.dart", encoding="utf-8").read()
    res = {}
    for m in re.finditer(r"BatchLesson\(\s*id: '([^']+)'(.*?)sourceRecords:", t, re.S):
        body = m.group(2)
        mi = re.search(r"media: LessonMedia\((.*?)\n    \),", body, re.S)
        im = {}
        if mi:
            imgs = re.search(r"images: \{(.*?)\}", mi.group(1), re.S)
            if imgs:
                im = {k: v for k, v in re.findall(r"'([^']*)':\s*'([^']*)'", imgs.group(1)) if exists(v)}
        res[m.group(1)] = im
    return res


def dart_lesson(src, lid):
    i = src.index("id: '%s'" % lid)
    j = src.find("id: '", i + 6)
    block = src[i: j if j > 0 else len(src)]

    def f(k):
        m = re.search(r"\n\s*%s:\s*'((?:[^'\\]|\\.)*)'" % k, block)
        return m.group(1) if m else None
    pr = re.search(r"prerequisites:\s*\[([^\]]*)\]", block)
    story = re.search(r"story:\s*\[(.*?)\],", block, re.S)
    opts = re.search(r"options:\s*\[(.*?)\],", block, re.S)
    pics = re.search(r"pictures:\s*\{(.*?)\},", block, re.S)
    stage = re.search(r"ExperienceStage\.(\w+)", block).group(1)
    return dict(id=lid, title=f("title"), objective=f("learningObjective"), locale=f("locale"),
                prerequisites=re.findall(r"'([^']*)'", pr.group(1)) if pr else [],
                level=STAGE_LEVEL[stage], challenge=f("challenge"), answer=f("answer"), cover=f("cover"),
                story=re.findall(r"'((?:[^'\\]|\\.)*)'", story.group(1)) if story else [],
                options=re.findall(r"'((?:[^'\\]|\\.)*)'", opts.group(1)) if opts else [],
                pictures=dict(re.findall(r"'([^']*)':\s*'([^']*)'", pics.group(1))) if pics else {},
                symbol=f("symbol"), speech=f("speech"))


def begins_exact(word, letter):
    """The word starts with exactly this letter / syllable (not followed by a combining sign, virama or anusvara)."""
    if not word or not word.startswith(letter):
        return False
    return not (len(word) > len(letter) and unicodedata.category(word[len(letter)]) in ("Mn", "Mc"))


# ====================================================================== builder
V_NONE = {"type": "none"}


def V_G(g):
    return {"type": "glyph", "glyph": g}


def V_P(asset, cap=""):
    assert exists(asset), asset
    return {"type": "picture", "asset": asset, "caption": cap}


def V_LW(g, word, asset):
    assert exists(asset), asset
    return {"type": "letterWord", "glyph": g, "word": word, "asset": asset}


class Lesson:
    """Collects the steps and questions of one lesson; enforces unique (answer, option set) keys."""

    def __init__(self, meta, S, template):
        self.meta, self.S, self.template = meta, S, template
        self.lid = meta["lesson_id"]
        self.ph = {k: [] for k in PHASES}
        self.keys = {}
        self.use = {}
        self.qn = 0
        self.seed = sum(ord(c) for c in self.lid) % 3
        self.notes = []
        self.review = []
        self.assets_missing = []

    # ---- text
    def t(self, key, **kw):
        s = self.S[key]
        try:
            r = s.format(**kw)
        except KeyError as e:
            raise KeyError("%s: key %s missing %s" % (self.lid, key, e))
        return r

    # ---- steps
    def step(self, phase, text, visual, speech=None):
        n = len(self.ph[phase]) + 1
        self.ph[phase].append({"id": "%s.%s.%d" % (self.lid, phase, n), "text": text, "speech": speech or text,
                               "visual": visual})

    # ---- options
    def pos(self, n):
        return (self.qn + self.seed) % n

    def opts(self, answer, pool, n=2, fixed=None):
        """answer + n distractors from pool, avoiding any (answer, option set) already used in this lesson."""
        pool = [x for x in dict.fromkeys(pool) if x != answer]
        best = None
        for combo in itertools.combinations(pool, n):
            if (answer, frozenset(combo + (answer,))) in self.keys:
                continue
            score = sum(self.use.get(x, 0) for x in combo)
            if best is None or score < best[0]:
                best = (score, combo)
        if best is None:
            raise RuntimeError("%s: no unused option set for %r (pool %d)" % (self.lid, asc(answer), len(pool)))
        for x in best[1]:
            self.use[x] = self.use.get(x, 0) + 1
        o = list(best[1])
        p = self.pos(n + 1) if fixed is None else fixed
        o.insert(p, answer)
        return o

    # ---- questions
    def q(self, phase, task, prompt, options, answer, visual, hints, fb, expl, diff, speech=None, optpics=None,
          raw_fb=None):
        assert answer in options, (self.lid, asc(answer), options)
        assert len(set(options)) == len(options)
        key = (answer, frozenset(options))
        assert key not in self.keys, "%s: repeated item %s (%s) vs %s" % (self.lid, task, asc(answer), self.keys.get(key))
        n = len(self.ph[phase]) + 1
        qid = "%s.%s.%d" % (self.lid, phase, n)
        self.keys[key] = qid
        wf = {}
        for o in options:
            if o != answer:
                wf[o] = raw_fb[o] if raw_fb else self.t(fb, O=o)
        d = {"id": qid, "task": task, "prompt": prompt, "speech": speech or prompt, "options": list(options),
             "answer": answer, "visual": visual, "hints": hints, "wrong_feedback": wf, "explanation": expl,
             "difficulty": diff}
        if optpics:
            d["optionPictures"] = {o: p for o, p in optpics.items() if o in options}
        self.ph[phase].append(d)
        self.qn += 1

    def result(self):
        m = self.meta
        les = {"lesson_id": m["lesson_id"], "world": m["world"], "level": m["level"], "locale": m["locale"],
               "title": m["title"], "objective": m["objective"], "prerequisites": m["prerequisites"],
               "variant": self.template, "mastery": dict(MASTERY),
               "introduce": self.ph["introduce"], "demonstrate": self.ph["demonstrate"],
               "guided": self.ph["guided"], "practice": self.ph["practice"], "check": self.ph["check"],
               "remediation": {"explain": self.ph["remediation_explain"], "guided": self.ph["remediation_guided"],
                               "check": self.ph["remediation_check"]},
               "review": {"native_review_needed": True, "items_to_review": self.review,
                          "assets_missing": self.assets_missing, "notes": self.notes}}
        return les


def nudge_pair(L, k1, k2):
    return [L.t(k1), L.t(k2)]


# ====================================================================== language strings
# Keys shared by every template are generic; the English table also carries the English-only skills.
STR = {}
STR["en"] = {
    # ---- generic hints (hint 1 of a guided item and both practice hints never contain an answer)
    "h_look": "Look carefully at each choice.",
    "h_listen": "Listen again, then look at each choice.",
    "h_first": "Listen to the first sound of the word.",
    "h_pic": "Look at the picture and say its name slowly.",
    "h_read": "Read each choice slowly, one at a time.",
    "h_sentence": "Read the sentence again, one word at a time.",
    "h_count": "Point to each word and count them one by one.",
    "h_blank": "Read the sentence again. Which word is hidden?",
    "h_story": "Think about the story. What happened first, next and last?",
    "h_end": "Listen to the end of the word.",
    "h_say": "Say the sounds slowly and blend them.",
    "h_stick": "Find the stick. Is it on the left or on the right?",
    "h_round": "Find the stick and the round part. Which way does the stick go?",
    "h_flip": "Imagine turning the letter over like a page.",
    "h_letters": "Say the letters one at a time.",
    "h_miss": "Say the word slowly. Which sound is missing?",
    "hr_ans": "The answer is {A}.",
    "hr_sent": "The sentence says: {T}",
    "hr_story": "Look at this sentence: {S}",
    # ---- generic wrong-answer feedback (always about the wrong choice, never the answer)
    "fb_try": "Good try! Look again and try another one.",
    "fb_letter": "That is a different letter. Look closely.",
    "fb_word": "That is a different word. Look again.",
    "fb_pic": "That is a different picture. Look again.",
    "fb_heard": "That is not what you heard. Listen again.",
    "fb_sent": "That is a different sentence. Listen again.",
    "fb_end": "That word has a different ending. Listen to the end of the word.",
    "fb_count": "Count again, one word at a time.",
    "fb_story": "That is not what the story says. Think about the story again.",
    "fb_fit": "That word does not fit the gap. Read the sentence again.",
    "fb_spell": "That is not spelled like the word you learned. Look at the letters.",
    "fb_shape": "That letter has a different shape. Look at the stick and the round part.",
    # ---- explanations
    "ex_ans": "The answer is {A}.",
    "ex_sent": "You heard: {A}",
    "ex_first": "The first word is {A}.",
    "ex_last": "The last word is {A}.",
    "ex_count": "The sentence has {A} words.",
    "ex_fill": "The missing word is {A}.",
    "ex_notin": "{A} is not in the sentence.",
    "ex_story": "The story says: {A}",
    "ex_namepic": "This picture is {A}.",
    "ex_heard": "You heard {A}.",
    # ---- sentences
    "se_i1": "Today we read a sentence. Listen and read along.",
    "se_i2": "{T}",
    "se_d1": "Read it one word at a time: {WORDS}.",
    "se_d2": "The first word is {F}. The last word is {Z}.",
    "se_d3": "This sentence has {N} words.",
    "se_d4": "When a question asks about the sentence, read the sentence again and look for the answer.",
    "se_d5": "Fill the gap: {BL} The missing word is {X}.",
    "se_r1": "Cover one word: {BL} Read the sentence again and think which word fits the gap.",
    "se_r2": "Read it in two parts: {P1} | {P2}",
    "se_r3": "Listen once more: {T}",
    "q_hears": "Listen. Which sentence did you hear?",
    "q_first": "What is the first word of the sentence?",
    "q_last": "What is the last word of the sentence?",
    "q_count": "How many words are in the sentence?",
    "q_fill": "Which word fits the gap?",
    "q_notin": "Which word is NOT in the sentence?",
    # ---- stories
    "st_i1": "Today we read a story: {TITLE}.",
    "st_i2": "Listen to each sentence and read along.",
    "st_d1": "First: {S}",
    "st_d2": "Then: {S}",
    "st_d3": "At the end: {S}",
    "st_d4": "Let us retell the story. {S1} {S2} {S3}",
    "st_d5": "A question: {Q} Look back at the story: {S} The answer is {A}.",
    "st_r1": "Close your eyes and remember the story. First: {S}",
    "st_r2": "Next: {S}",
    "st_r3": "And last: {S}",
    "q_sfirst": "What happened first in the story?",
    "q_snext": "What happened right after this? {S}",
    "q_slast": "What happened last in the story?",
    "q_shear": "Listen. Which sentence did you hear?",
    "q_snot": "Which sentence is NOT in this story?",
    # ---- words with pictures / missing letters (en-word)
    "w_i1": "Today we build words. A picture helps us find the missing letter.",
    "w_i2": "{W}: {S1} + {S2} + {S3}.",
    "w_d1": "Look at the picture. It is {W}.",
    "w_dm": "Hide one letter: {BL} Say the sounds. The missing letter is {X}.",
    "w_d1m": "Another word: {W}. {BL} The missing letter is {X}.",
    "w_d5": "A puzzle: which word is NOT the name of this picture? This is {W}. {X} is a different word.",
    "w_r1": "Say the word slowly and listen to each sound: {W}.",
    "w_r2": "Now hide the last sound: {BL} Which sound is missing? It is {X}.",
    "w_r3": "Put the letters back together: {S1} + {S2} + {S3} = {W}.",
    "q_wmiss": "Which letter is missing?",
    "q_wpic": "What is this picture?",
    "q_whear": "Listen. Which picture is it?",
    "q_wnot": "Which word is NOT the name of this picture?",
    "ex_wmiss": "The missing letter is {A}.",
    # ---- word families (blend_cvc)
    "cv_i1": "Today we read words that end in -{F}.",
    "cv_i2": "{S1} + {S2} + {S3} = {W1}. Listen: {W1}.",
    "cv_d1": "Say the sounds slowly: {S1} ... {S2} ... {S3}.",
    "cv_d2": "Now blend the sounds together: {W1}.",
    "cv_d3": "Change the first sound: {C} + {R1} + {R2} = {W2}. The ending stays the same: -{F}.",
    "cv_d4": "Again: {C3} + {R1} + {R2} = {W3}, and {C4} + {R1} + {R2} = {W4}. These words all end in -{F}: they are the -{F} family.",
    "cv_d5": "A puzzle: which word does NOT end in -{F}? {W2} does end in -{F}. {X} does not. {X} is the odd one out.",
    "cv_r1": "Listen to the end of each word: {W1}, {W2}, {W3}, {W4}. They sound the same at the end.",
    "cv_r2": "Now listen to {W1} and {O}. They do not end the same. {W1} ends in -{F}. {O} ends in -{F2}.",
    "cv_r3": "Remember: a word in the -{F} family ends in -{F}. Say {W1} again and listen to the end.",
    "q_blend": "Listen to the sounds. Which word do they make?",
    "q_fam": "Which word belongs to the -{F} family?",
    "q_notfam": "Which word does NOT belong to the -{F} family?",
    "q_cheard": "Listen. Which word did you hear?",
    "q_cfirst": "Listen to the word. Which letter does it begin with?",
    "q_cend": "Listen to the word. Which ending does it have?",
    "ex_blend": "{S1} + {S2} + {S3} = {A}",
    "ex_fam": "{A} ends in -{F}.",
    "ex_notfam": "{A} does not end in -{F}.",
    "ex_cfirst": "{W} begins with {A}.",
    "ex_cend": "{W} ends in {A}.",
    # ---- sight words
    "sw_i1": "Today we learn a word that we see all the time.",
    "sw_i2": "This word is {W}. Look, say, cover, and read it again.",
    "sw_d1": "Look at the word. It is {W}.",
    "sw_d2": "Say it letter by letter: {LET}. Then say the whole word: {W}.",
    "sw_d3": "Cover the word and picture it in your mind. It has {N} letters.",
    "sw_d4": "Uncover it and read it again: {W}.",
    "sw_d5": "Be careful: {X} is not the word {W}. Some of its letters are different.",
    "sw_r1": "Clap once for each letter of the word. How many claps? {N}.",
    "sw_r2": "Say the word, then say its first letter: {F}.",
    "sw_r3": "Read it again: {W}.",
    "q_spick": "Listen. Which spelling is the word you heard?",
    "q_look": "Find the word that looks just like this one.",
    "q_smiss": "Which letter is missing?",
    "q_sfirstl": "Listen to the word. Which letter does it begin with?",
    "q_scount": "How many letters are in this word?",
    "q_sread": "Listen. Which word did you hear?",
    "q_swrong": "Which one is spelled wrongly?",
    "ex_spell": "The word is {A}.",
    "ex_smiss": "The missing letter is {A}.",
    "ex_scount": "The word has {A} letters.",
    "ex_swrong": "{A} is not spelled like the word you learned.",
    # ---- letter shapes (b d p q)
    "sh_i1": "Look closely at the small letter {L}. It has a stick and a round part.",
    "sh_i2": "In {L}, the stick is on the {SIDE} and it goes {DIR}. The round part is on the {OSIDE}.",
    "sh_d1": "Say the letter: {L}.",
    "sh_d1w": "{L} is for {W}.",
    "sh_d2": "Here is {P1}. It looks a little like {L}, but its stick is on the {S1}. It is a different letter.",
    "sh_d3": "Here is {P2}. Its stick goes {D2}. That is different too.",
    "sh_d4": "Put them side by side. If you flip {L} from left to right, you get {P1}. If you flip it upside down, you get {P2}.",
    "sh_d5": "A puzzle: which letter is NOT {L}? {P1} is not {L}. Only {L} has its stick on the {SIDE} going {DIR}.",
    "sh_r1": "Find the stick of {L}. It is on the {SIDE}.",
    "sh_r2": "Now find the round part. It is on the {OSIDE}.",
    "sh_r3": "Say it once more: {L}. The stick is on the {SIDE} and goes {DIR}.",
    "q_hearl": "Listen. Which letter is it?",
    "q_clue": "Which letter has its stick on the {SIDE} going {DIR}?",
    "q_mirror": "Flip this letter from left to right. Which letter do you get?",
    "q_flip": "Flip this letter upside down. Which letter do you get?",
    "q_pw": "Which letter does this word begin with?",
    "q_samel": "Find the letter that looks just like this one.",
    "q_notl": "Which letter is NOT {L}?",
    "ex_hearl": "This letter is {A}.",
    "ex_clue": "{A} has its stick on the {SIDE} going {DIR}.",
    "ex_mirror": "Flipped left to right it becomes {A}.",
    "ex_flip": "Flipped upside down it becomes {A}.",
    "ex_pw": "{W} begins with {A}.",
    "ex_notl": "{A} is a different letter.",
}
STR["te"] = {
    "h_look": "ప్రతి ఎంపికను జాగ్రత్తగా చూడండి.",
    "h_listen": "మళ్లీ వినండి, తర్వాత ప్రతి ఎంపికను చూడండి.",
    "h_first": "పదం మొదటి శబ్దాన్ని వినండి.",
    "h_pic": "బొమ్మను చూసి దాని పేరు నెమ్మదిగా చెప్పండి.",
    "h_read": "ప్రతి ఎంపికను నెమ్మదిగా చదవండి.",
    "h_sentence": "వాక్యాన్ని మళ్లీ చదవండి, ఒక్కో పదంగా.",
    "h_count": "ప్రతి పదాన్ని చూపిస్తూ ఒక్కొక్కటిగా లెక్కించండి.",
    "h_blank": "వాక్యాన్ని మళ్లీ చదవండి. ఏ పదం దాగి ఉంది?",
    "h_story": "కథ గురించి ఆలోచించండి. మొదట, తర్వాత, చివరగా ఏమి జరిగింది?",
    "h_parts": "మొదట పెద్ద అక్షరాన్ని, తర్వాత చిన్న గుర్తును చూడండి.",
    "h_sign": "అక్షరం పక్కన ఉన్న చిన్న గుర్తును చూడండి.",
    "h_sound": "శబ్దాన్ని నెమ్మదిగా చెప్పండి. ఇది ఏ అక్షరం?",
    "hr_ans": "జవాబు {A}.",
    "hr_sent": "వాక్యం ఇలా ఉంది: {T}",
    "hr_story": "ఈ వాక్యాన్ని చూడండి: {S}",
    "hr_syl": "{B} + {S} = {L}.",
    "fb_try": "మంచి ప్రయత్నం! మళ్లీ చూసి మరొకటి ప్రయత్నించండి.",
    "fb_letter": "అది వేరే అక్షరం. జాగ్రత్తగా చూడండి.",
    "fb_word": "అది వేరే పదం. మళ్లీ చూడండి.",
    "fb_pic": "అది వేరే బొమ్మ. మళ్లీ చూడండి.",
    "fb_heard": "అది మీరు విన్నది కాదు. మళ్లీ వినండి.",
    "fb_sent": "అది వేరే వాక్యం. మళ్లీ వినండి.",
    "fb_count": "పదాలను ఒక్కొక్కటిగా మళ్లీ లెక్కించండి.",
    "fb_story": "కథలో అలా లేదు. కథను మళ్లీ గుర్తు చేసుకోండి.",
    "fb_fit": "ఆ పదం ఖాళీకి సరిపోదు. వాక్యాన్ని మళ్లీ చదవండి.",
    "fb_parts": "ఆ రెండు భాగాలు కావు. అక్షరాన్ని మళ్లీ చూడండి.",
    "fb_sign": "అది వేరే గుర్తు. మళ్లీ ప్రయత్నించండి.",
    "ex_ans": "జవాబు {A}.",
    "ex_sent": "మీరు విన్నది: {A}",
    "ex_first": "మొదటి పదం {A}.",
    "ex_last": "చివరి పదం {A}.",
    "ex_count": "ఈ వాక్యంలో {A} పదాలు ఉన్నాయి.",
    "ex_fill": "రావలసిన పదం {A}.",
    "ex_notin": "{A} ఈ వాక్యంలో లేదు.",
    "ex_story": "కథలో ఇలా ఉంది: {A}",
    "ex_namepic": "ఇది {A}.",
    "ex_heard": "మీరు {A} విన్నారు.",
    "ex_combine": "{B} + {S} = {A}.",
    "ex_decomp": "ఈ రెండు భాగాలను కలిపితే ఈ అక్షరం వస్తుంది.",
    "ex_sign": "{S} గుర్తు కావాలి.",
    "ex_wbegin": "{W} పదం {L} తో మొదలవుతుంది.",
    "ex_not": "{A} లో {S} గుర్తు లేదు.",
    "ex_wfirst": "{W} పదం {A} తో మొదలవుతుంది.",
    "se_i1": "ఒక వాక్యాన్ని చదువుదాం. వినండి, కలిసి చదవండి.",
    "se_i2": "{T}",
    "se_d1": "ఒక్కో పదంగా చదవండి: {WORDS}.",
    "se_d2": "మొదటి పదం {F}. చివరి పదం {Z}.",
    "se_d3": "ఈ వాక్యంలో {N} పదాలు ఉన్నాయి.",
    "se_d4": "వాక్యం గురించి ప్రశ్న అడిగితే, వాక్యాన్ని మళ్లీ చదివి జవాబును వెతకండి.",
    "se_d5": "ఖాళీని నింపుదాం: {BL} ఇక్కడ రావలసిన పదం {X}.",
    "se_r1": "ఒక పదాన్ని కప్పేయండి: {BL} వాక్యాన్ని మళ్లీ చదివి ఖాళీకి ఏ పదం సరిపోతుందో ఆలోచించండి.",
    "se_r2": "వాక్యాన్ని రెండు భాగాలుగా చదవండి: {P1} | {P2}",
    "se_r3": "ఇంకోసారి వినండి: {T}",
    "q_hears": "వినండి. మీరు ఏ వాక్యం విన్నారు?",
    "q_first": "వాక్యంలో మొదటి పదం ఏది?",
    "q_last": "వాక్యంలో చివరి పదం ఏది?",
    "q_count": "వాక్యంలో ఎన్ని పదాలు ఉన్నాయి?",
    "q_fill": "ఖాళీకి ఏ పదం సరిపోతుంది?",
    "q_notin": "ఈ వాక్యంలో లేని పదం ఏది?",
    "st_i1": "ఈరోజు ఒక కథ చదువుదాం: {TITLE}.",
    "st_i2": "ప్రతి వాక్యాన్ని వినండి, కలిసి చదవండి.",
    "st_d1": "మొదట: {S}",
    "st_d2": "తర్వాత: {S}",
    "st_d3": "చివరగా: {S}",
    "st_d4": "కథను మళ్లీ చెప్పుకుందాం. {S1} {S2} {S3}",
    "st_d5": "ప్రశ్న: {Q} కథను మళ్లీ చూడండి: {S} జవాబు {A}.",
    "st_r1": "కళ్లు మూసుకొని కథను గుర్తు చేసుకోండి. మొదట: {S}",
    "st_r2": "తర్వాత: {S}",
    "st_r3": "చివరగా: {S}",
    "q_sfirst": "కథలో మొదట ఏమి జరిగింది?",
    "q_snext": "దీని తర్వాత ఏమి జరిగింది? {S}",
    "q_slast": "కథలో చివరగా ఏమి జరిగింది?",
    "q_shear": "వినండి. మీరు ఏ వాక్యం విన్నారు?",
    "q_snot": "ఈ కథలో లేని వాక్యం ఏది?",
    "w_i1": "ఈరోజు బొమ్మను చూసి సరైన పదాన్ని ఎంచుకుంటాం.",
    "w_i2": "{W}. బొమ్మను చూడండి.",
    "w_d1": "ఇది {W}. {W} అనే పదాన్ని చదవండి.",
    "w_d4": "ప్రతి పదం ఒక అక్షరంతో మొదలవుతుంది. {W1} {L1} తో, {W2} {L2} తో, {W3} {L3} తో మొదలవుతుంది.",
    "w_d5": "పజిల్: ఈ బొమ్మ పేరు కాని పదం ఏది? ఇది {W}. {X} ఈ బొమ్మ పేరు కాదు, కాబట్టి {X} వేరుగా ఉంది.",
    "w_r1": "{W} అని నెమ్మదిగా చెప్పండి. మొదటి శబ్దాన్ని వినండి.",
    "w_r2": "ఇప్పుడు బొమ్మను చూసి పేరు చెప్పండి, తర్వాత మొదటి అక్షరం ఏదో చూడండి: {L}.",
    "w_r3": "{W} పదం {L} తో మొదలవుతుంది. బొమ్మను, పదాన్ని కలిపి గుర్తుంచుకోండి.",
    "q_wpic": "ఈ బొమ్మ ఏమిటి?",
    "q_whear": "వినండి. ఏ బొమ్మ?",
    "q_wnot": "ఈ బొమ్మ పేరు కాని పదం ఏది?",
    "q_wfirst": "పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది?",
    "syl_i1": "ఈరోజు {B} కు {S} గుర్తు కలుపుతాం.",
    "syl_i2": "{B} + {S} = {L}. వినండి: {L}.",
    "syl_d1": "ఇది {B} అక్షరం. దీనికి ఈ {S} గుర్తు కలుపుతాం.",
    "syl_d2": "{B} కు {S} గుర్తు కలిపితే {L} అవుతుంది.",
    "syl_d3b": "{W} అనే పదాన్ని వినండి. {W} {L} తో మొదలవుతుంది.",
    "syl_d3c": "{W} అనే పదాన్ని వినండి. ఇందులో {L} అక్షరం ఉంది.",
    "syl_d4": "గుర్తు మారితే అక్షరం మారుతుంది. {B} కు {S2} గుర్తు కలిపితే {L2} అవుతుంది.",
    "syl_d5": "పజిల్: {S} గుర్తు లేని అక్షరం ఏది? {L} లో {S} గుర్తు ఉంది. {L2} లో లేదు. కాబట్టి {L2} వేరుగా ఉంది.",
    "syl_r1": "{B} అని చెప్పండి. ఇది గుర్తు లేని అక్షరం.",
    "syl_r2": "ఇప్పుడు {S} గుర్తును చూడండి. ఇది {B} పక్కన చేరి శబ్దాన్ని మారుస్తుంది.",
    "syl_r3": "రెండింటినీ కలిపి చదవండి: {L}.",
    "q_combine": "{B} + {S} = ?",
    "sp_combine": "{B} కు {S} గుర్తు కలిపితే ఏ అక్షరం వస్తుంది?",
    "q_hear": "వినండి. మీరు ఏ అక్షరం విన్నారు?",
    "q_decomp": "ఈ అక్షరం ఏ రెండు భాగాలతో తయారైంది?",
    "q_sign": "{B} + ? = {L}. ఏ గుర్తు కావాలి?",
    "q_wbegin": "పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది?",
    "q_namepic": "ఈ బొమ్మ ఏమిటి?",
    "q_match": "ఇలాంటి అక్షరాన్ని కనుగొనండి.",
    "q_not": "{S} గుర్తు లేని అక్షరం ఏది?",
}
STR["hi"] = {
    "h_look": "हर विकल्प को ध्यान से देखो।",
    "h_listen": "फिर से सुनो, फिर हर विकल्प को देखो।",
    "h_first": "शब्द की पहली आवाज़ सुनो।",
    "h_pic": "चित्र को देखो और उसका नाम धीरे-धीरे बोलो।",
    "h_read": "हर विकल्प को धीरे-धीरे पढ़ो।",
    "h_sentence": "वाक्य को फिर से पढ़ो, एक-एक शब्द करके।",
    "h_count": "हर शब्द पर उँगली रखकर एक-एक करके गिनो।",
    "h_blank": "वाक्य को फिर से पढ़ो। कौन सा शब्द छिपा है?",
    "h_story": "कहानी के बारे में सोचो। पहले, फिर और आख़िर में क्या हुआ?",
    "h_parts": "पहले बड़े अक्षर को देखो, फिर छोटी मात्रा को।",
    "h_sign": "अक्षर के साथ लगी छोटी मात्रा को देखो।",
    "h_sound": "आवाज़ को धीरे-धीरे बोलो। यह कौन सा अक्षर है?",
    "h_miss": "शब्द को धीरे-धीरे बोलो। कौन सी आवाज़ छूट गई है?",
    "hr_ans": "उत्तर है {A}।",
    "hr_sent": "वाक्य यह है: {T}",
    "hr_story": "यह वाक्य देखो: {S}",
    "hr_syl": "{B} + {S} = {L}।",
    "fb_try": "अच्छी कोशिश! फिर से देखो और दूसरा चुनो।",
    "fb_letter": "वह दूसरा अक्षर है। ध्यान से देखो।",
    "fb_word": "वह दूसरा शब्द है। फिर से देखो।",
    "fb_pic": "वह दूसरा चित्र है। फिर से देखो।",
    "fb_heard": "यह वह नहीं है जो तुमने सुना। फिर से सुनो।",
    "fb_sent": "वह दूसरा वाक्य है। फिर से सुनो।",
    "fb_count": "शब्दों को एक-एक करके फिर से गिनो।",
    "fb_story": "कहानी में ऐसा नहीं है। कहानी को फिर से याद करो।",
    "fb_fit": "वह शब्द खाली जगह में ठीक नहीं बैठता। वाक्य फिर से पढ़ो।",
    "fb_parts": "वे दो भाग नहीं हैं। अक्षर को फिर से देखो।",
    "fb_sign": "वह दूसरी मात्रा है। फिर से कोशिश करो।",
    "ex_ans": "उत्तर है {A}।",
    "ex_sent": "तुमने यह सुना: {A}",
    "ex_first": "पहला शब्द {A} है।",
    "ex_last": "आख़िरी शब्द {A} है।",
    "ex_count": "इस वाक्य में {A} शब्द हैं।",
    "ex_fill": "यहाँ {A} आएगा।",
    "ex_notin": "{A} इस वाक्य में नहीं है।",
    "ex_story": "कहानी में लिखा है: {A}",
    "ex_namepic": "यह {A} है।",
    "ex_heard": "तुमने {A} सुना।",
    "ex_combine": "{B} + {S} = {A}।",
    "ex_decomp": "इन दो भागों को जोड़ने से यह अक्षर बनता है।",
    "ex_sign": "{S} की मात्रा चाहिए।",
    "ex_wbegin": "{W} शब्द {L} से शुरू होता है।",
    "ex_not": "{A} में {S} की मात्रा नहीं है।",
    "ex_wfirst": "{W} शब्द {A} से शुरू होता है।",
    "ex_wmiss": "छूटा हुआ अक्षर {A} है।",
    "se_i1": "आओ एक वाक्य पढ़ें। सुनो और साथ में पढ़ो।",
    "se_i2": "{T}",
    "se_d1": "एक-एक शब्द करके पढ़ो: {WORDS}।",
    "se_d2": "पहला शब्द {F} है। आख़िरी शब्द {Z} है।",
    "se_d3": "इस वाक्य में {N} शब्द हैं।",
    "se_d4": "जब वाक्य के बारे में सवाल पूछा जाए, तो वाक्य को फिर से पढ़ो और उत्तर ढूँढो।",
    "se_d5": "खाली जगह भरें: {BL} यहाँ {X} आएगा।",
    "se_r1": "एक शब्द को ढक दो: {BL} वाक्य फिर से पढ़ो और सोचो कि खाली जगह में कौन सा शब्द बैठेगा।",
    "se_r2": "वाक्य को दो हिस्सों में पढ़ो: {P1} | {P2}",
    "se_r3": "एक बार और सुनो: {T}",
    "q_hears": "सुनो। तुमने कौन सा वाक्य सुना?",
    "q_first": "वाक्य का पहला शब्द कौन सा है?",
    "q_last": "वाक्य का आख़िरी शब्द कौन सा है?",
    "q_count": "वाक्य में कितने शब्द हैं?",
    "q_fill": "खाली जगह में कौन सा शब्द आएगा?",
    "q_notin": "इस वाक्य में कौन सा शब्द नहीं है?",
    "st_i1": "आज हम एक कहानी पढ़ेंगे: {TITLE}।",
    "st_i2": "हर वाक्य को सुनो और साथ में पढ़ो।",
    "st_d1": "पहले: {S}",
    "st_d2": "फिर: {S}",
    "st_d3": "आख़िर में: {S}",
    "st_d4": "आओ कहानी को फिर से सुनाएँ। {S1} {S2} {S3}",
    "st_d5": "सवाल: {Q} कहानी में देखो: {S} उत्तर है {A}।",
    "st_r1": "आँखें बंद करो और कहानी याद करो। पहले: {S}",
    "st_r2": "फिर: {S}",
    "st_r3": "आख़िर में: {S}",
    "q_sfirst": "कहानी में सबसे पहले क्या हुआ?",
    "q_snext": "इसके ठीक बाद क्या हुआ? {S}",
    "q_slast": "कहानी में आख़िर में क्या हुआ?",
    "q_shear": "सुनो। तुमने कौन सा वाक्य सुना?",
    "q_snot": "इस कहानी में कौन सा वाक्य नहीं है?",
    "w_i1": "आज हम शब्द बनाएँगे। चित्र हमें छूटा हुआ अक्षर ढूँढने में मदद करता है।",
    "w_i2": "{W}: {S1} + {S2} + {S3}।",
    "w_d1": "चित्र देखो। यह {W} है।",
    "w_dm": "एक अक्षर छिपाओ: {BL} आवाज़ें बोलो। छूटा हुआ अक्षर {X} है।",
    "w_d1m": "एक और शब्द: {W}। {BL} छूटा हुआ अक्षर {X} है।",
    "w_d5": "पहेली: कौन सा शब्द इस चित्र का नाम नहीं है? यह {W} है। {X} दूसरा शब्द है।",
    "w_r1": "{W} को धीरे-धीरे बोलो और हर आवाज़ सुनो।",
    "w_r2": "अब आख़िरी अक्षर छिपाओ: {BL} कौन सा अक्षर छूटा है? यह {X} है।",
    "w_r3": "अक्षरों को फिर से जोड़ो: {S1} + {S2} + {S3} = {W}।",
    "q_wmiss": "कौन सा अक्षर छूट गया है?",
    "q_wpic": "इस चित्र में क्या है?",
    "q_whear": "सुनो। कौन सा चित्र है?",
    "q_wnot": "इस चित्र का नाम कौन सा शब्द नहीं है?",
    "syl_i1": "आज हम {B} में {S} की मात्रा लगाएँगे।",
    "syl_i2": "{B} + {S} = {L}। सुनो: {L}।",
    "syl_d1": "यह अक्षर {B} है। इसके साथ {S} की मात्रा लगेगी।",
    "syl_d2": "{B} में {S} की मात्रा लगाकर {L} बनता है।",
    "syl_d3b": "शब्द सुनो: {W}। {W} {L} से शुरू होता है।",
    "syl_d3c": "शब्द सुनो: {W}। इसमें {L} है।",
    "syl_d4": "मात्रा बदलने से अक्षर बदल जाता है। {B} + {S2} = {L2}।",
    "syl_d5": "पहेली: किस अक्षर में {S} की मात्रा नहीं है? {L} में {S} की मात्रा है। {L2} में नहीं है। इसलिए {L2} अलग है।",
    "syl_r1": "{B} बोलो। यह बिना मात्रा का अक्षर है।",
    "syl_r2": "अब {S} की मात्रा देखो। यह {B} के साथ जुड़कर आवाज़ बदल देती है।",
    "syl_r3": "दोनों को जोड़कर पढ़ो: {L}।",
    "q_combine": "{B} + {S} = ?",
    "sp_combine": "{B} में {S} की मात्रा लगाने पर कौन सा अक्षर बनता है?",
    "q_hear": "सुनो। तुमने कौन सा अक्षर सुना?",
    "q_decomp": "यह अक्षर किन दो भागों से बना है?",
    "q_sign": "{B} + ? = {L}। कौन सी मात्रा चाहिए?",
    "q_wbegin": "शब्द सुनो। यह किस अक्षर से शुरू होता है?",
    "q_namepic": "इस चित्र में क्या है?",
    "q_match": "ऐसा ही अक्षर ढूँढो।",
    "q_not": "किस अक्षर में {S} की मात्रा नहीं है?",
}
STR["ta"] = {
    "h_look": "ஒவ்வொரு தேர்வையும் கவனமாகப் பாருங்கள்.",
    "h_listen": "மீண்டும் கேளுங்கள், பிறகு ஒவ்வொன்றையும் பாருங்கள்.",
    "h_first": "சொல்லின் முதல் ஒலியைக் கேளுங்கள்.",
    "h_pic": "படத்தைப் பார்த்து அதன் பெயரை மெதுவாகச் சொல்லுங்கள்.",
    "h_read": "ஒவ்வொரு தேர்வையும் மெதுவாகப் படியுங்கள்.",
    "h_sentence": "வாக்கியத்தை மீண்டும் படியுங்கள், ஒவ்வொரு சொல்லாக.",
    "h_count": "ஒவ்வொரு சொல்லையும் தொட்டு ஒவ்வொன்றாக எண்ணுங்கள்.",
    "h_blank": "வாக்கியத்தை மீண்டும் படியுங்கள். எந்தச் சொல் மறைந்துள்ளது?",
    "h_story": "கதையைப் பற்றி யோசியுங்கள். முதலில், அடுத்து, கடைசியில் என்ன நடந்தது?",
    "h_parts": "முதலில் பெரிய எழுத்தைப் பாருங்கள், பிறகு சேர்ந்த உயிரைப் பாருங்கள்.",
    "h_sign": "எழுத்துடன் சேர்ந்துள்ள உயிரைக் கவனியுங்கள்.",
    "h_sound": "ஒலியை மெதுவாகச் சொல்லுங்கள். இது எந்த எழுத்து?",
    "hr_ans": "விடை {A}.",
    "hr_sent": "வாக்கியம் இது: {T}",
    "hr_story": "இந்த வாக்கியத்தைப் பாருங்கள்: {S}",
    "hr_syl": "{B} + {S} = {L}.",
    "fb_try": "நல்ல முயற்சி! மீண்டும் பார்த்து இன்னொன்றைத் தேர்ந்தெடுங்கள்.",
    "fb_letter": "அது வேறு எழுத்து. கவனமாகப் பாருங்கள்.",
    "fb_word": "அது வேறு சொல். மீண்டும் பாருங்கள்.",
    "fb_pic": "அது வேறு படம். மீண்டும் பாருங்கள்.",
    "fb_heard": "அது நீங்கள் கேட்டது அல்ல. மீண்டும் கேளுங்கள்.",
    "fb_sent": "அது வேறு வாக்கியம். மீண்டும் கேளுங்கள்.",
    "fb_count": "சொற்களை ஒவ்வொன்றாக மீண்டும் எண்ணுங்கள்.",
    "fb_story": "கதையில் அப்படி இல்லை. கதையை மீண்டும் நினைவுபடுத்துங்கள்.",
    "fb_fit": "அந்தச் சொல் வெற்றிடத்திற்குப் பொருந்தாது. வாக்கியத்தை மீண்டும் படியுங்கள்.",
    "fb_parts": "அவை அந்த இரண்டு பகுதிகள் அல்ல. எழுத்தை மீண்டும் பாருங்கள்.",
    "fb_sign": "அது வேறு உயிர். மீண்டும் முயற்சி செய்யுங்கள்.",
    "ex_ans": "விடை {A}.",
    "ex_sent": "நீங்கள் கேட்டது: {A}",
    "ex_first": "முதல் சொல் {A}.",
    "ex_last": "கடைசிச் சொல் {A}.",
    "ex_count": "இந்த வாக்கியத்தில் {A} சொற்கள் உள்ளன.",
    "ex_fill": "வர வேண்டிய சொல் {A}.",
    "ex_notin": "{A} இந்த வாக்கியத்தில் இல்லை.",
    "ex_story": "கதையில் இப்படி உள்ளது: {A}",
    "ex_namepic": "இது {A}.",
    "ex_heard": "நீங்கள் {A} என்ற சொல்லைக் கேட்டீர்கள்.",
    "ex_combine": "{B} + {S} = {A}.",
    "ex_decomp": "இந்த இரண்டு பகுதிகளையும் சேர்த்தால் இந்த எழுத்து உருவாகும்.",
    "ex_sign": "{S} உயிர் தேவை.",
    "ex_wbegin": "{W} என்ற சொல் {L} என்ற எழுத்தில் தொடங்குகிறது.",
    "ex_not": "{A} எழுத்தில் {S} உயிர் சேரவில்லை.",
    "ex_wfirst": "{W} என்ற சொல் {A} என்ற எழுத்தில் தொடங்குகிறது.",
    "se_i1": "ஒரு வாக்கியத்தைப் படிப்போம். கேளுங்கள், சேர்ந்து படியுங்கள்.",
    "se_i2": "{T}",
    "se_d1": "ஒவ்வொரு சொல்லாகப் படியுங்கள்: {WORDS}.",
    "se_d2": "முதல் சொல் {F}. கடைசிச் சொல் {Z}.",
    "se_d3": "இந்த வாக்கியத்தில் {N} சொற்கள் உள்ளன.",
    "se_d4": "வாக்கியத்தைப் பற்றிக் கேள்வி கேட்டால், வாக்கியத்தை மீண்டும் படித்து விடையைத் தேடுங்கள்.",
    "se_d5": "வெற்றிடத்தை நிரப்புவோம்: {BL} இங்கே வர வேண்டிய சொல் {X}.",
    "se_r1": "ஒரு சொல்லை மூடுங்கள்: {BL} வாக்கியத்தை மீண்டும் படித்து வெற்றிடத்திற்கு எந்தச் சொல் பொருந்தும் என்று யோசியுங்கள்.",
    "se_r2": "வாக்கியத்தை இரண்டு பகுதிகளாகப் படியுங்கள்: {P1} | {P2}",
    "se_r3": "இன்னொரு முறை கேளுங்கள்: {T}",
    "q_hears": "கேளுங்கள். நீங்கள் எந்த வாக்கியத்தைக் கேட்டீர்கள்?",
    "q_first": "வாக்கியத்தின் முதல் சொல் எது?",
    "q_last": "வாக்கியத்தின் கடைசிச் சொல் எது?",
    "q_count": "வாக்கியத்தில் எத்தனை சொற்கள் உள்ளன?",
    "q_fill": "வெற்றிடத்திற்கு எந்தச் சொல் பொருந்தும்?",
    "q_notin": "இந்த வாக்கியத்தில் இல்லாத சொல் எது?",
    "st_i1": "இன்று ஒரு கதையைப் படிப்போம்: {TITLE}.",
    "st_i2": "ஒவ்வொரு வாக்கியத்தையும் கேளுங்கள், சேர்ந்து படியுங்கள்.",
    "st_d1": "முதலில்: {S}",
    "st_d2": "அடுத்து: {S}",
    "st_d3": "கடைசியில்: {S}",
    "st_d4": "கதையை மீண்டும் சொல்வோம். {S1} {S2} {S3}",
    "st_d5": "கேள்வி: {Q} கதையை மீண்டும் பாருங்கள்: {S} விடை {A}.",
    "st_r1": "கண்களை மூடிக் கதையை நினைவுபடுத்துங்கள். முதலில்: {S}",
    "st_r2": "அடுத்து: {S}",
    "st_r3": "கடைசியில்: {S}",
    "q_sfirst": "கதையில் முதலில் என்ன நடந்தது?",
    "q_snext": "இதற்குப் பிறகு என்ன நடந்தது? {S}",
    "q_slast": "கதையில் கடைசியில் என்ன நடந்தது?",
    "q_shear": "கேளுங்கள். நீங்கள் எந்த வாக்கியத்தைக் கேட்டீர்கள்?",
    "q_snot": "இந்தக் கதையில் இல்லாத வாக்கியம் எது?",
    "w_i1": "இன்று படத்தைப் பார்த்துச் சரியான சொல்லைத் தேர்ந்தெடுப்போம்.",
    "w_i2": "{W}. படத்தைப் பாருங்கள்.",
    "w_d1": "இது {W}. {W} என்ற சொல்லைப் படியுங்கள்.",
    "w_d4": "ஒவ்வொரு சொல்லும் ஓர் எழுத்தில் தொடங்கும். {W1} {L1} என்ற எழுத்திலும், {W2} {L2} என்ற எழுத்திலும், {W3} {L3} என்ற எழுத்திலும் தொடங்குகின்றன.",
    "w_d5": "புதிர்: இந்தப் படத்தின் பெயர் அல்லாத சொல் எது? இது {W}. {X} இந்தப் படத்தின் பெயர் அல்ல, எனவே {X} வேறுபட்டது.",
    "w_r1": "{W} என்று மெதுவாகச் சொல்லுங்கள். முதல் ஒலியைக் கேளுங்கள்.",
    "w_r2": "இப்போது படத்தைப் பார்த்துப் பெயர் சொல்லுங்கள், பிறகு முதல் எழுத்தைப் பாருங்கள்: {L}.",
    "w_r3": "{W} என்ற சொல் {L} என்ற எழுத்தில் தொடங்குகிறது. படத்தையும் சொல்லையும் சேர்த்து நினைவில் வையுங்கள்.",
    "q_wpic": "இது என்ன படம்?",
    "q_whear": "கேளுங்கள். எந்தப் படம்?",
    "q_wnot": "இந்தப் படத்தின் பெயர் அல்லாத சொல் எது?",
    "q_wfirst": "சொல்லைக் கேளுங்கள். அது எந்த எழுத்தில் தொடங்குகிறது?",
    "syl_i1": "இன்று {B} உடன் {S} என்ற உயிரைச் சேர்ப்போம்.",
    "syl_i2": "{B} + {S} = {L}. கேளுங்கள்: {L}.",
    "syl_d1": "இது {B} என்ற எழுத்து. இதனுடன் {S} என்ற உயிர் சேரும்.",
    "syl_d2": "{B} உடன் {S} உயிர் சேர்ந்தால் {L} எழுத்து உருவாகும்.",
    "syl_d3b": "{W} என்ற சொல்லைக் கேளுங்கள். {W} {L} என்ற எழுத்தில் தொடங்குகிறது.",
    "syl_d3c": "{W} என்ற சொல்லைக் கேளுங்கள். இதில் {L} என்ற எழுத்து உள்ளது.",
    "syl_d4": "உயிர் மாறினால் எழுத்து மாறும். {B} + {S2} = {L2}.",
    "syl_d5": "புதிர்: {S} உயிர் சேராத எழுத்து எது? {L} எழுத்தில் {S} உயிர் சேர்ந்துள்ளது. {L2} எழுத்தில் சேரவில்லை. எனவே {L2} வேறுபட்டது.",
    "syl_r1": "{B} என்று சொல்லுங்கள். இது உயிர் சேராத எழுத்து.",
    "syl_r2": "இப்போது {S} உயிரைக் கவனியுங்கள். இது {B} உடன் சேர்ந்து ஒலியை மாற்றும்.",
    "syl_r3": "இரண்டையும் சேர்த்துப் படியுங்கள்: {L}.",
    "q_combine": "{B} + {S} = ?",
    "sp_combine": "{B} உடன் {S} உயிர் சேர்ந்தால் எந்த எழுத்து உருவாகும்?",
    "q_hear": "கேளுங்கள். நீங்கள் எந்த எழுத்தைக் கேட்டீர்கள்?",
    "q_decomp": "இந்த எழுத்து எந்த இரண்டு பகுதிகளால் ஆனது?",
    "q_sign": "{B} + ? = {L}. எந்த உயிர் தேவை?",
    "q_wbegin": "சொல்லைக் கேளுங்கள். அது எந்த எழுத்தில் தொடங்குகிறது?",
    "q_namepic": "இது என்ன படம்?",
    "q_match": "இதே போன்ற எழுத்தைத் தேடுங்கள்.",
    "q_not": "{S} உயிர் சேராத எழுத்து எது?",
}

# ====================================================================== templates
#@@TEMPLATES

# ====================================================================== meta + main
#@@MAIN
