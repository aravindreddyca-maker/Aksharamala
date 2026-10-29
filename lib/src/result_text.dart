/// The words on the quest result pop-up, in the language of the quest.
///
/// English quests (and the Number Galaxy maths quests) use English; Tamil,
/// Telugu and Hindi quests use their own language so a child reading that
/// script is not suddenly pushed into English. The exception is the "Back to
/// map" button, which is English everywhere (it is for navigation, and a short
/// familiar label is easier to find than a long translated one).
///
/// NOTE FOR REVIEW: the Tamil, Telugu and Hindi sentences below were written
/// for this app, not taken from the curriculum. They are deliberately short and
/// plain, but a native speaker should read them before release. Keeping them in
/// one file makes that a five-minute job.
library;

enum QuestLanguage { english, tamil, telugu, hindi }

QuestLanguage languageForLocale(String locale) {
  final code = locale.toLowerCase().split(RegExp('[-_]')).first;
  return switch (code) {
    'ta' => QuestLanguage.tamil,
    'te' => QuestLanguage.telugu,
    'hi' => QuestLanguage.hindi,
    _ => QuestLanguage.english,
  };
}

class ResultText {
  const ResultText._({
    required this.language,
    required this.earned,
    required this.earnedOne,
    required this.alreadyCollected,
    required this.courage,
    required this.tryAgain,
    required this.playAgain,
  });

  factory ResultText.forLocale(String locale) =>
      _byLanguage[languageForLocale(locale)]!;

  final QuestLanguage language;

  /// "You earned n stars and completed this quest." (n is 2 or more).
  final String Function(int n) earned;

  /// The same for exactly one star.
  final String earnedOne;

  /// A finished quest that has already paid all of its stars.
  final String alreadyCollected;

  /// A mistake that still earned the courage star.
  final String courage;

  /// A mistake that earned nothing (the quest has already paid out).
  final String tryAgain;

  final String playAgain;

  /// English in every language, by design (see the note at the top).
  String get backToMap => 'Back to map';

  /// The sentence for a result. [gained] is what was really paid.
  String message({required bool correct, required int gained}) {
    if (correct) {
      if (gained <= 0) return alreadyCollected;
      return gained == 1 ? earnedOne : earned(gained);
    }
    return gained <= 0 ? tryAgain : courage;
  }
}

final _byLanguage = <QuestLanguage, ResultText>{
  QuestLanguage.english: ResultText._(
    language: QuestLanguage.english,
    earned: (n) => 'You earned $n stars and completed this quest.',
    earnedOne: 'You earned 1 star and completed this quest.',
    alreadyCollected:
        'You already collected every star in this quest. Great practice!',
    courage: 'You earned a courage star. Try the quest again to master it!',
    tryAgain: 'Not quite. Look at the pictures and try again!',
    playAgain: 'Play again',
  ),
  QuestLanguage.tamil: ResultText._(
    language: QuestLanguage.tamil,
    earned: (n) =>
        'உங்களுக்கு $n நட்சத்திரங்கள் கிடைத்தன! இந்தப் பாடம் முடிந்தது.',
    earnedOne: 'உங்களுக்கு 1 நட்சத்திரம் கிடைத்தது! இந்தப் பாடம் முடிந்தது.',
    alreadyCollected:
        'இந்தப் பாடத்தின் எல்லா நட்சத்திரங்களையும் ஏற்கனவே பெற்றுவிட்டீர்கள். சிறந்த பயிற்சி!',
    courage:
        'உங்களுக்கு ஒரு தைரிய நட்சத்திரம் கிடைத்தது. மீண்டும் விளையாடி இன்னும் நன்றாகச் செய்யுங்கள்!',
    tryAgain: 'சரியில்லை. படங்களைப் பார்த்து மீண்டும் முயற்சி செய்யுங்கள்!',
    playAgain: 'மீண்டும் விளையாடு',
  ),
  QuestLanguage.telugu: ResultText._(
    language: QuestLanguage.telugu,
    earned: (n) => 'మీకు $n నక్షత్రాలు వచ్చాయి! ఈ పాఠం పూర్తయింది.',
    earnedOne: 'మీకు 1 నక్షత్రం వచ్చింది! ఈ పాఠం పూర్తయింది.',
    alreadyCollected:
        'ఈ పాఠంలోని నక్షత్రాలన్నీ మీరు ఇప్పటికే సంపాదించారు. చక్కని సాధన!',
    courage: 'మీకు ఒక ధైర్య నక్షత్రం వచ్చింది. మళ్లీ ఆడి మరింత బాగా చేయండి!',
    tryAgain: 'సరిగ్గా లేదు. బొమ్మలను చూసి మళ్లీ ప్రయత్నించండి!',
    playAgain: 'మళ్లీ ఆడండి',
  ),
  QuestLanguage.hindi: ResultText._(
    language: QuestLanguage.hindi,
    earned: (n) => 'आपको $n सितारे मिले! यह पाठ पूरा हुआ।',
    earnedOne: 'आपको 1 सितारा मिला! यह पाठ पूरा हुआ।',
    alreadyCollected:
        'इस पाठ के सारे सितारे आप पहले ही जीत चुके हैं। बहुत बढ़िया अभ्यास!',
    courage: 'आपको एक हिम्मत का सितारा मिला। इसे फिर से खेलकर और अच्छा करें!',
    tryAgain: 'ठीक नहीं। तस्वीरें देखिए और फिर कोशिश कीजिए!',
    playAgain: 'फिर खेलें',
  ),
};
