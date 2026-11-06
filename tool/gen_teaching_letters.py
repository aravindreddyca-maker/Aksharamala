# -*- coding: utf-8 -*-
"""Rollout R2 generator: Level 1 letter-recognition teaching plans (English, Telugu, Hindi, Tamil).

Author: content-creator. Output is UNVERIFIED. Run:  python -X utf8 -I tool/gen_teaching_letters.py
Reads (nothing under lib/ is modified):
  lib/src/curriculum.dart            -> the recognition sequences (ids, titles, objectives, prerequisites, options)
  lib/src/alphabet/alphabet_data.dart -> picture word + picture path per letter
Writes:
  content/teaching_pending/rollout_letters.json
  audit/ROLLOUT_R2_LETTERS_SPECS.md
The four finished pilot letter plans (en-a, te-a, hi-a, ta-a) are never regenerated here.
"""
import itertools
import json
import os
import re
import sys
import unicodedata

ROOT = r"E:\Aksharamala"
OUT_JSON = ROOT + r"\content\teaching_pending\rollout_letters.json"
OUT_MD = ROOT + r"\audit\ROLLOUT_R2_LETTERS_SPECS.md"
WORLDS = ["english", "telugu", "hindi", "tamil"]
SHORT = {"english": "en", "telugu": "te", "hindi": "hi", "tamil": "ta"}
LOCALE = {"english": "en-US", "telugu": "te-IN", "hindi": "hi-IN", "tamil": "ta-IN"}
LANGNAME = {"english": "English", "telugu": "Telugu", "hindi": "Hindi", "tamil": "Tamil"}
DONE = {"en-a", "te-a", "hi-a", "ta-a"}
# English X: the picture word (Xylophone) begins with the LETTER X but its first SOUND is z, so no sound claim is made;
# the lesson is taught letter-only and the educator decides (see UNVERIFIED list).
FORCE_LETTER_ONLY = {("english", "X")}

MASTERY = {"check_total": 3, "check_pass": 2, "remediation_pass": 2,
           "max_remediation_cycles": 2, "after_limit": "offer_parent_support"}

# ---------------------------------------------------------------- strings
STR = {
 "en": {
  "intro1": "This is the letter {L}.",
  "intro2": "{L} is for {W1}.",
  "demo1": "Look at the letter {L}. Say it with me: {L}.",
  "demo2": "{W1} begins with {L}.",
  "demo3": "{W} does not begin with {L}. It is a different letter.",
  "q_word": "Which word begins with {L}?",
  "q_word2": "Find the word that begins with {L}.",
  "q_letter": "Which letter is this?",
  "q_letter_listen": "Listen. Which letter is it?",
  "q_pic_letter": "Which letter does this word begin with?",
  "q_listen_word_letter": "Listen to the word. Which letter does it begin with?",
  "q_pic_word": "What is this picture?",
  "q_listen_pic": "Listen. Which picture is it?",
  "q_listen_letter_pic": "Listen to the letter. Which word begins with it?",
  "q_listen_word_text": "Listen. Which word did you hear?",
  "hint_slow": "Say the words slowly. Listen to the first sound.",
  "hint_reveal": "{W1} begins with {L}. A says a, like in {W1}.",
  "hint_same": "Find the letter that looks just like this one.",
  "hint_listen": "Listen again, then look at each picture.",
  "fb_generic": "Good try! Listen to the first sound again and try another.",
  "fb_word": "{W} begins with a different letter. Look at another word.",
  "fb_letter": "That is a different letter. Look closely at the letter.",
  "fb_pic": "That is a different picture. Look again.",
  "expl_word": "{W1} begins with {L}.",
  "expl_letter": "This letter is {L}.",
  "expl_pic": "This picture is {W}.",
  "expl_heard": "You heard {W}.",
  "r1": "Say {W}. Does it begin with {L}? No.",
  "r3": "Say {W1}. Yes! {W1} begins with {L}.",
  "spk_word": "{W}.",
  "spk_letter": "{L}.",
  "demo_not": "A puzzle: which word does NOT begin with {L}? {W1} does begin with {L}. {W} does not. {W} is the odd one out.",
  "fb_heard": "That is not what you heard. Listen again.",
  "fb_say": "Say {W} slowly. Listen to its first sound. Try again!",
  "q_not": "Which word does NOT begin with {L}?",
  "r_a": "Close your eyes. Listen: {W1}. The first sound is the sound of {L}.",
  "r_b": "Listen: {W}. Does it start with the sound of {L}? No. It starts with a different sound.",
  "r_c": "When you hear the sound of {L} first, think of {W1}.",
  "hint_narrow": "Say each name. Which one starts with the same sound?",
  "hint_look": "Look at the picture. Say its name slowly.",
  "q_same_big": "Which big letter is the same as this small letter?",
  "q_listen_word_small": "Listen to the word. Which small letter does it begin with?",
  "hint_pair1": "Look at the small letter. Which big letter is its partner?",
  "hint_pair2": "Say the first sound of Apple. Which big letter makes it?",
  "expl_pair": "Big A and small a are the same letter.",
  "expl_small": "{W1} begins with small a."
 },
 "te": {
  "intro1": "ఇది {L} అక్షరం.",
  "intro2": "{L} – {W1}. {W1} అనే పదం {L} తో మొదలవుతుంది.",
  "demo1": "{L} అక్షరాన్ని చూడండి. నాతో చెప్పండి: {L}.",
  "demo2": "{W1} {L} తో మొదలవుతుంది.",
  "demo3": "{W} {L} తో మొదలవదు. ఇది వేరే అక్షరం.",
  "q_word": "{L} తో మొదలయ్యే పదం ఏది?",
  "q_word2": "{L} తో మొదలయ్యే పదాన్ని కనుగొనండి.",
  "q_letter": "ఈ అక్షరం ఏది?",
  "q_letter_listen": "వినండి. ఇది ఏ అక్షరం?",
  "q_pic_letter": "ఈ పదం ఏ అక్షరంతో మొదలవుతుంది?",
  "q_listen_word_letter": "పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది?",
  "q_pic_word": "ఈ బొమ్మ ఏమిటి?",
  "q_listen_pic": "వినండి. ఏ బొమ్మ?",
  "q_listen_letter_pic": "అక్షరాన్ని వినండి. దానితో మొదలయ్యే పదం ఏది?",
  "q_listen_word_text": "వినండి. మీరు ఏ పదం విన్నారు?",
  "hint_slow": "పదాన్ని నెమ్మదిగా చెప్పండి. మొదటి శబ్దాన్ని వినండి.",
  "hint_reveal": "{W1} {L} తో మొదలవుతుంది.",
  "hint_same": "ఈ అక్షరంలా ఉన్న అక్షరాన్ని వెతకండి.",
  "hint_listen": "మళ్లీ వినండి, తర్వాత ప్రతి బొమ్మను చూడండి.",
  "fb_generic": "మంచి ప్రయత్నం! మొదటి శబ్దాన్ని మళ్లీ వినండి, మరొకటి ప్రయత్నించండి.",
  "fb_word": "{W} వేరే అక్షరంతో మొదలవుతుంది. మరొక పదాన్ని చూడండి.",
  "fb_letter": "అది వేరే అక్షరం. అక్షరాన్ని జాగ్రత్తగా చూడండి.",
  "fb_pic": "అది వేరే బొమ్మ. మళ్లీ చూడండి.",
  "expl_word": "{W1} {L} తో మొదలవుతుంది.",
  "expl_letter": "ఇది {L} అక్షరం.",
  "expl_pic": "ఇది {W}.",
  "expl_heard": "మీరు {W} విన్నారు.",
  "r1": "{W} అని చెప్పండి. ఇది {L} తో మొదలవుతుందా? లేదు.",
  "r3": "{W1} అని చెప్పండి. అవును! {W1} {L} తో మొదలవుతుంది.",
  "spk_word": "{W}.",
  "spk_letter": "{L}.",
  "demo_not": "పజిల్: {L} తో మొదలవని పదం ఏది? {W1} {L} తో మొదలవుతుంది. {W} మొదలవదు. కాబట్టి {W} వేరుగా ఉంది.",
  "fb_heard": "అది మీరు విన్నది కాదు. మళ్లీ వినండి.",
  "fb_say": "{W} ని నెమ్మదిగా చెప్పండి. మొదటి శబ్దాన్ని వినండి. మళ్లీ ప్రయత్నించండి!",
  "q_not": "{L} తో మొదలవని పదం ఏది?",
  "r_a": "కళ్ళు మూసుకోండి. వినండి: {W1}. మొదటి శబ్దం {L} శబ్దం.",
  "r_b": "వినండి: {W}. ఇది {L} శబ్దంతో మొదలవుతుందా? లేదు, వేరే శబ్దంతో మొదలవుతుంది.",
  "r_c": "మొదట {L} శబ్దం వినిపిస్తే, {W1} అని గుర్తుంచుకోండి.",
  "hint_narrow": "ప్రతి బొమ్మ పేరు చెప్పండి. ఏది అదే శబ్దంతో మొదలవుతుంది?",
  "hint_look": "బొమ్మను చూడండి. దాని పేరు నెమ్మదిగా చెప్పండి."
 },
 "hi": {
  "intro1": "यह अक्षर {L} है।",
  "intro2": "{L} से {W1}। {W1} शब्द {L} से शुरू होता है।",
  "demo1": "अक्षर {L} को देखो। मेरे साथ बोलो: {L}।",
  "demo2": "{W1} {L} से शुरू होता है।",
  "demo3": "{W} {L} से शुरू नहीं होता। यह दूसरा अक्षर है।",
  "q_word": "{L} से कौन सा शब्द शुरू होता है?",
  "q_word2": "{L} से शुरू होने वाला शब्द ढूँढो।",
  "q_letter": "यह कौन सा अक्षर है?",
  "q_letter_listen": "सुनो। यह कौन सा अक्षर है?",
  "q_pic_letter": "इस चित्र का शब्द किस अक्षर से शुरू होता है?",
  "q_listen_word_letter": "शब्द सुनो। यह किस अक्षर से शुरू होता है?",
  "q_pic_word": "इस चित्र में क्या है?",
  "q_listen_pic": "सुनो। कौन सा चित्र है?",
  "q_listen_letter_pic": "अक्षर सुनो। इससे शुरू होने वाला शब्द कौन सा है?",
  "q_listen_word_text": "सुनो। तुमने कौन सा शब्द सुना?",
  "hint_slow": "शब्द को धीरे-धीरे बोलो। पहली आवाज़ सुनो।",
  "hint_reveal": "{W1} {L} से शुरू होता है।",
  "hint_same": "ऐसा ही दिखने वाला अक्षर ढूँढो।",
  "hint_listen": "फिर से सुनो, फिर हर चित्र को देखो।",
  "fb_generic": "अच्छी कोशिश! पहली आवाज़ फिर से सुनो और दोबारा कोशिश करो।",
  "fb_word": "{W} दूसरे अक्षर से शुरू होता है। कोई और शब्द देखो।",
  "fb_letter": "वह दूसरा अक्षर है। अक्षर को ध्यान से देखो।",
  "fb_pic": "वह दूसरा चित्र है। फिर से देखो।",
  "expl_word": "{W1} {L} से शुरू होता है।",
  "expl_letter": "यह अक्षर {L} है।",
  "expl_pic": "यह {W} है।",
  "expl_heard": "तुमने {W} सुना।",
  "r1": "{W} बोलो। क्या यह {L} से शुरू होता है? नहीं।",
  "r3": "{W1} बोलो। हाँ! {W1} {L} से शुरू होता है।",
  "spk_word": "{W}।",
  "spk_letter": "{L}।",
  "demo_not": "पहेली: {L} से कौन सा शब्द शुरू नहीं होता? {W1} {L} से शुरू होता है। {W} नहीं होता। इसलिए {W} अलग है।",
  "fb_heard": "यह वह नहीं है जो तुमने सुना। फिर से सुनो।",
  "fb_say": "{W} को धीरे-धीरे बोलो। पहली आवाज़ सुनो। फिर कोशिश करो!",
  "q_not": "{L} से कौन सा शब्द शुरू नहीं होता?",
  "r_a": "आँखें बंद करो। सुनो: {W1}। पहली आवाज़ {L} की आवाज़ है।",
  "r_b": "सुनो: {W}। क्या यह {L} की आवाज़ से शुरू होता है? नहीं, यह दूसरी आवाज़ से शुरू होता है।",
  "r_c": "जब सबसे पहले {L} की आवाज़ सुनाई दे, तो {W1} याद करो।",
  "hint_narrow": "हर चित्र का नाम बोलो। कौन सा उसी आवाज़ से शुरू होता है?",
  "hint_look": "चित्र को देखो। उसका नाम धीरे-धीरे बोलो।"
 },
 "ta": {
  "intro1": "இது {L} என்ற எழுத்து.",
  "intro2": "{L} – {W1}. {W1} என்ற சொல் {L} என்ற எழுத்தில் தொடங்குகிறது.",
  "demo1": "{L} என்ற எழுத்தைப் பாருங்கள். என்னோடு சொல்லுங்கள்: {L}.",
  "demo2": "{W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
  "demo3": "{W} {L} என்ற எழுத்தில் தொடங்கவில்லை. இது வேறு எழுத்து.",
  "q_word": "{L} என்ற எழுத்தில் தொடங்கும் சொல் எது?",
  "q_word2": "{L} என்ற எழுத்தில் தொடங்கும் சொல்லைக் கண்டுபிடியுங்கள்.",
  "q_letter": "இது எந்த எழுத்து?",
  "q_letter_listen": "கேளுங்கள். இது எந்த எழுத்து?",
  "q_pic_letter": "இந்தச் சொல் எந்த எழுத்தில் தொடங்குகிறது?",
  "q_listen_word_letter": "சொல்லைக் கேளுங்கள். அது எந்த எழுத்தில் தொடங்குகிறது?",
  "q_pic_word": "இது என்ன படம்?",
  "q_listen_pic": "கேளுங்கள். எந்தப் படம்?",
  "q_listen_letter_pic": "எழுத்தைக் கேளுங்கள். அதில் தொடங்கும் சொல் எது?",
  "q_listen_word_text": "கேளுங்கள். நீங்கள் எந்தச் சொல்லைக் கேட்டீர்கள்?",
  "hint_slow": "சொல்லை மெதுவாகச் சொல்லுங்கள். முதல் ஒலியைக் கேளுங்கள்.",
  "hint_reveal": "{W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
  "hint_same": "இதே போல் தெரியும் எழுத்தைத் தேடுங்கள்.",
  "hint_listen": "மீண்டும் கேளுங்கள், பிறகு ஒவ்வொரு படத்தையும் பாருங்கள்.",
  "fb_generic": "நல்ல முயற்சி! முதல் ஒலியை மீண்டும் கேட்டு, இன்னொரு முறை முயற்சி செய்யுங்கள்.",
  "fb_word": "{W} வேறு எழுத்தில் தொடங்குகிறது. வேறொரு சொல்லைப் பாருங்கள்.",
  "fb_letter": "அது வேறு எழுத்து. எழுத்தைக் கவனமாகப் பாருங்கள்.",
  "fb_pic": "அது வேறு படம். மீண்டும் பாருங்கள்.",
  "expl_word": "{W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
  "expl_letter": "இது {L} எழுத்து.",
  "expl_pic": "இது {W}.",
  "expl_heard": "நீங்கள் {W} என்ற சொல்லைக் கேட்டீர்கள்.",
  "r1": "{W} என்று சொல்லுங்கள். இது {L} என்ற எழுத்தில் தொடங்குகிறதா? இல்லை.",
  "r3": "{W1} என்று சொல்லுங்கள். ஆம்! {W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
  "spk_word": "{W}.",
  "spk_letter": "{L}.",
  "demo_not": "புதிர்: {L} என்ற எழுத்தில் தொடங்காத சொல் எது? {W1} {L} என்ற எழுத்தில் தொடங்குகிறது. {W} தொடங்கவில்லை. எனவே {W} வேறுபட்டது.",
  "fb_heard": "அது நீங்கள் கேட்டது அல்ல. மீண்டும் கேளுங்கள்.",
  "fb_say": "{W} என்ற சொல்லை மெதுவாகச் சொல்லுங்கள். முதல் ஒலியைக் கேளுங்கள். மீண்டும் முயற்சி செய்யுங்கள்!",
  "q_not": "{L} என்ற எழுத்தில் தொடங்காத சொல் எது?",
  "r_a": "கண்களை மூடுங்கள். கேளுங்கள்: {W1}. முதல் ஒலி {L} ஒலி.",
  "r_b": "கேளுங்கள்: {W}. இது {L} ஒலியில் தொடங்குகிறதா? இல்லை, இது வேறு ஒலியில் தொடங்குகிறது.",
  "r_c": "முதலில் {L} ஒலி கேட்டால், {W1} என்று நினைவில் வைத்துக்கொள்ளுங்கள்.",
  "hint_narrow": "ஒவ்வொரு படத்தின் பெயரையும் சொல்லுங்கள். எது அதே ஒலியில் தொடங்குகிறது?",
  "hint_look": "படத்தைப் பாருங்கள். அதன் பெயரை மெதுவாகச் சொல்லுங்கள்."
 }
}


