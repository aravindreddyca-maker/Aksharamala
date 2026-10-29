/// First batch of lessons built from the curriculum pack (`content/pack_v2`):
/// ten Telugu lessons and Number Galaxy 0-10. Everything else in the pack stays
/// unimported until this batch is tested and approved.
///
/// The pack is not bundled with the app, so the parts of it that these lessons
/// use are written out here. `test/batch/batch_content_test.dart` checks every
/// record id, answer and option list against the pack, so this file cannot
/// drift from it.
///
/// Child-facing Telugu sentences are drafts for a native Telugu educator to
/// approve (see content/reports/ASSET_MANIFEST.md).
library;

import '../models.dart';
import 'batch_lesson.dart';

/// Bundled pictures that already exist, by Telugu word. Any other word is shown
/// as text until its picture is added (listed in the asset manifest).
const teluguWordPictures = <String, String>{
  'అమ్మ': 'assets/images/quiz/te_amma.webp',
  'ఆవు': 'assets/images/quiz/te_cow.webp',
  'ఇల్లు': 'assets/images/quiz/te_house.webp',
  'ఈగ': 'assets/images/quiz/te_fly.webp',
  'ఉడుత': 'assets/images/quiz/te_squirrel.webp',
  'ఊయల': 'assets/images/quiz/te_swing.webp',
  'ఏనుగు': 'assets/images/quiz/te_elephant.webp',
  'ఐదు': 'assets/images/quiz/te_five.webp',
  'ఒంటె': 'assets/images/quiz/te_camel.webp',
  'కలం': 'assets/images/quiz/te_pen.webp',
  'బడి': 'assets/images/quiz/te_school.webp',
  'పండు': 'assets/images/quiz/te_fruit.webp',
};

/// Every Telugu picture word the first batch can show -> (pack vocab record,
/// English meaning). Used for the asset manifest; a test checks it against
/// the pack.
const teluguWords = <String, ({String record, String meaning})>{
  'అమ్మ': (record: 'telugu-vocab-001', meaning: 'mother'),
  'ఆవు': (record: 'telugu-vocab-002', meaning: 'cow'),
  'ఇల్లు': (record: 'telugu-vocab-003', meaning: 'house'),
  'ఈగ': (record: 'telugu-vocab-004', meaning: 'fly'),
  'ఉడుత': (record: 'telugu-vocab-005', meaning: 'squirrel'),
  'ఊయల': (record: 'telugu-vocab-006', meaning: 'swing'),
  'ఏనుగు': (record: 'telugu-vocab-007', meaning: 'elephant'),
  'ఐదు': (record: 'telugu-vocab-008', meaning: 'five'),
  'ఒంటె': (record: 'telugu-vocab-009', meaning: 'camel'),
  'ఓడ': (record: 'telugu-vocab-010', meaning: 'boat'),
  'కలం': (record: 'telugu-vocab-011', meaning: 'pen'),
  'బడి': (record: 'telugu-vocab-012', meaning: 'school'),
  'పండు': (record: 'telugu-vocab-013', meaning: 'fruit'),
  'చిలుక': (record: 'telugu-vocab-014', meaning: 'parrot'),
  'పిల్లి': (record: 'telugu-vocab-015', meaning: 'cat'),
  'కుక్క': (record: 'telugu-vocab-016', meaning: 'dog'),
  'చెట్టు': (record: 'telugu-vocab-017', meaning: 'tree'),
  'పువ్వు': (record: 'telugu-vocab-018', meaning: 'flower'),
};

class _TeluguUnit {
  const _TeluguUnit({
    required this.recogniseNo,
    required this.letter,
    required this.letterOptions,
    this.vocabNo,
    this.word,
    this.wordOptions = const [],
  });

  final int recogniseNo;
  final String letter;
  final List<String> letterOptions;
  final int? vocabNo;
  final String? word;
  final List<String> wordOptions;

  String get recordId => 'telugu-recognise-${_pad(recogniseNo, 3)}';

  /// The pack's guided-tracing record for this letter.
  String get guidedWriteId => 'telugu-trace-${_pad(recogniseNo, 3)}';

  /// The pack's independent-writing record for this letter.
  String get independentWriteId =>
      'telugu-write-v2-${_pad(_teluguIndependentNo[recogniseNo]!, 4)}-independent-writing';
  String? get vocabId =>
      vocabNo == null ? null : 'telugu-vocab-${_pad(vocabNo!, 3)}';
}

String _pad(int n, int width) => n.toString().padLeft(width, '0');

