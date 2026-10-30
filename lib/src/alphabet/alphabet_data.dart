/// Every letter a child learns from scratch, in teaching order, per language.
///
/// Letters come from the curriculum pack's recognition lists (English is put
/// in A to Z order). Where the pack has a picture word for a letter, it is
/// listed here so the letter is learned with a word; letters with no natural
/// word are shown on their own rather than forcing one. A test checks every
/// list against the pack.
library;

class AlphabetLetter {
  const AlphabetLetter(this.glyph, {this.word, this.meaning, this.picture});

  final String glyph;

  /// A picture word from the pack that starts with this letter.
  final String? word;

  /// English meaning of [word], for the parent / teacher.
  final String? meaning;

  /// A bundled picture for [word], when one exists.
  final String? picture;

  /// What the Listen button says.
  String get speech => word == null ? glyph : '$glyph. $word.';
}

class AlphabetSet {
  const AlphabetSet({
    required this.worldId,
    required this.locale,
    required this.title,
    required this.letters,
  });

  final String worldId;
  final String locale;

  /// Shown on the button and the page, in the language's own script where the
  /// app already does so.
  final String title;
  final List<AlphabetLetter> letters;

  /// The id saved when letter [index] has been traced. Kept to the app's
  /// existing "finished lesson" list; no new save format.
  String lessonId(int index) =>
      'alpha-$worldId-${(index + 1).toString().padLeft(3, '0')}';
}

const _q = 'assets/images/quiz/';

const englishAlphabet = AlphabetSet(
  worldId: 'english',
  locale: 'en-US',
  title: 'ABC',
  letters: [
    AlphabetLetter('A',
        word: 'Apple', meaning: 'apple', picture: '${_q}apple.png'),
    AlphabetLetter('B',
        word: 'Ball', meaning: 'ball', picture: '${_q}ball.png'),
    AlphabetLetter('C', word: 'Cat', meaning: 'cat', picture: '${_q}cat.png'),
    AlphabetLetter('D', word: 'Dog', meaning: 'dog'),
    AlphabetLetter('E', word: 'Egg', meaning: 'egg'),
    AlphabetLetter('F', word: 'Fish', meaning: 'fish'),
    AlphabetLetter('G', word: 'Goat', meaning: 'goat'),
    AlphabetLetter('H', word: 'Hat', meaning: 'hat'),
    AlphabetLetter('I', word: 'Ink', meaning: 'ink'),
    AlphabetLetter('J', word: 'Jam', meaning: 'jam'),
    AlphabetLetter('K',
        word: 'Kite', meaning: 'kite', picture: '${_q}kite.png'),
    AlphabetLetter('L', word: 'Lion', meaning: 'lion'),
    AlphabetLetter('M',
        word: 'Mango', meaning: 'mango', picture: '${_q}mango.png'),
    AlphabetLetter('N', word: 'Nest', meaning: 'nest'),
    AlphabetLetter('O', word: 'Orange', meaning: 'orange'),
    AlphabetLetter('P', word: 'Pen', meaning: 'pen'),
    AlphabetLetter('Q', word: 'Queen', meaning: 'queen'),
    AlphabetLetter('R', word: 'Rabbit', meaning: 'rabbit'),
    AlphabetLetter('S', word: 'Sun', meaning: 'sun'),
    AlphabetLetter('T', word: 'Tree', meaning: 'tree'),
    AlphabetLetter('U', word: 'Umbrella', meaning: 'umbrella'),
    AlphabetLetter('V', word: 'Van', meaning: 'van'),
    AlphabetLetter('W', word: 'Water', meaning: 'water'),
    AlphabetLetter('X', word: 'Xylophone', meaning: 'xylophone'),
    AlphabetLetter('Y', word: 'Yak', meaning: 'yak'),
    AlphabetLetter('Z', word: 'Zebra', meaning: 'zebra'),
  ],
);