LT = {
    "en": {
        "intro1": "This is the letter {L}. It has a big {L} and a small {l}.",
        "intro2_w": "{L} is for {W1}.",
        "intro2_l": "Listen to the letter {L}. Say it with me: {L}.",
        "demo_big": "This is big {L}. It is the capital letter.",
        "demo_small": "This is small {l}. Big {L} and small {l} are the same letter.",
        "demo_listen": "Now listen to the letter {L}. Say it with me: {L}.",
        "demo_word": "{W1} begins with {L}.",
        "demo_diff": "This is {X}. {X} is not {L}. It is a different letter.",
        "demo_puzzle": "A puzzle: only one of these letters is {L}. {N1} is not {L}. {N2} is not {L}. So the other one is {L}.",
        "H": ["Listen. Which letter is it?", "Which letter do you hear?", "Listen carefully. Tap the letter you hear.",
              "Which letter did I say?", "Listen and find the letter.", "Tap the letter that you hear.",
              "Which letter am I saying now?", "Listen once more. Find the letter."],
        "q_look": "Which letter is this?",
        "q_lw": "Listen to the word. Which letter does it begin with?",
        "q_lw2": "Listen: which letter does this word start with?",
        "q_lw_small": "Listen to the word. Which small letter does it begin with?",
        "q_same_big": "Which big letter is the same as this small letter?",
        "q_small_partner": "Which small letter is the partner of this big letter?",
        "q_not_letter": "Which letter is NOT {L}?",
        "hint_look": "Look at the shape of the letter carefully.",
        "hint_look2": "This letter is {L}.",
        "hint_hear": "Listen again. Say the letter softly.",
        "hint_hear2": "It is the letter {L}.",
        "hint_hear_b": "Look at the letters. Which one matches what you heard?",
        "hint_word": "Say the word slowly. Listen to the first sound.",
        "hint_word2": "{W1} begins with {L}.",
        "hint_diff": "Look at the big letter. Find the one that looks different.",
        "hint_say_each": "Say each letter. Which one is not the same as the big letter?",
        "hint_pair1": "Look at the small letter. Which big letter is its partner?",
        "hint_pair2": "Big {L} and small {l} are the same letter.",
        "hint_partner1": "Look at the big letter. Find the small letter that looks like it.",
        "hint_partner2": "Big and small partners are the same letter. Which small letter matches?",
        "hint_not2": "{X} is not {L}.",
        "fb_letter": "That is a different letter. Look closely at the letter.",
        "fb_hear": "That is not the letter you heard. Listen again.",
        "fb_not": "That letter is {O}. Find the letter that is different.",
        "fb_say": "Say {W} slowly. Listen to its first sound. Try again!",
        "expl_look": "This letter is {L}.",
        "expl_hear": "You heard the letter {L}.",
        "expl_word": "{W1} begins with {L}.",
        "expl_not": "{X} is not {L}. It is a different letter.",
        "expl_pair": "Big {L} and small {l} are the same letter.",
        "expl_partner": "Small {l} is the partner of big {L}.",
        "expl_small": "{W1} begins with small {l}.",
        "r_a": "Close your eyes. Listen: {L}. Say it softly: {L}.",
        "r_b": "Now open your eyes and look at the shape of {L}. {N1} has a different shape.",
        "r_c": "When you hear {L}, look for this shape: big {L} and small {l}.",
        "r_w": "Say {W1} slowly. {W1} begins with {L}.",
        "spk_letter": "{L}.",
        "spk_word": "{W}.",
    },
    "te": {
        "intro1": "ఇది {L} అక్షరం.",
        "intro2_w": "{L} – {W1}. {W1} అనే పదం {L} తో మొదలవుతుంది.",
        "intro2_l": "{L} అక్షరాన్ని వినండి. నాతో చెప్పండి: {L}.",
        "demo_look": "{L} అక్షరాన్ని జాగ్రత్తగా చూడండి. ఇది {L}.",
        "demo_listen": "ఇప్పుడు వినండి. ఈ శబ్దం {L} అక్షరానిది.",
        "demo_word": "{W1} {L} తో మొదలవుతుంది.",
        "demo_diff": "ఇది {X}. {X} అంటే {L} కాదు. ఇది వేరే అక్షరం.",
        "demo_puzzle": "పజిల్: వీటిలో ఒకటి మాత్రమే {L}. {N1} {L} కాదు. {N2} {L} కాదు. కాబట్టి మిగిలినదే {L}.",
        "H": ["వినండి. ఇది ఏ అక్షరం?", "మీరు ఏ అక్షరం వింటున్నారు?", "జాగ్రత్తగా వినండి. మీరు విన్న అక్షరాన్ని ఎంచుకోండి.",
              "నేను చెప్పిన అక్షరం ఏది?", "విని, ఆ అక్షరాన్ని కనుగొనండి.", "మీరు విన్న అక్షరాన్ని తాకండి.",
              "ఏ అక్షరం ఈ శబ్దం ఇస్తుంది?", "మళ్లీ ఒకసారి వినండి. అక్షరాన్ని కనుగొనండి."],
        "q_look": "ఈ అక్షరం ఏది?",
        "q_lw": "పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది?",
        "q_lw2": "వినండి: ఈ పదం మొదటి అక్షరం ఏది?",
        "q_not_letter": "{L} కాని అక్షరం ఏది?",
        "hint_look": "అక్షరం ఆకారాన్ని జాగ్రత్తగా చూడండి.",
        "hint_look2": "ఇది {L} అక్షరం.",
        "hint_hear": "మళ్లీ వినండి. అక్షరాన్ని మెల్లగా చెప్పండి.",
        "hint_hear2": "అది {L} అక్షరం.",
        "hint_hear_b": "అక్షరాలను చూడండి. మీరు విన్నదానికి ఏది సరిపోతుంది?",
        "hint_word": "పదాన్ని నెమ్మదిగా చెప్పండి. మొదటి శబ్దాన్ని వినండి.",
        "hint_word2": "{W1} {L} తో మొదలవుతుంది.",
        "hint_diff": "పెద్ద అక్షరాన్ని చూడండి. భిన్నంగా కనిపించేదాన్ని కనుగొనండి.",
        "hint_say_each": "ప్రతి అక్షరాన్ని చెప్పండి. ఏది పెద్ద అక్షరంలా లేదు?",
        "hint_not2": "{X} {L} కాదు.",
        "fb_letter": "అది వేరే అక్షరం. అక్షరాన్ని జాగ్రత్తగా చూడండి.",
        "fb_hear": "మీరు విన్న అక్షరం అది కాదు. మళ్లీ వినండి.",
        "fb_not": "ఆ అక్షరం {O}. భిన్నమైన అక్షరాన్ని కనుగొనండి.",
        "fb_say": "{W} ని నెమ్మదిగా చెప్పండి. మొదటి శబ్దాన్ని వినండి. మళ్లీ ప్రయత్నించండి!",
        "expl_look": "ఇది {L} అక్షరం.",
        "expl_hear": "మీరు {L} అక్షరం విన్నారు.",
        "expl_word": "{W1} {L} తో మొదలవుతుంది.",
        "expl_not": "{X} {L} కాదు. ఇది వేరే అక్షరం.",
        "r_a": "కళ్ళు మూసుకోండి. వినండి: {L}. మెల్లగా చెప్పండి: {L}.",
        "r_b": "ఇప్పుడు కళ్ళు తెరిచి {L} ఆకారాన్ని చూడండి. {N1} ఆకారం వేరు.",
        "r_c": "{L} శబ్దం వినిపిస్తే, ఈ ఆకారాన్ని గుర్తుంచుకోండి.",
        "r_w": "{W1} ని నెమ్మదిగా చెప్పండి. మొదటి శబ్దం {L} శబ్దం.",
        "spk_letter": "{L}.",
        "spk_word": "{W}.",
    },
    "hi": {
        "intro1": "यह अक्षर {L} है।",
        "intro2_w": "{L} से {W1}। {W1} शब्द {L} से शुरू होता है।",
        "intro2_l": "अक्षर {L} को सुनो। मेरे साथ बोलो: {L}।",
        "demo_look": "अक्षर {L} को ध्यान से देखो। यह {L} है।",
        "demo_listen": "अब सुनो। यह आवाज़ अक्षर {L} की है।",
        "demo_word": "{W1} {L} से शुरू होता है।",
        "demo_diff": "यह {X} है। {X}, {L} नहीं है। यह दूसरा अक्षर है।",
        "demo_puzzle": "पहेली: इनमें से एक ही {L} है। {N1}, {L} नहीं है। {N2}, {L} नहीं है। इसलिए बचा हुआ अक्षर {L} है।",
        "H": ["सुनो। यह कौन सा अक्षर है?", "तुम कौन सा अक्षर सुन रहे हो?", "ध्यान से सुनो। जो अक्षर सुना, उसे चुनो।",
              "मैंने कौन सा अक्षर बोला?", "सुनो और वह अक्षर ढूँढो।", "जो अक्षर तुमने सुना, उसे छुओ।",
              "कौन सा अक्षर यह आवाज़ देता है?", "एक बार और सुनो। अक्षर ढूँढो।"],
        "q_look": "यह कौन सा अक्षर है?",
        "q_lw": "शब्द सुनो। यह किस अक्षर से शुरू होता है?",
        "q_lw2": "सुनो: इस शब्द का पहला अक्षर कौन सा है?",
        "q_not_letter": "कौन सा अक्षर {L} नहीं है?",
        "hint_look": "अक्षर का आकार ध्यान से देखो।",
        "hint_look2": "यह अक्षर {L} है।",
        "hint_hear": "फिर से सुनो। अक्षर को धीरे से बोलो।",
        "hint_hear2": "वह अक्षर {L} है।",
        "hint_hear_b": "अक्षरों को देखो। जो सुना, उससे कौन सा मेल खाता है?",
        "hint_word": "शब्द को धीरे-धीरे बोलो। पहली आवाज़ सुनो।",
        "hint_word2": "{W1} {L} से शुरू होता है।",
        "hint_diff": "बड़े अक्षर को देखो। जो अलग दिखता है, उसे ढूँढो।",
        "hint_say_each": "हर अक्षर बोलो। कौन सा बड़े अक्षर जैसा नहीं है?",
        "hint_not2": "{X}, {L} नहीं है।",
        "fb_letter": "वह दूसरा अक्षर है। अक्षर को ध्यान से देखो।",
        "fb_hear": "तुमने वह अक्षर नहीं सुना। फिर से सुनो।",
        "fb_not": "वह अक्षर {O} है। जो अलग है, उसे ढूँढो।",
        "fb_say": "{W} को धीरे-धीरे बोलो। पहली आवाज़ सुनो। फिर कोशिश करो!",
        "expl_look": "यह अक्षर {L} है।",
        "expl_hear": "तुमने अक्षर {L} सुना।",
        "expl_word": "{W1} {L} से शुरू होता है।",
        "expl_not": "{X}, {L} नहीं है। यह दूसरा अक्षर है।",
        "r_a": "आँखें बंद करो। सुनो: {L}। धीरे से बोलो: {L}।",
        "r_b": "अब आँखें खोलो और {L} का आकार देखो। {N1} का आकार अलग है।",
        "r_c": "जब {L} की आवाज़ सुनाई दे, तो यह आकार याद करो।",
        "r_w": "{W1} को धीरे-धीरे बोलो। पहली आवाज़ {L} की आवाज़ है।",
        "spk_letter": "{L}।",
        "spk_word": "{W}।",
    },
    "ta": {
        "intro1": "இது {L} என்ற எழுத்து.",
        "intro2_w": "{L} – {W1}. {W1} என்ற சொல் {L} என்ற எழுத்தில் தொடங்குகிறது.",
        "intro2_l": "{L} என்ற எழுத்தைக் கேளுங்கள். என்னோடு சொல்லுங்கள்: {L}.",
        "demo_look": "{L} என்ற எழுத்தைக் கவனமாகப் பாருங்கள். இது {L}.",
        "demo_listen": "இப்போது கேளுங்கள். இந்த ஒலி {L} என்ற எழுத்தின் ஒலி.",
        "demo_word": "{W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
        "demo_diff": "இது {X}. {X} என்பது {L} அல்ல. இது வேறு எழுத்து.",
        "demo_puzzle": "புதிர்: இவற்றில் ஒன்று மட்டுமே {L}. {N1} {L} அல்ல. {N2} {L} அல்ல. எனவே மீதமுள்ளதே {L}.",
        "H": ["கேளுங்கள். இது எந்த எழுத்து?", "நீங்கள் எந்த எழுத்தைக் கேட்கிறீர்கள்?", "கவனமாகக் கேளுங்கள். கேட்ட எழுத்தைத் தேர்ந்தெடுங்கள்.",
              "நான் சொன்ன எழுத்து எது?", "கேட்டு, அந்த எழுத்தைக் கண்டுபிடியுங்கள்.", "நீங்கள் கேட்ட எழுத்தைத் தொடுங்கள்.",
              "எந்த எழுத்து இந்த ஒலியைத் தருகிறது?", "இன்னொரு முறை கேளுங்கள். எழுத்தைக் கண்டுபிடியுங்கள்."],
        "q_look": "இது எந்த எழுத்து?",
        "q_lw": "சொல்லைக் கேளுங்கள். அது எந்த எழுத்தில் தொடங்குகிறது?",
        "q_lw2": "கேளுங்கள்: இந்தச் சொல்லின் முதல் எழுத்து எது?",
        "q_not_letter": "{L} அல்லாத எழுத்து எது?",
        "hint_look": "எழுத்தின் வடிவத்தைக் கவனமாகப் பாருங்கள்.",
        "hint_look2": "இது {L} என்ற எழுத்து.",
        "hint_hear": "மீண்டும் கேளுங்கள். எழுத்தை மெதுவாகச் சொல்லுங்கள்.",
        "hint_hear2": "அது {L} என்ற எழுத்து.",
        "hint_hear_b": "எழுத்துகளைப் பாருங்கள். நீங்கள் கேட்டதற்கு எது பொருந்துகிறது?",
        "hint_word": "சொல்லை மெதுவாகச் சொல்லுங்கள். முதல் ஒலியைக் கேளுங்கள்.",
        "hint_word2": "{W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
        "hint_diff": "பெரிய எழுத்தைப் பாருங்கள். வேறுபட்டுத் தெரிவதைக் கண்டுபிடியுங்கள்.",
        "hint_say_each": "ஒவ்வொரு எழுத்தையும் சொல்லுங்கள். எது பெரிய எழுத்து போல இல்லை?",
        "hint_not2": "{X} {L} அல்ல.",
        "fb_letter": "அது வேறு எழுத்து. எழுத்தைக் கவனமாகப் பாருங்கள்.",
        "fb_hear": "நீங்கள் கேட்ட எழுத்து அது அல்ல. மீண்டும் கேளுங்கள்.",
        "fb_not": "அந்த எழுத்து {O}. வேறுபட்ட எழுத்தைக் கண்டுபிடியுங்கள்.",
        "fb_say": "{W} என்ற சொல்லை மெதுவாகச் சொல்லுங்கள். முதல் ஒலியைக் கேளுங்கள். மீண்டும் முயற்சி செய்யுங்கள்!",
        "expl_look": "இது {L} என்ற எழுத்து.",
        "expl_hear": "நீங்கள் {L} என்ற எழுத்தைக் கேட்டீர்கள்.",
        "expl_word": "{W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
        "expl_not": "{X} {L} அல்ல. இது வேறு எழுத்து.",
        "r_a": "கண்களை மூடுங்கள். கேளுங்கள்: {L}. மெதுவாகச் சொல்லுங்கள்: {L}.",
        "r_b": "இப்போது கண்களைத் திறந்து {L} வடிவத்தைப் பாருங்கள். {N1} வடிவம் வேறு.",
        "r_c": "{L} ஒலி கேட்டால், இந்த வடிவத்தை நினைவில் வைத்துக்கொள்ளுங்கள்.",
        "r_w": "{W1} என்ற சொல்லை மெதுவாகச் சொல்லுங்கள். முதல் ஒலி {L} ஒலி.",
        "spk_letter": "{L}.",
        "spk_word": "{W}.",
    },
}

