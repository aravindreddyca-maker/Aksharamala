/// Which bundled illustration represents each quest on a world's quest trail.
///
/// This is presentation only: it is keyed by lesson id and never touches the
/// lesson data itself. Every path is checked by a test.
const questArt = <String, String>{
  // English Forest
  'en-a': 'assets/images/quiz/apple.png',
  'en-word': 'assets/images/quiz/cat.png',
  'en-trace': 'assets/images/quiz/te_pen.webp',
  'en-story': 'assets/images/stories/mango.webp',
  // Telugu Kingdom
  'te-a': 'assets/images/quiz/te_amma.webp',
  'te-word': 'assets/images/quiz/te_pen.webp',
  'te-trace': 'assets/images/quiz/te_school.webp',
  'te-story': 'assets/images/stories/parrot.webp',
  // Hindi Valley
  'hi-a': 'assets/images/quiz/hi_pomegranate.webp',
  'hi-word': 'assets/images/quiz/hi_lotus.webp',
  'hi-trace': 'assets/images/quiz/te_pen.webp',
  'hi-story': 'assets/images/stories/kite.webp',
  // Tamil Garden
  'ta-a': 'assets/images/quiz/ta_mother.webp',
  'ta-word': 'assets/images/quiz/ta_flower.webp',
  'ta-trace': 'assets/images/quiz/te_pen.webp',
  'ta-story': 'assets/images/stories/butterfly.webp',
  // Number Galaxy
  'num-count': 'assets/images/rewards/star.png',
  'num-add': 'assets/images/quiz/num_crystal.webp',
  'num-subtract': 'assets/images/quiz/num_moon.webp',
  'num-names': 'assets/images/quiz/num_rocket.webp',
};