const teluguAlphabet = AlphabetSet(
  worldId: 'telugu',
  locale: 'te-IN',
  title: 'అక్షరాలు',
  letters: [
    AlphabetLetter('అ',
        word: 'అమ్మ', meaning: 'mother', picture: '${_q}te_amma.webp'),
    AlphabetLetter('ఆ',
        word: 'ఆవు', meaning: 'cow', picture: '${_q}te_cow.webp'),
    AlphabetLetter('ఇ',
        word: 'ఇల్లు', meaning: 'house', picture: '${_q}te_house.webp'),
    AlphabetLetter('ఈ',
        word: 'ఈగ', meaning: 'fly', picture: '${_q}te_fly.webp'),
    AlphabetLetter('ఉ',
        word: 'ఉడుత', meaning: 'squirrel', picture: '${_q}te_squirrel.webp'),
    AlphabetLetter('ఊ',
        word: 'ఊయల', meaning: 'swing', picture: '${_q}te_swing.webp'),
    AlphabetLetter('ఋ'),
    AlphabetLetter('ఎ'),
    AlphabetLetter('ఏ',
        word: 'ఏనుగు', meaning: 'elephant', picture: '${_q}te_elephant.webp'),
    AlphabetLetter('ఐ',
        word: 'ఐదు', meaning: 'five', picture: '${_q}te_five.webp'),
    AlphabetLetter('ఒ',
        word: 'ఒంటె', meaning: 'camel', picture: '${_q}te_camel.webp'),
    AlphabetLetter('ఓ', word: 'ఓడ', meaning: 'boat'),
    AlphabetLetter('ఔ'),
    AlphabetLetter('అం'),
    AlphabetLetter('అః'),
    AlphabetLetter('క',
        word: 'కలం', meaning: 'pen', picture: '${_q}te_pen.webp'),
    AlphabetLetter('ఖ'),
    AlphabetLetter('గ'),
    AlphabetLetter('ఘ'),
    AlphabetLetter('ఙ'),
    AlphabetLetter('చ', word: 'చిలుక', meaning: 'parrot'),
    AlphabetLetter('ఛ'),
    AlphabetLetter('జ'),
    AlphabetLetter('ఝ'),
    AlphabetLetter('ఞ'),
    AlphabetLetter('ట'),
    AlphabetLetter('ఠ'),
    AlphabetLetter('డ'),
    AlphabetLetter('ఢ'),
    AlphabetLetter('ణ'),
    AlphabetLetter('త'),
    AlphabetLetter('థ'),
    AlphabetLetter('ద'),
    AlphabetLetter('ధ'),
    AlphabetLetter('న'),
    AlphabetLetter('ప',
        word: 'పండు', meaning: 'fruit', picture: '${_q}te_fruit.webp'),
    AlphabetLetter('ఫ'),
    AlphabetLetter('బ',
        word: 'బడి', meaning: 'school', picture: '${_q}te_school.webp'),
    AlphabetLetter('భ'),
    AlphabetLetter('మ'),
    AlphabetLetter('య'),
    AlphabetLetter('ర'),
    AlphabetLetter('ల'),
    AlphabetLetter('వ'),
    AlphabetLetter('శ'),
    AlphabetLetter('ష'),
    AlphabetLetter('స'),
    AlphabetLetter('హ'),
    AlphabetLetter('ళ'),
    AlphabetLetter('క్ష'),
    AlphabetLetter('ఱ'),
  ],
);