NOT_AB = {
    "en": {"demo_not_a": "A puzzle: which word does NOT begin with {L}? First look: {W1} does begin with {L}.",
           "demo_not_b": "Now look: {W} does not begin with {L}. {W} is the odd one out."},
    "te": {"demo_not_a": "పజిల్: {L} తో మొదలవని పదం ఏది? మొదట చూడండి: {W1} {L} తో మొదలవుతుంది.",
           "demo_not_b": "ఇప్పుడు చూడండి: {W} {L} తో మొదలవదు. కాబట్టి {W} వేరుగా ఉంది."},
    "hi": {"demo_not_a": "पहेली: {L} से कौन सा शब्द शुरू नहीं होता? पहले देखो: {W1} {L} से शुरू होता है।",
           "demo_not_b": "अब देखो: {W} {L} से शुरू नहीं होता। इसलिए {W} अलग है।"},
    "ta": {"demo_not_a": "புதிர்: {L} என்ற எழுத்தில் தொடங்காத சொல் எது? முதலில் பாருங்கள்: {W1} {L} என்ற எழுத்தில் தொடங்குகிறது.",
           "demo_not_b": "இப்போது பாருங்கள்: {W} {L} என்ற எழுத்தில் தொடங்கவில்லை. எனவே {W} வேறுபட்டது."},
}
for _k, _v in NOT_AB.items():
    STR[_k].update(_v)

