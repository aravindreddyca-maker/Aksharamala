/// What each quest card shows. Presentation only, keyed by lesson id; the
/// lesson data itself is never touched.
///
/// - [questArt]: the bundled picture that matches what the quest teaches.
///   Tracing quests have none: their card draws the letter being traced.
/// - [questLabel]: the letter or word the quest teaches, shown on the picture
///   so the picture and the word are learned together. Every label is text
///   that already appears in the lesson (a test enforces this), so nothing is
///   translated or invented here.
const questArt = <String, String>{
  // English Forest
  'en-a': 'assets/images/quiz/apple.png',
  'en-word': 'assets/images/quiz/cat.png',
  'en-story': 'assets/images/stories/mango.webp',
  // Telugu Kingdom
  'te-a': 'assets/images/quiz/te_amma.webp',
  'te-word': 'assets/images/quiz/te_pen.webp',
  'te-story': 'assets/images/stories/parrot.webp',
  // Hindi Valley
  'hi-a': 'assets/images/quiz/hi_pomegranate.webp',
  'hi-word': 'assets/images/quiz/hi_lotus.webp',
  'hi-story': 'assets/images/stories/kite.webp',
  // Tamil Garden
  'ta-a': 'assets/images/quiz/ta_mother.webp',
  'ta-word': 'assets/images/quiz/ta_flower.webp',
  'ta-story': 'assets/images/stories/butterfly.webp',
  // Number Galaxy
  'num-count': 'assets/images/rewards/star.png',
  'num-add': 'assets/images/quiz/num_crystal.webp',
  'num-subtract': 'assets/images/quiz/num_moon.webp',
  'num-names': 'assets/images/quiz/num_rocket.webp',
};

const questLabel = <String, String>{
  'en-a': 'A a',
  'en-word': 'C A T',
  'te-a': 'అ',
  'te-word': 'కలం',
  'hi-a': 'अ',
  // The lesson shows the word with a missing letter; the label mirrors that.
  'hi-word': 'क _ ल',
  'ta-a': 'அ',
  'ta-word': 'மலர்',
};