/// Recognise number -> number in the pack's independent-writing record id (the
/// pack numbers its handwriting list in its own order; ఋ sits between).
const _teluguIndependentNo = <int, int>{
  1: 1,
  2: 2,
  3: 3,
  4: 4,
  5: 5,
  6: 6,
  8: 11,
  9: 12,
  10: 13,
  11: 14,
};

/// The ten lessons, in teaching order. ఋ (recognise 007) is left for later:
/// it is rare and the pack has no picture word for it. ఎ has no pack word, so
/// its lesson is letter-only rather than forcing an unsuitable picture.
const _teluguUnits = <_TeluguUnit>[
  _TeluguUnit(
    recogniseNo: 1,
    letter: 'అ',
    letterOptions: ['అ', 'ఇ', 'ఋ'],
    vocabNo: 1,
    word: 'అమ్మ',
    wordOptions: ['అమ్మ', 'ఉడుత', 'ఓడ'],
  ),
  _TeluguUnit(
    recogniseNo: 2,
    letter: 'ఆ',
    letterOptions: ['ఆ', 'ఊ', 'ఐ'],
    vocabNo: 2,
    word: 'ఆవు',
    wordOptions: ['ఆవు', 'ఊయల', 'కలం'],
  ),
  _TeluguUnit(
    recogniseNo: 3,
    letter: 'ఇ',
    letterOptions: ['ఇ', 'ఏ', 'ఔ'],
    vocabNo: 3,
    word: 'ఇల్లు',
    wordOptions: ['ఇల్లు', 'ఏనుగు', 'బడి'],
  ),
  _TeluguUnit(
    recogniseNo: 4,
    letter: 'ఈ',
    letterOptions: ['ఈ', 'ఓ', 'క'],
    vocabNo: 4,
    word: 'ఈగ',
    wordOptions: ['ఈగ', 'ఐదు', 'పండు'],
  ),
  _TeluguUnit(
    recogniseNo: 5,
    letter: 'ఉ',
    letterOptions: ['ఉ', 'అః', 'ఘ'],
    vocabNo: 5,
    word: 'ఉడుత',
    wordOptions: ['ఉడుత', 'ఒంటె', 'చిలుక'],
  ),
  _TeluguUnit(
    recogniseNo: 6,
    letter: 'ఊ',
    letterOptions: ['ఊ', 'గ', 'ఛ'],
    vocabNo: 6,
    word: 'ఊయల',
    wordOptions: ['ఊయల', 'ఓడ', 'పిల్లి'],
  ),
  _TeluguUnit(
    recogniseNo: 8,
    letter: 'ఎ',
    letterOptions: ['ఎ', 'ఝ', 'డ'],
  ),
  _TeluguUnit(
    recogniseNo: 9,
    letter: 'ఏ',
    letterOptions: ['ఏ', 'ఠ', 'త'],
    vocabNo: 7,
    word: 'ఏనుగు',
    wordOptions: ['ఏనుగు', 'కలం', 'కుక్క'],
  ),
  _TeluguUnit(
    recogniseNo: 10,
    letter: 'ఐ',
    letterOptions: ['ఐ', 'ణ', 'ధ'],
    vocabNo: 8,
    word: 'ఐదు',
    wordOptions: ['ఐదు', 'బడి', 'చెట్టు'],
  ),
  _TeluguUnit(
    recogniseNo: 11,
    letter: 'ఒ',
    letterOptions: ['ఒ', 'ద', 'ఫ'],
    vocabNo: 9,
    word: 'ఒంటె',
    wordOptions: ['ఒంటె', 'పండు', 'పువ్వు'],
  ),
];

/// What the screen says around the steps, per language.
class BatchText {
  const BatchText({
    required this.rightMessage,
    required this.tryAgainMessage,
    required this.goodWriting,
    required this.writeAgain,
    required this.strokeHint,
    required this.directionHint,
    required this.orderHint,
    required this.strokesHint,
  });

  final String rightMessage;
  final String tryAgainMessage;
  final String goodWriting;
  final String writeAgain;
  final String strokeHint;
  final String directionHint;
  final String orderHint;
  final String strokesHint;

  static const telugu = BatchText(
    rightMessage: 'శభాష్!',
    tryAgainMessage: 'మళ్ళీ ప్రయత్నించండి',
    goodWriting: 'బాగా వ్రాశారు!',
    writeAgain: 'మళ్ళీ ప్రయత్నించండి',
    strokeHint: 'అక్షరం ఆకారాన్ని అనుసరించండి',
    directionHint: 'ఆకుపచ్చ చుక్క నుండి మొదలుపెట్టండి',
    orderHint: 'సంఖ్యల క్రమంలో గీయండి',
    strokesHint: 'గీతల సంఖ్య సరిపోలేదు',
  );