# English tier-A strings that mention the letter get {L}/{l} so every letter is parameterised (pilot hard-coded A/a)
EN_A_OVERRIDE = {
    "intro1": "This is the letter {L}. It has a big {L} and a small {l}.",
    "demo_big": "This is big {L}. It is the capital letter.",
    "demo_small": "This is small {l}. Big {L} and small {l} are the same letter.",
    "hint_reveal": "{W1} begins with {L}.",
    "hint_pair2": "Say the first sound of {W1}. Which big letter makes it?",
    "expl_pair": "Big {L} and small {l} are the same letter.",
    "expl_small": "{W1} begins with small {l}.",
}

# ---------------------------------------------------------------- source data
def parse_alphabets():
    t = open(ROOT + r"\lib\src\alphabet\alphabet_data.dart", encoding="utf-8").read()
    out = {}
    for w in WORLDS:
        m = re.search(r"const %sAlphabet = AlphabetSet\((.*?)\n\);" % w, t, re.S)
        body = m.group(1)
        d = {}
        for lm in re.finditer(r"AlphabetLetter\('([^']*)'(.*?)\)(?:,\s*\n)", body, re.S):
            g, rest = lm.group(1), lm.group(2)

            def f(k, rest=rest):
                mm = re.search(k + r":\s*'([^']*)'", rest)
                return mm.group(1) if mm else None
            d[g] = dict(word=f("word"), meaning=f("meaning"), picture=f("picture"))
        out[w] = d
    return out


def parse_recognition():
    src = open(ROOT + r"\lib\src\curriculum.dart", encoding="utf-8").read()
    out = {}
    for w in WORLDS:
        m = re.search(r"final _%sRecognition = _recognitionSequence\((.*?)\n\);" % w, src, re.S).group(1)
        g = lambda k: re.search(k + r":\s*'([^']*)'", m).group(1)
        if "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" in m:
            targets = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        else:
            lst = re.search(r"targets:\s*const\s*\[(.*?)\],\s*\n\s*locale", m, re.S).group(1)
            targets = re.findall(r"'([^']*)'", lst)
        out[w] = dict(prefix=g("idPrefix"), first=g("firstLessonId"), locale=g("locale"), challenge=g("challenge"),
                      objprefix=g("objectivePrefix"), targets=targets)
    return out


ALPHA = parse_alphabets()
REC = parse_recognition()


def lesson_rows(w):
    r = REC[w]
    t = r["targets"]
    n = len(t)

    def idat(i):
        return r["first"] if i == 0 else "%s-%s" % (r["prefix"], str(i + 1).zfill(3))
    rows = []
    for i, L in enumerate(t):
        pool = []
        for x in [t[(i + 1) % n], t[(i + 2) % n]] + [t[j] for j in range(i - 1, -1, -1)][:5]:
            if x != L and x not in pool:
                pool.append(x)
        j = i + 3
        while len(pool) < 7 and j < i + 3 + n:
            x = t[j % n]
            if x != L and x not in pool:
                pool.append(x)
            j += 1
        rows.append(dict(id=idat(i), index=i, letter=L, pool=pool, title=r["challenge"], objective="%s %s" % (r["objprefix"], L),
                         prerequisites=[] if i == 0 else [idat(i - 1)], locale=r["locale"],
                         options=[t[i], t[(i + 1) % n], t[(i + 2) % n]], prev=t[i - 1] if i > 0 else t[-1]))
    return rows


def begins_exact(word, letter):
    """True only if the word begins with exactly this letter (not the letter plus a vowel sign / virama / anusvara)."""
    if not word or not word.startswith(letter):
        return False
    if len(word) > len(letter) and unicodedata.category(word[len(letter)]) in ("Mn", "Mc"):
        return False
    return True


def slug(s):
    return re.sub(r"[^a-z0-9]+", "_", (s or "").lower()).strip("_")


PIC_OVERRIDE = {("telugu", "\u0c13"): "assets/images/quiz/boat.png"}  # boat (existing file) for the word for boat
NUMBER_MEANINGS = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}


def word_info(w, letter):
    x = ALPHA[w].get(letter)
    if not x or not x["word"]:
        return None
    ok = begins_exact(x["word"], letter) and x["word"] != letter  # a word identical to the letter adds nothing and would show the answer
    pic = PIC_OVERRIDE.get((w, letter), x["picture"])
    exists = bool(pic) and os.path.isfile(os.path.join(ROOT, pic.replace("/", os.sep)))
    proposed = False
    if not pic:
        mean = slug(x["meaning"] or x["word"])
        if "name" in mean.split("_"):  # a personal name has no stock picture word: keep the proposed file name neutral
            mean = "name_%04x" % ord(letter[0])
        pic = "assets/images/quiz/%s_%s.webp" % (SHORT[w], mean)
        proposed = True
    return dict(word=x["word"], meaning=x["meaning"], begins=ok, pic=pic, exists=exists, proposed=proposed)



# Telugu: three letters are also ordinary function words used in the shared sentences (ఈ = this, ఆ = that, ఏ = which).
# For those lessons the sentence is reworded so the answer letter never appears as a separate word in a prompt/hint/feedback.
TE_WHICH_MAP = [
    ("వినండి. ఇది ఏ అక్షరం?", "వినండి. అక్షరం ఏమిటి?"),
    ("మీరు ఏ అక్షరం వింటున్నారు?", "మీరు వింటున్న అక్షరం ఏమిటి?"),
    ("ఏ అక్షరం ఈ శబ్దం ఇస్తుంది?", "ఈ శబ్దం ఇచ్చే అక్షరం ఏమిటి?"),
    ("ఈ పదం ఏ అక్షరంతో మొదలవుతుంది?", "ఈ పదం మొదటి అక్షరం ఏమిటి?"),
    ("పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది?", "పదాన్ని వినండి. దాని మొదటి అక్షరం ఏమిటి?"),
    ("వినండి. ఏ బొమ్మ?", "వినండి. బొమ్మ ఏమిటి?"),
    ("వినండి. మీరు ఏ పదం విన్నారు?", "వినండి. మీరు విన్న పదం ఏమిటి?"),
]
TE_HOMOGRAPH = {"ఈ": "ఇక్కడి", "ఆ": "అక్కడి"}


def adapt(w, Ls, s):
    """Ls = every letter that can be an answer or an option in the lesson."""
    if w != "telugu" or not isinstance(s, str):
        return s
    if "ఏ" in Ls:
        for a, b in TE_WHICH_MAP:
            s = s.replace(a, b)
    for L, rep in TE_HOMOGRAPH.items():
        if L in Ls:
            s = re.sub(r"(?<![ఀ-౿{])%s(?![ఀ-౿}])" % L, rep, s)
    return s


# ---------------------------------------------------------------- builders
def place(answer, others, pos):
    o = list(others)
    o.insert(pos, answer)
    return o