const hindiAlphabet = AlphabetSet(
  worldId: 'hindi',
  locale: 'hi-IN',
  title: 'अक्षर',
  letters: [
    AlphabetLetter('अ',
        word: 'अनार',
        meaning: 'pomegranate',
        picture: '${_q}hi_pomegranate.webp'),
    AlphabetLetter('आ', word: 'आम', meaning: 'mango'),
    AlphabetLetter('इ', word: 'इमली', meaning: 'tamarind'),
    AlphabetLetter('ई', word: 'ईख', meaning: 'sugarcane'),
    AlphabetLetter('उ', word: 'उल्लू', meaning: 'owl'),
    AlphabetLetter('ऊ', word: 'ऊन', meaning: 'wool'),
    AlphabetLetter('ऋ', word: 'ऋषि', meaning: 'sage'),
    AlphabetLetter('ए', word: 'एक', meaning: 'one'),
    AlphabetLetter('ऐ', word: 'ऐनक', meaning: 'spectacles'),
    AlphabetLetter('ओ', word: 'ओस', meaning: 'dew'),
    AlphabetLetter('औ', word: 'औरत', meaning: 'woman'),
    AlphabetLetter('अं'),
    AlphabetLetter('अः'),
    AlphabetLetter('क',
        word: 'कमल', meaning: 'lotus', picture: '${_q}hi_lotus.webp'),
    AlphabetLetter('ख'),
    AlphabetLetter('ग'),
    AlphabetLetter('घ',
        word: 'घर', meaning: 'house', picture: '${_q}hi_house.webp'),
    AlphabetLetter('ङ'),
    AlphabetLetter('च'),
    AlphabetLetter('छ'),
    AlphabetLetter('ज'),
    AlphabetLetter('झ'),
    AlphabetLetter('ञ'),
    AlphabetLetter('ट'),
    AlphabetLetter('ठ'),
    AlphabetLetter('ड'),
    AlphabetLetter('ढ'),
    AlphabetLetter('ण'),
    AlphabetLetter('त'),
    AlphabetLetter('थ'),
    AlphabetLetter('द'),
    AlphabetLetter('ध'),
    AlphabetLetter('न'),
    AlphabetLetter('प',
        word: 'पतंग', meaning: 'kite', picture: '${_q}hi_kite_red.webp'),
    AlphabetLetter('फ'),
    AlphabetLetter('ब'),
    AlphabetLetter('भ'),
    AlphabetLetter('म'),
    AlphabetLetter('य'),
    AlphabetLetter('र'),
    AlphabetLetter('ल'),
    AlphabetLetter('व'),
    AlphabetLetter('श'),
    AlphabetLetter('ष'),
    AlphabetLetter('स'),
    AlphabetLetter('ह'),
  ],
);

const tamilAlphabet = AlphabetSet(
  worldId: 'tamil',
  locale: 'ta-IN',
  title: 'எழுத்துகள்',
  letters: [
    AlphabetLetter('அ',
        word: 'அம்மா', meaning: 'mother', picture: '${_q}ta_mother.webp'),
    AlphabetLetter('ஆ', word: 'ஆடு', meaning: 'goat'),
    AlphabetLetter('இ',
        word: 'இலை', meaning: 'leaf', picture: '${_q}ta_leaf.webp'),
    AlphabetLetter('ஈ', word: 'ஈ', meaning: 'fly'),
    AlphabetLetter('உ', word: 'உடை', meaning: 'clothes'),
    AlphabetLetter('ஊ',
        word: 'ஊஞ்சல்', meaning: 'swing', picture: '${_q}ta_swing.webp'),
    AlphabetLetter('எ', word: 'எலி', meaning: 'mouse'),
    AlphabetLetter('ஏ', word: 'ஏணி', meaning: 'ladder'),
    AlphabetLetter('ஐ', word: 'ஐந்து', meaning: 'five'),
    AlphabetLetter('ஒ', word: 'ஒட்டகம்', meaning: 'camel'),
    AlphabetLetter('ஓ', word: 'ஓடை', meaning: 'stream'),
    AlphabetLetter('ஔ', word: 'ஔவை', meaning: 'a name'),
    AlphabetLetter('க்',
        word: 'கல்', meaning: 'stone', picture: '${_q}ta_stone.webp'),
    AlphabetLetter('ங்'),
    AlphabetLetter('ச்'),
    AlphabetLetter('ஞ்'),
    AlphabetLetter('ட்'),
    AlphabetLetter('ண்'),
    AlphabetLetter('த்'),
    AlphabetLetter('ந்', word: 'நாய்', meaning: 'dog'),
    AlphabetLetter('ப்', word: 'பூனை', meaning: 'cat'),
    AlphabetLetter('ம்', word: 'மரம்', meaning: 'tree'),
    AlphabetLetter('ய்'),
    AlphabetLetter('ர்'),
    AlphabetLetter('ல்'),
    AlphabetLetter('வ்'),
    AlphabetLetter('ழ்'),
    AlphabetLetter('ள்'),
    AlphabetLetter('ற்'),
    AlphabetLetter('ன்'),
  ],
);

/// The worlds that teach a script, by world id.
const alphabets = <String, AlphabetSet>{
  'english': englishAlphabet,
  'telugu': teluguAlphabet,
  'hindi': hindiAlphabet,
  'tamil': tamilAlphabet,
};