  static const english = BatchText(
    rightMessage: 'Great!',
    tryAgainMessage: 'Try again',
    goodWriting: 'Well written!',
    writeAgain: 'Try again',
    strokeHint: 'Follow the shape of the number',
    directionHint: 'Start at the green dot',
    orderHint: 'Draw the strokes in number order',
    strokesHint: 'Check how many strokes the number needs',
  );

  static BatchText forLocale(String locale) =>
      locale.startsWith('te') ? telugu : english;
}

// -- Telugu ---------------------------------------------------------------

List<BatchLesson> _buildTelugu() {
  final lessons = <BatchLesson>[];
  for (var i = 0; i < _teluguUnits.length; i++) {
    final u = _teluguUnits[i];
    final hasWord = u.word != null;
    lessons.add(
      BatchLesson(
        id: u.recordId,
        title: '${u.letter} అక్షరం',
        subtitle: 'వినండి • గుర్తించండి • వ్రాయండి',
        kind: LessonKind.alphabet,
        symbol: u.letter,
        locale: 'te-IN',
        ageBand: '3-4',
        prerequisites: i == 0 ? const [] : [_teluguUnits[i - 1].recordId],
        sourceRecords: [
          u.recordId,
          if (hasWord) u.vocabId!,
          u.guidedWriteId,
          u.independentWriteId,
        ],
        steps: [
          BatchStep(
            kind: StepKind.listen,
            prompt: 'అక్షరాన్ని వినండి',
            speech: hasWord ? '${u.letter}. ${u.word}.' : '${u.letter}.',
            glyph: u.letter,
            sourceRecord: u.recordId,
          ),
          BatchStep(
            kind: StepKind.pickLetter,
            prompt: 'ఈ అక్షరం ఏది?',
            speech: 'ఈ అక్షరం ఏది?',
            glyph: u.letter,
            options: u.letterOptions,
            answer: u.letter,
            sourceRecord: u.recordId,
          ),
          if (hasWord)
            BatchStep(
              kind: StepKind.pickWord,
              prompt: '${u.letter} తో మొదలయ్యే పదం ఏది?',
              speech: '${u.letter} తో మొదలయ్యే పదం ఏది?',
              glyph: u.letter,
              options: u.wordOptions,
              answer: u.word!,
              pictures: {
                for (final w in u.wordOptions)
                  if (teluguWordPictures.containsKey(w))
                    w: teluguWordPictures[w]!,
              },
              sourceRecord: u.vocabId,
            ),
          BatchStep(
            kind: StepKind.write,
            prompt: '${u.letter} అక్షరాన్ని వ్రాయండి',
            speech: '${u.letter} అక్షరాన్ని వ్రాయండి',
            glyph: u.letter,
            writeMode: WriteMode.guided,
            sourceRecord: u.guidedWriteId,
          ),
          BatchStep(
            kind: StepKind.write,
            prompt: 'చూడకుండా ${u.letter} వ్రాయండి',
            speech: 'చూడకుండా ${u.letter} వ్రాయండి',
            glyph: u.letter,
            writeMode: WriteMode.independent,
            sourceRecord: u.independentWriteId,
          ),
        ],
      ),
    );
  }
  return lessons;
}

// -- Number Galaxy 0-10 ---------------------------------------------------

const _numberWords = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
];

/// Three different numbers around [n], inside 0-10, always including [n].
List<String> numbersAround(int n) {
  final lo = n == 0 ? 0 : (n == 10 ? 8 : n - 1);
  return [for (var k = lo; k < lo + 3; k++) '$k'];
}

/// Id of the pack record that gives writing practice for number [n].
String numberWriteRecord(int n, WriteMode mode) =>
    'numbers-write-v2-${_pad(n + 1, 4)}-'
    '${mode == WriteMode.guided ? 'guided-tracing' : 'independent-writing'}';