class SetPicker:
    """Hands out wrong-option pairs so that no (answer, option set) is used twice in one lesson, spreading the letters."""

    def __init__(self):
        self.used = set()
        self.count = {}

    def pick(self, answer, base):
        base = [x for x in base if x != answer]
        best = None
        for pair in itertools.combinations(base, 2):
            if (answer, frozenset(pair)) in self.used:
                continue
            score = sum(self.count.get(x, 0) for x in pair)
            if best is None or score < best[0]:
                best = (score, pair)
        if best is None:
            raise RuntimeError("no unused option set left")
        pair = best[1]
        self.used.add((answer, frozenset(pair)))
        for x in pair:
            self.count[x] = self.count.get(x, 0) + 1
        return list(pair)


class Fmt(dict):
    def __missing__(self, k):
        raise KeyError(k)


def build_full(row, w, infos, S, tokens):
    """Tier A: the approved pilot template (3 picture words that all begin with their letter, all 3 pictures exist)."""
    lid, en = row["id"], w == "english"
    ALLS = set(row["options"]) | {row["prev"]} | set(row["pool"])
    pk = SetPicker()
    POOL = row["pool"]
    LPOOL = [x.lower() for x in POOL]
    L, L2, L3 = row["options"]
    W1, W2, W3 = [infos[x]["word"] for x in row["options"]]
    P = [infos[x]["pic"] for x in row["options"]]
    pic = {W1: P[0], W2: P[1], W3: P[2]}
    low = L.lower()

    def f(key, **kw):
        base = dict(L=L, l=low, W1=W1, W2=W2, W3=W3, L2=L2, L3=L3)
        base.update(kw)
        return adapt(w, ALLS, S[key]).format(**base)

    def step(phase, n, text, visual, speech=None):
        return {"id": "%s.%s.%d" % (lid, phase, n), "text": text, "speech": speech or text, "visual": visual}

    def v_pic(x, cap=True):
        return {"type": "picture", "asset": pic[x], "caption": x if cap else ""}

    v_glyph = {"type": "glyph", "glyph": L}
    v_lw = {"type": "letterWord", "glyph": L, "word": W1, "asset": P[0]}
    v_none = {"type": "none"}

    def question(phase, n, task, prompt, speech, options, answer, visual, hints, kind, expl, diff, optpics=False):
        fb = {}
        for o in options:
            if o == answer:
                continue
            fb[o] = {"word": lambda: f("fb_word", W=o), "letter": lambda: f("fb_letter"),
                     "pic": lambda: f("fb_pic"), "heard": lambda: f("fb_heard"),
                     "say": lambda: f("fb_say", W=o)}[kind]()
        q = {"id": "%s.%s.%d" % (lid, phase, n), "task": task, "prompt": prompt, "speech": speech, "options": options,
             "answer": answer, "visual": visual, "hints": hints, "wrong_feedback": fb,
             "explanation": expl, "difficulty": diff}
        if optpics:
            q["optionPictures"] = {o: pic[o] for o in options if o in pic}
        return q

    hs, hr, hsame, hl = f("hint_slow"), f("hint_reveal"), f("hint_same"), f("hint_listen")
    hn, hlook = f("hint_narrow"), f("hint_look")
    spW = lambda x: f("spk_word", W=x)
    spL = f("spk_letter")
    notexpl = lambda x: f("demo3", W=x)

    introduce = [step("introduce", 1, f("intro1"), {"type": "glyph", "glyph": (L + " " + low) if en else L}),
                 step("introduce", 2, f("intro2"), v_lw, speech=spL + " " + spW(W1))]
    if en:
        demo = [step("demonstrate", 1, f("demo_big"), v_glyph),
                step("demonstrate", 2, f("demo_small"), {"type": "glyph", "glyph": low}),
                step("demonstrate", 3, f("demo2"), v_lw),
                step("demonstrate", 4, f("demo3", W=W2), v_pic(W2)),
                step("demonstrate", 5, f("demo_not_a"), v_lw),
                step("demonstrate", 6, f("demo_not_b", W=W3), v_pic(W3))]
    else:
        demo = [step("demonstrate", 1, f("demo1"), v_glyph), step("demonstrate", 2, f("demo2"), v_lw),
                step("demonstrate", 3, f("demo3", W=W2), v_pic(W2)),
                step("demonstrate", 4, f("demo3", W=W3), v_pic(W3)),
                step("demonstrate", 5, f("demo_not_a"), v_lw),
                step("demonstrate", 6, f("demo_not_b", W=W3), v_pic(W3))]
    if en:
        g2 = question("guided", 2, "letter_id", f("q_same_big"), f("q_same_big"), place(L, pk.pick(L, POOL), 1), L,
                      {"type": "glyph", "glyph": low}, [f("hint_pair1"), f("hint_pair2")], "letter", f("expl_pair"), 1)
    else:
        g2 = question("guided", 2, "letter_id", f("q_letter"), f("q_letter"), place(L, pk.pick(L, POOL), 1), L, v_glyph,
                      [hsame, f("expl_letter")], "letter", f("expl_letter"), 1)
    guided = [
        question("guided", 1, "pick_word", f("q_word"), f("q_word"), [W2, W1, W3], W1, v_glyph, [hs, hr], "word", f("expl_word"), 1, True),
        g2,
        question("guided", 3, "not_word", f("q_not"), f("q_not"), [W1, W2], W2, v_glyph, [hs, hr], "say", notexpl(W2), 2, True),
    ]
    p1 = question("practice", 1, "word_to_letter", f("q_pic_letter"), f("q_pic_letter"), place(L, pk.pick(L, POOL), 1), L,
                  v_pic(W1, False), [hlook, hs], "letter", f("expl_word"), 1)
    practice = [
        p1,
        question("practice", 2, "name_picture", f("q_pic_word"), f("q_pic_word"), [W1, W3, W2], W2, v_pic(W2, False), [hlook, hs], "pic", f("expl_pic", W=W2), 1),
        question("practice", 3, "hear_pick", f("q_listen_pic"), f("q_listen_pic") + " " + spW(W3), [W2, W3, W1], W3, v_none, [hl, hn], "heard", f("expl_heard", W=W3), 2, True),
        question("practice", 4, "pick_word", f("q_listen_letter_pic"), f("q_listen_letter_pic") + " " + spL, [W3, W1, W2], W1, v_none, [hl, hn], "word", f("expl_word"), 3, True),
        question("practice", 5, "not_word", f("q_not"), f("q_not"), [W3, W1], W3, v_glyph, [hs, hn], "say", notexpl(W3), 3, True),
    ]
    if en:
        c1 = question("check", 1, "word_to_letter", f("q_listen_word_small"), f("q_listen_word_small") + " " + spW(W1),
                      place(low, pk.pick(low, LPOOL), 2), low, v_none, [], "letter", f("expl_small"), 2)
    else:
        c1 = question("check", 1, "word_to_letter", f("q_listen_word_letter"), f("q_listen_word_letter") + " " + spW(W1),
                      place(L, pk.pick(L, POOL), 2), L, v_none, [], "letter", f("expl_word"), 2)
    check = [
        c1,
        question("check", 2, "pick_word", f("q_word2"), f("q_word2"), place(W1, [W3, W2], 0), W1, v_glyph, [], "word", f("expl_word"), 2),
        question("check", 3, "name_picture", f("q_pic_word"), f("q_pic_word"), place(W3, [W2, W1], 1), W3, v_pic(W3, False), [], "pic", f("expl_pic", W=W3), 2),
    ]
    rexplain = [step("remediation_explain", 1, f("r_a"), v_pic(W1, False)),
                step("remediation_explain", 2, f("r_b", W=W2), v_pic(W2, False)),
                step("remediation_explain", 3, f("r_c"), v_pic(W1))]
    rguided = [
        question("remediation_guided", 1, "not_word", f("q_not"), f("q_not"), [W1, W2], W2, v_none, [hs, hr], "say", notexpl(W2), 2, True),
        question("remediation_guided", 2, "hear_pick", f("q_listen_word_text"), f("q_listen_word_text") + " " + spW(W1), [W3, W1, W2], W1, v_none, [hl, hr], "heard", f("expl_heard", W=W1), 1),
    ]
    rc1 = question("remediation_check", 1, "pick_word", f("q_word"), f("q_word"), place(W1, [W2, W3], 0), W1, v_none, [], "word", f("expl_word"), 2)
    rc2 = question("remediation_check", 2, "hear_pick", f("q_listen_pic"), f("q_listen_pic") + " " + spW(W2), place(W2, [W1, W3], 2), W2, v_none, [], "heard", f("expl_heard", W=W2), 2, True)
    rc3 = question("remediation_check", 3, "letter_id", f("q_letter_listen"), f("q_letter_listen") + " " + spL, place(L, pk.pick(L, POOL), 1), L, v_none, [], "letter", f("expl_letter"), 2)
    return dict(introduce=introduce, demonstrate=demo, guided=guided, practice=practice, check=check,
                remediation={"explain": rexplain, "guided": rguided, "check": [rc1, rc2, rc3]})


def build_letter(row, w, hasw, info1, S):
    """Tiers B/C: letter lesson. Wrong letters come from a pool of the lesson's own two options plus letters taught earlier
    (nearest first; for the first lessons the next letters of the alphabet). No (answer, option set) is used twice in a lesson.
    hasw = the target letter has a picture word that begins with it and whose picture file exists."""
    lid, en = row["id"], w == "english"
    ALLS = set(row["options"]) | {row["prev"]} | set(row["pool"])
    L, N1, N2 = row["options"]
    Pv = row["prev"]
    POOL = row["pool"]
    LPOOL = [x.lower() for x in POOL]
    pk = SetPicker()
    low = L.lower()
    W1 = info1["word"] if hasw else None
    asset = info1["pic"] if hasw else None
    H = [adapt(w, ALLS, h) for h in S["H"]]
    SA = lambda k: adapt(w, ALLS, S[k])

    def f(key, **kw):
        base = dict(L=L, l=low, N1=N1, N2=N2, P=Pv, W1=W1)
        base.update(kw)
        return SA(key).format(**base)

    def step(phase, n, text, visual, speech=None):
        return {"id": "%s.%s.%d" % (lid, phase, n), "text": text, "speech": speech or text, "visual": visual}

    def Q(phase, n, task, prompt, speech, options, answer, visual, hints, fbtxt, expl, diff, purpose=None):
        fb = {o: fbtxt(o) for o in options if o != answer}
        q = {"id": "%s.%s.%d" % (lid, phase, n), "task": task, "prompt": prompt, "speech": speech, "options": options,
             "answer": answer, "visual": visual, "hints": hints, "wrong_feedback": fb, "explanation": expl,
             "difficulty": diff}
        if purpose:
            q["purpose"] = purpose
        return q

    spL = f("spk_letter")
    gl = lambda g: {"type": "glyph", "glyph": g}
    none = {"type": "none"}
    fbL = lambda o: f("fb_letter")
    fbH = lambda o: f("fb_hear")
    fbN = lambda o: f("fb_not", O=o)
    fbS = lambda o: f("fb_say", W=W1)
    REV = "spaced_review_previous_letter"

    def hear(phase, n, hi, pos, hints, diff, ans=None):
        a = ans or L
        base = POOL if a == L else [L] + [x for x in POOL if x != a]
        opts = place(a, pk.pick(a, base), pos)
        return Q(phase, n, "letter_id", H[hi], H[hi] + " " + f("spk_letter", L=a), opts, a, none, hints, fbH,
                 f("expl_hear", L=a), diff, REV if a == Pv else None)

    def word_item(phase, n, key, pos, hints, diff):
        opts = place(L, pk.pick(L, POOL), pos)
        return Q(phase, n, "word_to_letter", SA(key), SA(key) + " " + f("spk_word", W=W1), opts, L, none, hints, fbS,
                 f("expl_word"), diff)

    hhear = [f("hint_hear"), f("hint_hear_b")]       # answer-free (practice)
    hhear_g = [f("hint_hear"), f("hint_hear2")]       # guided: second rung may reveal
    hword = [f("hint_word"), f("hint_hear_b")]
    hword_g = [f("hint_word"), f("hint_word2")]
    hnot = [f("hint_diff"), f("hint_say_each")]

    introduce = [step("introduce", 1, f("intro1"), gl((L + " " + low) if en else L))]
    if hasw:
        introduce.append(step("introduce", 2, f("intro2_w"), {"type": "letterWord", "glyph": L, "word": W1, "asset": asset},
                              speech=spL + " " + f("spk_word", W=W1)))
    else:
        introduce.append(step("introduce", 2, f("intro2_l"), gl(L), speech=f("intro2_l")))
    if en:
        demo = [step("demonstrate", 1, f("demo_big"), gl(L)),
                step("demonstrate", 2, f("demo_small"), gl(low))]
        if hasw:
            demo.append(step("demonstrate", 3, f("demo_word"), {"type": "letterWord", "glyph": L, "word": W1, "asset": asset}))
        else:
            demo.append(step("demonstrate", 3, f("demo_listen"), gl(L)))
        demo.append(step("demonstrate", 4, f("demo_diff", X=N1), gl(N1)))
        demo.append(step("demonstrate", 5, f("demo_puzzle"), gl("%s  %s  %s" % (N1, L, N2))))
    else:
        demo = [step("demonstrate", 1, f("demo_look"), gl(L))]
        if hasw:
            demo.append(step("demonstrate", 2, f("demo_word"), {"type": "letterWord", "glyph": L, "word": W1, "asset": asset}))
        else:
            demo.append(step("demonstrate", 2, f("demo_listen"), gl(L)))
        demo.append(step("demonstrate", 3, f("demo_diff", X=N1), gl(N1)))
        demo.append(step("demonstrate", 4, f("demo_diff", X=N2), gl(N2)))
        demo.append(step("demonstrate", 5, f("demo_puzzle"), gl("%s  %s  %s" % (N1, L, N2))))
    # ---- guided
    if en:
        g1 = Q("guided", 1, "letter_id", SA("q_same_big"), SA("q_same_big"), place(L, pk.pick(L, POOL), 1), L, gl(low),
               [f("hint_pair1"), f("hint_pair2")], fbL, f("expl_pair"), 1)
    else:
        g1 = Q("guided", 1, "letter_id", SA("q_look"), SA("q_look"), place(L, pk.pick(L, POOL), 1), L, gl(L),
               [f("hint_look"), f("hint_look2")], fbL, f("expl_look"), 1)
    g2 = hear("guided", 2, 0, 0, hhear_g, 1)
    g3 = Q("guided", 3, "not_letter", f("q_not_letter"), f("q_not_letter"), [N1, L], N1, gl(L),
           [f("hint_diff"), f("hint_not2", X=N1)], fbN, f("expl_not", X=N1), 2)
    guided = [g1, g2, g3]
    # ---- practice (5 + one spaced-review item)
    p1 = hear("practice", 1, 1, 1, hhear, 1)
    p2 = hear("practice", 2, 2, 2, hhear, 1)
    p3 = word_item("practice", 3, "q_lw", 0, hword, 2) if hasw else hear("practice", 3, 3, 1, hhear, 2)
    if en:
        p4 = Q("practice", 4, "letter_id", SA("q_small_partner"), SA("q_small_partner"),
               place(low, pk.pick(low, LPOOL), 2), low, gl(L), [f("hint_partner1"), f("hint_partner2")], fbL,
               f("expl_partner"), 2)
    else:
        p4 = hear("practice", 4, 4, 0, hhear, 2)
    p5 = Q("practice", 5, "not_letter", f("q_not_letter"), f("q_not_letter"), [N2, L], N2, gl(L), hnot, fbN, f("expl_not", X=N2), 3)
    p6 = hear("practice", 6, 7, 2, hhear, 2, ans=Pv)
    practice = [p1, p2, p3, p4, p5, p6]
    # ---- check (3 options, no hints; c3 = spaced review of the previous letter)
    if hasw and en:
        c1 = Q("check", 1, "word_to_letter", SA("q_lw_small"), SA("q_lw_small") + " " + f("spk_word", W=W1),
               place(low, pk.pick(low, LPOOL), 2), low, none, [], fbS, f("expl_small"), 2)
    elif hasw:
        c1 = word_item("check", 1, "q_lw2", 2, [], 2)
    else:
        c1 = hear("check", 1, 5, 2, [], 2)
    c2 = hear("check", 2, 6, 0, [], 2)
    c3 = hear("check", 3, 4, 1, [], 3, ans=Pv)
    check = [c1, c2, c3]
    # ---- remediation
    rexplain = [step("remediation_explain", 1, f("r_a"), gl("%s %s %s" % (L, L, L))),
                step("remediation_explain", 2, f("r_b"), gl("%s  %s  %s" % (N2, L, N1)))]
    if hasw:
        rexplain.append(step("remediation_explain", 3, f("r_w"), {"type": "picture", "asset": asset, "caption": W1}))
    else:
        rexplain.append(step("remediation_explain", 3, f("r_c"), gl((L + " " + low) if en else L)))
    rg1 = Q("remediation_guided", 1, "not_letter", f("q_not_letter"), f("q_not_letter"), [Pv, L], Pv, none,
            [f("hint_diff"), f("hint_not2", X=Pv)], fbN, f("expl_not", X=Pv), 2)
    rg2 = word_item("remediation_guided", 2, "q_lw", 1, hword_g, 1) if hasw else hear("remediation_guided", 2, 0, 1, hhear_g, 1)
    rc1 = hear("remediation_check", 1, 1, 0, [], 2)
    rc2 = hear("remediation_check", 2, 3, 2, [], 2)
    rc3 = word_item("remediation_check", 3, "q_lw2", 1, [], 3) if hasw else hear("remediation_check", 3, 5, 1, [], 3, ans=Pv)
    return dict(introduce=introduce, demonstrate=demo, guided=guided, practice=practice, check=check,
                remediation={"explain": rexplain, "guided": [rg1, rg2], "check": [rc1, rc2, rc3]})


# ---------------------------------------------------------------- per-lesson review
def review_for(w, row, variant, infos, assets_missing):
    L = row["letter"]
    items = [
        "Every sentence (text, speech, prompts, hints, feedback, explanations) is AI-written and UNVERIFIED by a native speaker: grammar, naturalness, register, age suitability." if w != "english" else
        "Educator review of wording, the item mix and the limited variety (see notes).",
        "Text-to-speech in the lesson locale was not heard: how a bare letter is read (letter name versus sound, vowel length) and every sentence.",
    ]
    if w == "english":
        items.append("en-US TTS reading of the bare capital letter '%s.' and of the lowercase '%s' in the small-letter items; big/small partner items rely on the child seeing both cases." % (L, L.lower()))
        if L in ("I", "L"):
            items.append("Capital I and lowercase l look alike in many fonts; check the rendering of the case items.")
    else:
        items.append("The letter wording ('which letter', 'sound of the letter', 'big letter' for the on-screen letter) and the negative item 'which letter is NOT ...' need native and educator confirmation for a 3-4 year old.")
        items.append("The letters used as wrong options are the next two letters of the sequence and (in some items) the previous letter, chosen by order not by visual similarity; confusable pairs were not designed.")
    if variant == "words_pictures":
        items.append("Picture words chosen from lib/src/alphabet/alphabet_data.dart; confirm each picture file clearly shows its word.")
    if variant == "letter_with_word":
        items.append("Only the target letter's picture word (%s) is used (teaching steps and the heard-word items); the other two option letters have no usable picture word, so there are no pick-the-word or name-the-picture items." % infos[L]["word"])
    if variant == "letter_only":
        items.append("No picture word is used for this letter. Reason: " + NO_WORD_REASON.get((w, L), "no picture word"))
    if w != "english" and w == "tamil" and L.endswith("\u0bcd"):
        items.append("Tamil pure consonant (pulli) letter: the bare letter is likely misread by text-to-speech (it may say the consonant with an 'a' or spell it); native speaker to confirm how to speak it.")
    if w in ("telugu", "hindi") and (L.endswith("\u0c02") or L.endswith("\u0c03") or L.endswith("\u0902") or L.endswith("\u0903")):
        items.append("Letter with anusvara/visarga: text-to-speech may not read it as the intended sound; native speaker to confirm.")
    if variant != "letter_only" and "name" in slug(infos[L]["meaning"] or "").split("_"):
        items.append("The source picture word for this letter is a personal name (%s); a picture may not suit a young child. Educator to decide whether to keep it." % infos[L]["meaning"])
    if (w, L) in RARE:
        items.append("Rarely used or conjunct letter: educator to confirm it belongs in a Level 1 recognition set and what it is called.")
    if w == "telugu" and ({"ఈ", "ఆ", "ఏ"} & (set(row["options"]) | {row["prev"]})):
        items.append("This lesson's option letters include a letter that is also an ordinary Telugu word (ఈ this, ఆ that, ఏ which). The shared sentences were reworded for this lesson so that word is not used in prompts, hints or feedback; native speaker to check the reworded sentences.")
    if (w, L) in FORCE_LETTER_ONLY:
        items.append("English X: the picture word Xylophone begins with the letter X, but its first sound is 'z'. No sound claim is made and no word is used; educator to decide how to teach X.")
    return items