List<BatchLesson> _buildNumbers() {
  final lessons = <BatchLesson>[];
  for (var n = 0; n <= 10; n++) {
    final word = _numberWords[n];
    final countId = 'numbers-count-${_pad(n, 3)}';
    final recogniseId = 'numbers-recognise-${_pad(n, 3)}';
    // Alternate: even numbers ask for the bigger, odd for the smaller.
    final partner = n < 10 ? n + 1 : n - 1;
    final askBigger = n.isEven;
    final compareAnswer =
        askBigger ? (n > partner ? n : partner) : (n < partner ? n : partner);
    lessons.add(
      BatchLesson(
        id: countId,
        title: 'Number $n',
        subtitle: 'Count, compare and write',
        kind: LessonKind.numbers,
        symbol: '$n',
        locale: 'en-IN',
        ageBand: '3-4',
        prerequisites: n == 0 ? const [] : ['numbers-count-${_pad(n - 1, 3)}'],
        sourceRecords: [
          countId,
          recogniseId,
          numberWriteRecord(n, WriteMode.guided),
          numberWriteRecord(n, WriteMode.independent),
        ],
        steps: [
          BatchStep(
            kind: StepKind.listen,
            prompt: 'This is the number $n.',
            speech: '${_capital(word)}. $n.',
            glyph: '$n',
            quantity: n,
            sourceRecord: recogniseId,
          ),
          BatchStep(
            kind: StepKind.pickQuantity,
            prompt: 'Which group has $n ${n == 1 ? 'star' : 'stars'}?',
            speech: 'Which group has $word ${n == 1 ? 'star' : 'stars'}?',
            glyph: '$n',
            options: numbersAround(n),
            answer: '$n',
            sourceRecord: recogniseId,
          ),
          BatchStep(
            kind: StepKind.count,
            prompt: n == 0
                ? 'How many stars are in the box?'
                : 'Tap each star to count. How many stars?',
            speech: n == 0
                ? 'How many stars are in the box?'
                : 'Tap each star to count. How many stars?',
            quantity: n,
            options: numbersAround(n),
            answer: '$n',
            sourceRecord: countId,
          ),
          BatchStep(
            kind: StepKind.compare,
            prompt:
                'Which number is ${askBigger ? 'bigger' : 'smaller'}: $n or $partner?',
            speech:
                'Which number is ${askBigger ? 'bigger' : 'smaller'}: ${_numberWords[n]} or ${_numberWords[partner]}?',
            options: ['$n', '$partner'],
            answer: '$compareAnswer',
            sourceRecord: countId,
          ),
          BatchStep(
            kind: StepKind.write,
            prompt: 'Trace the number $n.',
            speech: 'Trace the number $word.',
            glyph: '$n',
            writeMode: WriteMode.guided,
            sourceRecord: numberWriteRecord(n, WriteMode.guided),
          ),
          BatchStep(
            kind: StepKind.write,
            prompt: 'Now write $n yourself.',
            speech: 'Now write $word yourself.',
            glyph: '$n',
            writeMode: WriteMode.independent,
            sourceRecord: numberWriteRecord(n, WriteMode.independent),
          ),
        ],
      ),
    );
  }
  return lessons;
}

String _capital(String s) => s[0].toUpperCase() + s.substring(1);

// -- Public ---------------------------------------------------------------

/// The ten Telugu lessons.
final List<BatchLesson> teluguBatch = List.unmodifiable(_buildTelugu());

/// Number Galaxy 0 to 10 (eleven lessons).
final List<BatchLesson> numbersBatch = List.unmodifiable(_buildNumbers());

/// World id -> its new lessons.
final Map<String, List<BatchLesson>> batchByWorld = {
  'telugu': teluguBatch,
  'numbers': numbersBatch,
};

/// Every new lesson.
List<BatchLesson> get allBatchLessons => [...teluguBatch, ...numbersBatch];

/// The lesson as the quest map shows it: card picture and label.
const batchQuestArt = <String, String>{
  'telugu-recognise-001': 'assets/images/quiz/te_amma.webp',
  'telugu-recognise-002': 'assets/images/quiz/te_cow.webp',
  'telugu-recognise-003': 'assets/images/quiz/te_house.webp',
  'telugu-recognise-004': 'assets/images/quiz/te_fly.webp',
  'telugu-recognise-005': 'assets/images/quiz/te_squirrel.webp',
  'telugu-recognise-006': 'assets/images/quiz/te_swing.webp',
  'telugu-recognise-009': 'assets/images/quiz/te_elephant.webp',
  'telugu-recognise-010': 'assets/images/quiz/te_five.webp',
  'telugu-recognise-011': 'assets/images/quiz/te_camel.webp',
};

/// Worlds with the new lessons added after their existing quests. Existing
/// quests, their order and their ids are untouched.
List<LearningWorld> worldsWithBatch(List<LearningWorld> base) => [
      for (final w in base)
        batchByWorld.containsKey(w.id)
            ? LearningWorld(
                id: w.id,
                name: w.name,
                emoji: w.emoji,
                assetPath: w.assetPath,
                color: w.color,
                darkColor: w.darkColor,
                description: w.description,
                lessons: [...w.lessons, ...batchByWorld[w.id]!],
              )
            : w,
    ];