NO_WORD_REASON = {}
RARE = {("telugu", "\u0c0b"), ("telugu", "\u0c19"), ("telugu", "\u0c1e"), ("telugu", "\u0c31"), ("telugu", "\u0c15\u0c4d\u0c37"),
        ("hindi", "\u090b"), ("hindi", "\u0919"), ("hindi", "\u091e"), ("tamil", "\u0b94")}


def make_lessons():
    lessons, skipped, tiers = [], [], {}
    for w in WORLDS:
        sk = SHORT[w]
        S_full = dict(STR[sk])
        if w == "english":
            S_full.update(EN_A_OVERRIDE)
        for row in lesson_rows(w):
            lid, L = row["id"], row["letter"]
            if lid in DONE:
                skipped.append((lid, "already planned in the approved pilot (pilot_teaching_plans.json)"))
                continue
            infos = {x: word_info(w, x) for x in row["options"]}
            i1 = infos[L]
            force = (w, L) in FORCE_LETTER_ONLY
            isname = bool(i1) and "name" in slug(i1["meaning"] or "").split("_")
            usable = bool(i1 and i1["begins"] and i1["exists"]) and not isname and not force
            allw = all(infos[x] and infos[x]["begins"] for x in row["options"])
            allp = all(infos[x] and infos[x]["exists"] for x in row["options"]) if allw else False
            numw = any(infos[x] and (infos[x]["meaning"] or "").lower().strip() in NUMBER_MEANINGS for x in row["options"])
            wish = [i1["pic"]] if (i1 and i1["begins"] and not i1["exists"] and not isname and not force) else []
            if usable and allw and allp and not numw:
                variant, body = "words_pictures", build_full(row, w, infos, S_full, None)
            elif usable:
                variant, body = "letter_with_word", build_letter(row, w, True, i1, LT[sk])
            else:
                if force:
                    NO_WORD_REASON[(w, L)] = "English X is taught letter-only (Xylophone's first sound is z)."
                elif not i1 or not i1["word"]:
                    NO_WORD_REASON[(w, L)] = "the source has no picture word for this letter"
                elif isname:
                    NO_WORD_REASON[(w, L)] = "the source word '%s' is a person's name and has no picture" % i1["word"]
                elif i1["begins"] and not i1["exists"]:
                    NO_WORD_REASON[(w, L)] = "the source word '%s' has no picture file yet (wished-for file listed in assets_missing); the plan works without it" % i1["word"]
                else:
                    NO_WORD_REASON[(w, L)] = "the source word '%s' does not begin with exactly this letter (it begins with the letter plus a vowel sign, or is the letter itself), so no 'begins with' claim is made" % i1["word"]
                variant, body = "letter_only", build_letter(row, w, False, i1, LT[sk])
            tiers[lid] = variant
            # assets
            used = set()

            def collect(v):
                if isinstance(v, dict) and v.get("type") in ("picture", "letterWord"):
                    used.add(v["asset"])
            for s in body["introduce"] + body["demonstrate"] + body["remediation"]["explain"]:
                collect(s["visual"])
            for q in body["guided"] + body["practice"] + body["check"] + body["remediation"]["guided"] + body["remediation"]["check"]:
                collect(q["visual"])
                for p in q.get("optionPictures", {}).values():
                    used.add(p)
            missing = sorted(a for a in used if not os.path.isfile(os.path.join(ROOT, a.replace("/", os.sep))))
            obj = row["objective"]
            if w != "english":
                gloss = {"telugu": "Telugu", "hindi": "Hindi", "tamil": "Tamil"}[w]
                obj += " (Recognise the %s letter %s.)" % (gloss, L)
            else:
                obj += ", uppercase %s and lowercase %s." % (L, L.lower())
            les = dict(lesson_id=lid, world=w, level=1, locale=row["locale"], title=row["title"], objective=obj,
                       prerequisites=row["prerequisites"], variant=variant, mastery=dict(MASTERY))
            les.update(body)
            notes = list(COMMON_NOTES)
            notes.append(VARIANT_NOTE[variant])
            assert not missing, (lid, missing)  # no step or question may reference a non-existent file
            les["review"] = dict(native_review_needed=True,
                                 items_to_review=review_for(w, row, variant, infos, wish),
                                 assets_missing=list(wish), notes=notes)
            if wish:
                les["review"]["notes"].append(
                    "assets_missing is a WISH list, not a dependency: %s does not exist (proposed name following the existing file naming); no step or question references it and the plan works without it." % ", ".join(wish))
            if numw and variant == "letter_with_word":
                les["review"]["notes"].append("One of the three source picture words is a number picture (counted objects); name-the-picture items are therefore not used in this lesson and the picture appears only in teaching steps with its caption.")
            lessons.append(les)
    return lessons, skipped, tiers


COMMON_NOTES = [
    "ID, title, level, prerequisites and locale are copied from the existing recognition lesson in lib/src/curriculum.dart; the existing one-question lesson (letter spoken, three letters as options) is unchanged.",
    "GUESS RATE: every check and remediation-check item has exactly 3 options and no hints (blind guess 33%; passing 2 of 3 by guessing alone about 26%). Guided and practice not-letter / not-word items have 2 options (as in the pilot); they are never used in a check because with three options two would be right.",
    "Pass marks, cycle limit and the 'needs support' rule are data fields (mastery); after the limit the UI offers parent support and lets the child continue.",
    "No tracing and no stroke order is taught anywhere.",
    "Audio-only items (visual none) need a replay button and a visual fallback if text-to-speech fails (UI decision).",
    "LIMITATION: the source gives each lesson only its own letter, two neighbouring letters and (sometimes) a picture word. Variety inside a lesson is therefore limited: items differ by task, wording, option set and answer position, but a child can still learn the small option sets by memory. More human-approved letters and picture words are needed to widen the check.",
]
VARIANT_NOTE = {
    "words_pictures": "VARIANT words_pictures: the approved pilot template (3 picture words that each begin with their letter, all 3 pictures exist). Demonstrate has 6 steps (the puzzle is shown with both pictures it talks about). Letter options come from a widened pool of earlier letters. Check = hear-word-to-letter, find the word, name the picture (no caption); remediation = sound-first explanation plus the 'which word does NOT begin' puzzle and alternate items.",
    "letter_with_word": "VARIANT letter_with_word: the letter has one picture word that begins with it, but the other two option letters have no usable word or no picture file, so the pick-the-word and name-the-picture tasks are NOT used. Word is used in teaching steps and in heard-word-to-letter items (audio, so a missing picture never leaks the answer). Wrong letters come from the lesson's own two options plus letters taught earlier; practice item 6 and check item 3 are spaced reviews of the previous letter (field purpose).",
    "letter_only": "VARIANT letter_only: no usable picture word. Tasks: look-and-match (guided), listen-and-pick, and the 'which letter is NOT ...' puzzle (guided/practice only). Wrong letters come from the lesson's own two options plus letters taught earlier (nearest first); no (answer, option set) repeats in the lesson; practice item 6 and check item 3 are spaced reviews of the previous letter (field purpose). Check = hear-letter, hear-the-sound wording, previous-letter review.",
}


# ---------------------------------------------------------------- spec document
def vis_text(v):
    t = v["type"]
    if t == "none":
        return "nothing shown"
    if t == "glyph":
        return "big letter(s) %s" % v["glyph"]
    if t == "picture":
        return "picture %s%s" % (os.path.basename(v["asset"]), (" captioned " + v["caption"]) if v["caption"] else " (no caption)")
    if t == "letterWord":
        return "letter %s + word %s + picture %s" % (v["glyph"], v["word"], os.path.basename(v["asset"]))
    return str(v)


def allq(les):
    return les["guided"] + les["practice"] + les["check"] + les["remediation"]["guided"] + les["remediation"]["check"]


def render_example(les, out):
    w = out.append
    w("**%s** (%s, variant `%s`, prerequisite %s)\n" % (les["lesson_id"], les["world"], les["variant"], ", ".join(les["prerequisites"]) or "none"))
    w("Objective: %s\n" % les["objective"])
    for title, lst in (("1. Introduce", les["introduce"]), ("2. Demonstrate", les["demonstrate"]),
                       ("6. Remediation explain (only after a failed check)", les["remediation"]["explain"])):
        w("*%s*\n" % title)
        for s in lst:
            w("- `%s` [%s] \"%s\"" % (s["id"], vis_text(s["visual"]), s["text"]))
        w("")
    w("*3-5, 7. Questions* (guided = 2 hints, may reveal on hint 2; practice = 2 hints that never reveal; check = no hints)\n")
    w("| id | task | visual | prompt | options | answer | hints |\n|---|---|---|---|---|---|---|")
    for q in allq(les):
        w("| %s | %s | %s | %s | %s | **%s** | %d |" % (q["id"], q["task"], vis_text(q["visual"]), q["prompt"], " / ".join(q["options"]), q["answer"], len(q["hints"])))
    w("")


def write_md(lessons, skipped, tiers):
    out = []
    w = out.append
    by = {}
    for l in lessons:
        by.setdefault(l["world"], []).append(l)
    w("# ROLLOUT R2 - Level 1 letter-recognition teaching plans (content-creator)\n")
    w("STATUS: rollout_unverified. Written by content-creator; NOT approved by anyone. Nothing here is native-speaker-verified, educator-verified, audio-verified or UI-verified. It must go to content-verifier.\n")
    w("Files: plans `content/teaching_pending/rollout_letters.json` (NOT promoted to content/teaching/ until the content-verifier passes it) (schema_version 1, status `rollout_unverified`); generator `tool/gen_teaching_letters.py`; checker `tool/check_rollout_letters.py`; field meanings `content/teaching/SCHEMA.md` (two additions below). Source data read, never modified: `lib/src/curriculum.dart` (recognition sequences) and `lib/src/alphabet/alphabet_data.dart` (picture words).\n")
    w("## 1. What the source really contains\n")
    w("Each existing recognition lesson (except the four pilot ones) is one question: the letter is spoken, the child picks it from three letters (the letter and the next two in the sequence). It has no picture words of its own. Picture words exist only in `alphabet_data.dart` and only for some letters: English 26 of 26, Telugu 14 of 51, Hindi 14 of 46, Tamil 16 of 30 (3 Telugu and 4 Tamil source words do not begin with exactly the lesson letter, see section 6; the English word for Q has no picture file named in the table). The plans use that table for the letter's word. Where it has none, the plan teaches the letter alone.\n")
    w("## 2. The three templates, in plain language\n")
    w("All three keep the pilot order: introduce -> demonstrate -> guided (hint ladder, retry, no penalty) -> practice (5, two hints that never reveal) -> check (3 new items, 3 options, no hints, pass 2 of 3) -> remediation only after a failed check (different, sound-first explanation, 2 guided items, 3 alternate check items; at most 2 cycles; then 'needs support' and the child continues). Pass marks are data fields.\n")
    w("**A. words_pictures** (the approved pilot template, filled in per letter): used when the letter and BOTH its option letters have a picture word that begins with them AND all three picture files exist. Introduce: letter, then letter+word+picture. Demonstrate: the letter, the word begins with it, two other words do not, the 'which does NOT begin' puzzle. Guided: pick the word, pick/match the letter (English: big letter for a small one), the NOT puzzle. Practice: picture to letter, name the picture, hear a word and pick the picture, hear the letter and pick the word, the NOT puzzle. Check (no caption, no glyph equal to the answer): hear a word and pick its first letter (English: the SMALL letter), find the word from the letter, name a captionless picture. Remediation: close your eyes and listen to the first sound, a different word that does not start with it, then the shape; extra items are the NOT puzzle, hear-a-word, and a different check.\n")
    w("**B. letter_with_word**: the letter has a picture word that begins with it, but the other two letters do not (or a picture file is missing). Pick-the-word and name-the-picture tasks are NOT used (two wrong words are not available / a missing picture would print its own label). The word is used in teaching steps and in heard-word-to-letter items (audio only, so a missing picture can never leak the answer). Demonstrate: letter, word begins with it, two different letters, the 'which one is the letter' puzzle. Guided: look-and-match, listen-and-pick, 'which letter is NOT the big letter'. Practice: listen-and-pick (different wording and option sets), heard-word-to-letter, the NOT puzzle (English adds big-letter to small-letter). Check: heard-word-to-letter, two listen-and-pick items. Remediation: close your eyes, say it softly; look at the shape beside a different letter; say the word and hear its first sound.\n")
    w("**C. letter_only**: no usable word (none in the source, or the word does not begin with exactly the letter - e.g. a Tamil pure consonant or a letter plus a vowel sign - so no 'begins with' claim is made, or English X by decision). Same as B without the word items: every question is look-and-match (guided only), listen-and-pick, or the NOT puzzle (guided/practice/remediation-guided only, never in a check).\n")
    w("Wrong letters (decision RR-2): each letter question draws its two wrong options from the lesson's own two options plus letters taught earlier (the 5 nearest earlier letters; for the first lessons the next letters of the alphabet fill the pool to 7). No (answer, option set) is used twice in a lesson, so check and remediation-check option sets are new. Practice item 6 and check item 3 are spaced reviews whose answer is the PREVIOUS letter (the prerequisite), marked with the field `purpose: spaced_review_previous_letter`. Check tasks vary: heard letter, heard-sound wording, heard word (B), previous-letter review. words_pictures lessons use the same pool for their letter items; their word items still reuse the three picture words (data limit). words_pictures demonstrate has 6 steps so the NOT puzzle shows both pictures (word with letterWord, then the odd word with picture). A lesson with a number picture (counted objects) among its three words is taught as letter_with_word so that picture only appears in teaching steps with its caption. Q (no picture file) and the Tamil name word are letter_only; te-letter-012 uses the existing boat.png.\n")
    w("Schema additions (not yet in SCHEMA.md; the UI does not read `task`): task value `not_letter` (like `not_word` but the options are letters, 2 options, never in a check); lesson field `variant` (`words_pictures` | `letter_with_word` | `letter_only`) and `prerequisites` on every lesson (copied from the source).\n")
    w("## 3. Counts\n")
    w("| language | recognition lessons in source | done in pilot | planned here | words_pictures | letter_with_word | letter_only | with missing picture files |\n|---|---|---|---|---|---|---|---|")
    tot = [0, 0, 0, 0, 0, 0]
    for wd in WORLDS:
        ls = by.get(wd, [])
        n_src = len(REC[wd]["targets"])
        a = sum(1 for x in ls if x["variant"] == "words_pictures")
        b = sum(1 for x in ls if x["variant"] == "letter_with_word")
        c = sum(1 for x in ls if x["variant"] == "letter_only")
        m = sum(1 for x in ls if x["review"]["assets_missing"])
        w("| %s | %d | 1 | %d | %d | %d | %d | %d |" % (LANGNAME[wd], n_src, len(ls), a, b, c, m))
        for i, v in enumerate((n_src, 1, len(ls), a, b, c)):
            tot[i] += v
    w("| **total** | %d | %d | %d | %d | %d | %d | |\n" % tuple(tot))
    w("Each planned lesson has 2 introduce + 5 demonstrate (6 in words_pictures) + 3 guided + 5 practice (6 in letter_with_word/letter_only) + 3 check + (3 explain, 2 guided, 3 check) remediation steps/questions.\n")
    w("## 4. One worked example per language\n")
    ex = {"english": "en-letter-002", "telugu": None, "hindi": None, "tamil": None}
    for wd in ("telugu", "hindi", "tamil"):
        pref = ["letter_with_word", "words_pictures", "letter_only"]
        cand = [x for x in by.get(wd, []) if x["variant"] == "letter_with_word"] or by.get(wd, [])
        ex[wd] = cand[0]["lesson_id"]
    lookup = {x["lesson_id"]: x for x in lessons}
    for wd in WORLDS:
        w("### %s\n" % LANGNAME[wd])
        render_example(lookup[ex[wd]], out)
    # one letter_only example too
    lo = [x for x in lessons if x["variant"] == "letter_only"]
    if lo:
        w("### Extra: a letter_only example (%s)\n" % LANGNAME[lo[0]["world"]])
        render_example(lo[0], out)
    w("## 5. Skipped (not planned here) and why\n")
    for lid, why in skipped:
        w("- `%s`: %s" % (lid, why))
    w("")
    w("## 6. Letters that fell to a weaker template (so no 'begins with' claim)\n")
    for wd in WORLDS:
        rows = []
        for l in by.get(wd, []):
            if l["variant"] == "letter_only":
                rows.append(l)
        if rows:
            w("- %s (%d letter_only): %s" % (LANGNAME[wd], len(rows), ", ".join("%s" % r["lesson_id"].split("-")[-1] if False else r["lesson_id"] for r in rows)))
    w("")
    w("Source words that do NOT begin with exactly their letter (not used for any 'begins with' claim):\n")
    for wd in WORLDS:
        for lt, x in ALPHA[wd].items():
            if x["word"] and not begins_exact(x["word"], lt):
                w("- %s: letter %s, source word %s (%s)" % (LANGNAME[wd], lt, x["word"], x["meaning"]))
    w("")
    w("## 7. UNVERIFIED / to review (applies to every plan)\n")
    for t in [
        "Every Telugu, Hindi and Tamil sentence is AI-written and not checked by a native speaker (grammar, naturalness, register, age suitability); native_review_needed is true on all %d plans, English included (educator review)." % len(lessons),
        "Text-to-speech was not heard: how a bare letter is spoken (name vs sound), anusvara/visarga letters, Tamil pure consonants, rare letters (listed per plan in review.items_to_review).",
        "Content is not educator-verified, not audio-verified, not UI-verified; no UI reads the file yet; the new fields (empty caption, `variant`, `not_letter`) need ui-creator work and ui-verifier checks.",
        "Variety limitation (accepted by the verifier for the pilot, to be judged again for the rollout): with a letter, two neighbours and at most one picture word, check items repeat the same few letters and differ by task, wording, option set and position. letter_only checks are all listen-and-pick; this is a real limit of the source data.",
        "Decision RR-2: wrong letters come from earlier-taught letters (pool of 7) and one spaced-review item each in practice and check; the verifier to judge.",
        "English X is taught letter-only (the source word Xylophone starts with the sound z); educator to decide.",
        "Where a picture word exists in the source but its picture file does not (or no file is named), the plan still uses the word in teaching steps and lists the path in review.assets_missing; some paths are proposed names following the existing file naming, not existing files.",
        "Hindi/Telugu/Tamil prompts such as 'big letter' for the on-screen letter and 'sound of the letter' need confirmation.",
        "Nothing here is approved. Next step: content-verifier.",
    ]:
        w("- " + t)
    os.makedirs(os.path.dirname(OUT_MD), exist_ok=True)
    open(OUT_MD, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")


def skipped_others():
    import csv
    ids = set()
    for wd in WORLDS:
        for r in lesson_rows(wd):
            ids.add(r["id"])
    res = []
    for r in csv.DictReader(open(ROOT + r"\audit\TEACHING_LESSON_AUDIT.csv", encoding="utf-8-sig")):
        if r["world"] in WORLDS and r["kind"] == "quiz" and r["lesson_id"] not in ids:
            lid = r["lesson_id"]
            if "trace" in lid:
                why = "tracing path (the 'all letters' trace lesson), level %s: not letter recognition, no tracing/stroke order is taught" % r["levels"]
            elif "word" in lid:
                why = "word builder lesson, level %s: not plain letter recognition" % r["levels"]
            elif "story" in lid:
                why = "story lesson, level %s: not letter recognition" % r["levels"]
            else:
                why = "not a letter-recognition lesson, level %s" % r["levels"]
            res.append((lid, why))
    return res


def main():
    lessons, skipped, tiers = make_lessons()
    skipped = skipped + skipped_others()
    plan = {"schema_version": 1, "status": "rollout_unverified", "lessons": lessons}
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(plan, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    write_md(lessons, skipped, tiers)
    cnt = {}
    for l in lessons:
        cnt.setdefault(l["world"], {}).setdefault(l["variant"], 0)
        cnt[l["world"]][l["variant"]] += 1
    print("written", len(lessons), "lessons")
    for k, v in cnt.items():
        print(" ", k, v, "total", sum(v.values()))
    print("skipped:", len(skipped))


main()
