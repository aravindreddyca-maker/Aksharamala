import 'batch_lesson.dart';
import 'level3_support.dart';

BatchLesson _l(
  int n,
  String title,
  String objective,
  String topic,
  String skill,
  String teach,
  List<L3Q> questions,
  List<String> examples,
) =>
    level3Lesson(
      id: 'english-l8-${n.toString().padLeft(3, '0')}',
      module: 'english',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      questions: questions,
      examples: examples,
      ageBand: '10-12',
      level: 8,
    );

const String _village =
    'The village library, once empty, now buzzes each evening: children read and elders tell stories. Yet its books are old, so the panchayat is raising funds.';

/// Level 8 english: 10 lessons (english-l8-001 .. 010), about age 15
/// (`ageBand: '10-12', level: 8`; levels above 5 have no age band of their own).
final List<BatchLesson> englishLevel8Lessons = List.unmodifiable(<BatchLesson>[
  _l(
    1,
    'Literary analysis',
    'Read a short passage closely for device, mood, theme and viewpoint.',
    'Reading',
    'Literary analysis',
    'Look closely: what device is used, what mood it creates, what the details suggest, and what idea lies beneath.',
    const [
      L3Q('The classroom clock ticked like a slow heartbeat. Which device is used in “ticked like a slow heartbeat”?',
          ['metaphor', 'simile', 'alliteration'], 'simile'),
      L3Q(
          'Rohan gripped the railing, his knuckles white, and did not look down at the crowd. What does “knuckles white” suggest?',
          ['He is very proud', 'He is very nervous', 'He is feeling cold'],
          'He is very nervous'),
      L3Q(
          'The old house sat silent at the end of the lane, its windows dark, its garden choked with weeds. What is the mood?',
          ['gloomy and lonely', 'cheerful and busy', 'angry and loud'],
          'gloomy and lonely'),
      L3Q(
          'Asha failed the trial despite daily practice, yet she returned next year and tried again, stronger. Which theme fits?',
          [
            'Winning is everything',
            'Failure should be hidden',
            'Perseverance leads to growth'
          ],
          'Perseverance leads to growth'),
      L3Q('“I could not believe my luck,” I thought as I opened the letter. Which point of view is this?',
          ['Third person', 'First person', 'Second person'], 'First person'),
    ],
    const ['Close reading of a short passage'],
  ),
  _l(
    2,
    'Irony and satire',
    'Tell situational, verbal and dramatic irony, satire and sarcasm apart.',
    'Reading',
    'Irony and satire',
    'Irony is a gap between what is said or expected and what is true. Satire uses humour to criticise foolishness.',
    const [
      L3Q(
          'A fire station is destroyed in a fire. What kind of irony is this?',
          ['Situational irony', 'Verbal irony', 'Dramatic irony'],
          'Situational irony'),
      L3Q('Standing in heavy rain, Ravi said, “What lovely weather for a picnic!” What is this?',
          ['A simile', 'A pun', 'Verbal irony'], 'Verbal irony'),
      L3Q(
          'In a play the audience knows the box holds a snake, but the hero happily opens it. What is this called?',
          ['Verbal irony', 'Dramatic irony', 'Personification'],
          'Dramatic irony'),
      L3Q(
          'A cartoon shows ministers asleep in a meeting while citizens wait outside. Satire like this mainly aims to...',
          [
            'criticise wrongdoing or foolishness',
            'praise the powerful',
            'describe the weather'
          ],
          'criticise wrongdoing or foolishness'),
      L3Q(
          'Which sentence is sarcastic?',
          [
            'I am thankful for your help.',
            'The tea was served hot.',
            'Oh wonderful, you spilt tea on my notes!'
          ],
          'Oh wonderful, you spilt tea on my notes!'),
    ],
    const ['Fire station burns down'],
  ),
  _l(
    3,
    'Synthesising two sources',
    'Combine ideas from two sources into one clear point.',
    'Reading',
    'Synthesis',
    'To synthesise, find what two sources share or where they clash, then combine them into one point of your own.',
    const [
      L3Q(
          'Source A: Schools with gardens report healthier eating. Source B: Gardens teach children where food comes from. What do both show?',
          [
            'Gardens are very expensive',
            'Gardens benefit school children',
            'Children dislike vegetables'
          ],
          'Gardens benefit school children'),
      L3Q(
          'Source A: 70% of Class 9 students sleep under seven hours. Source B: Tired students score lower. Which conclusion combines them?',
          [
            'Everyone sleeps enough',
            'Less sleep may lower marks',
            'Class 9 scores are the highest'
          ],
          'Less sleep may lower marks'),
      L3Q(
          'Source A: The river is clean. Source B: Tests show the river is polluted. How do the sources relate?',
          [
            'They support each other',
            'They are about unrelated topics',
            'They contradict each other'
          ],
          'They contradict each other'),
      L3Q(
          'When you synthesise two sources you should...',
          [
            'combine ideas from both into one point',
            'copy the longer source',
            'use only the one you like'
          ],
          'combine ideas from both into one point'),
      L3Q(
          'Source A: Cycling reduces pollution. Source B: Cycling keeps people fit. Which is the best one-sentence synthesis?',
          [
            'Cycling is only for the fit.',
            'Cycling helps the planet and health.',
            'Cycling makes the air dirty.'
          ],
          'Cycling helps the planet and health.'),
    ],
    const ['Two short sources'],
  ),
  _l(
    4,
    'Rhetorical devices',
    'Spot rhetorical questions, repetition and contrast, and their effect.',
    'Reading',
    'Rhetorical devices',
    'Speakers persuade with rhetorical questions (no answer needed), repetition for emphasis, and contrast to stress a point.',
    const [
      L3Q(
          '“Who among us does not want a safer road?” Which device is this?',
          ['a simile', 'a rhetorical question', 'a statistic'],
          'a rhetorical question'),
      L3Q('The speaker says, “We will study, we will work, we will win.” Which device is used?',
          ['irony', 'a pun', 'repetition'], 'repetition'),
      L3Q(
          '“Not words but deeds; not promises but progress.” What is the effect of the contrast?',
          [
            'It stresses action over talk',
            'It confuses the reader',
            'It describes a place'
          ],
          'It stresses action over talk'),
      L3Q(
          'Why does a speaker use a rhetorical question?',
          [
            'To ask for a real answer',
            'To make listeners think',
            'To end the speech'
          ],
          'To make listeners think'),
      L3Q(
          '“Our rivers are dying, dying, dying.” What does the repeated word create?',
          ['Humour', 'A rhyme', 'Emphasis and urgency'],
          'Emphasis and urgency'),
    ],
    const ['Speech devices'],
  ),
  _l(
    5,
    'Parallel structure and grammar',
    'Keep list items in the same form and use advanced grammar correctly.',
    'Grammar',
    'Parallel structure',
    'In a list, keep the same form: reading, writing, singing. Use who for people, a semicolon between linked sentences.',
    const [
      L3Q(
          'Which sentence uses parallel structure?',
          [
            'She likes reading, writing and to sing.',
            'She likes reading, writing and singing.',
            'She likes to read, writing and sing.'
          ],
          'She likes reading, writing and singing.'),
      L3Q('Complete: Neither of the boys ____ ready.', ['are', 'were', 'is'],
          'is'),
      L3Q(
          'Which sentence uses a semicolon correctly?',
          [
            'The bell rang; the class went silent.',
            'The bell; rang the class went silent.',
            'The bell rang the class; went silent.'
          ],
          'The bell rang; the class went silent.'),
      L3Q(
          'Which sentence is in the passive voice?',
          [
            'The ball broke the window.',
            'The ball hit the window hard.',
            'The window was broken by the ball.'
          ],
          'The window was broken by the ball.'),
      L3Q('Complete: The girl ____ won the race is my cousin.',
          ['whom', 'which', 'who'], 'who'),
    ],
    const ['reading, writing and singing'],
  ),
  _l(
    6,
    'Precis choice',
    'Choose the shortest accurate summary of a passage.',
    'Writing',
    'Precis',
    'A precis keeps the main point in about one-third of the words, in your own words, with no examples or opinions.',
    const [
      L3Q(
          'Millions of Indians now use digital payments for shopping, bills and fares. This reduces queues and cash handling, though some villages lack good networks. Best precis?',
          [
            'Digital payments are popular, yet uneven.',
            'Villages have no networks at all.',
            'Queues have vanished from India.'
          ],
          'Digital payments are popular, yet uneven.'),
      L3Q(
          'A precis should be about how long compared with the original?',
          [
            'The same length',
            'One-third of the original',
            'Twice the original'
          ],
          'One-third of the original'),
      L3Q(
          'Which should be left out of a precis?',
          [
            'The main argument',
            'The key conclusion',
            'Examples and repeated details'
          ],
          'Examples and repeated details'),
      L3Q('A precis of someone else’s text is usually in which person?',
          ['Third person', 'First person', 'Second person'], 'Third person'),
      L3Q(
          'Sports teach teamwork. Players learn to share, lose gracefully and trust others. These habits help later in jobs and family life. Best precis?',
          [
            'Players must always win.',
            'Jobs are the same as sports.',
            'Sports build habits useful for life.'
          ],
          'Sports build habits useful for life.'),
    ],
    const ['Summary in a third of the words'],
  ),
  _l(
    7,
    'Formal letters and reports',
    'Use the right layout, opening, closing and tone.',
    'Writing',
    'Formal writing',
    'A formal letter has sender address, date, receiver, salutation, subject, body and closing, in a polite tone.',
    const [
      L3Q(
          'Which is the correct opening of a formal letter to a principal?',
          ['Hey Principal!', 'Respected Madam,', 'Hi there,'],
          'Respected Madam,'),
      L3Q(
          'A letter begins “Respected Madam”. Which closing fits?',
          ['See you soon,', 'Your buddy,', 'Yours faithfully,'],
          'Yours faithfully,'),
      L3Q(
          'Which sentence has the right tone for a complaint letter?',
          [
            'I request you to repair the broken fans.',
            'Fix the fans now, or else!',
            'The fans are totally useless lol.'
          ],
          'I request you to repair the broken fans.'),
      L3Q(
          'In a formal letter, where does the subject line go?',
          [
            'After the signature',
            'After the salutation',
            'Before the sender’s address'
          ],
          'After the salutation'),
      L3Q(
          'A report on an event that has already taken place is mostly written in...',
          [
            'Present tense, slang',
            'Future tense, jokes',
            'Past tense, formal language'
          ],
          'Past tense, formal language'),
    ],
    const ['Letter to the principal'],
  ),
  _l(
    8,
    'Evaluating evidence',
    'Judge whether evidence is reliable, enough and relevant.',
    'Reading',
    'Evaluating evidence',
    'Good evidence is specific, from a reliable source, and enough in number. An opinion or a rumour is not evidence.',
    const [
      L3Q(
          'Which is the strongest evidence that a canteen’s meals are unhealthy?',
          [
            'My friend dislikes the canteen',
            'A lab test of the meals',
            'Someone said it looked dirty'
          ],
          'A lab test of the meals'),
      L3Q(
          'An advert says “9 out of 10 users agree!” but does not say how many were asked. What is the weakness?',
          [
            'The advert is too short',
            'The paste is too cheap',
            'The sample size is not stated'
          ],
          'The sample size is not stated'),
      L3Q(
          'Which source is most reliable for facts about the monsoon?',
          [
            'The India Meteorological Department',
            'A rumour on a chat group',
            'An unsigned blog post'
          ],
          'The India Meteorological Department'),
      L3Q(
          'Ravi says, “Two of my friends failed after tuition, so tuition is useless.” What is wrong?',
          [
            'Friends never lie',
            'Tuition is always useful',
            'Two cases are too few to prove it'
          ],
          'Two cases are too few to prove it'),
      L3Q(
          'Which is an opinion, not evidence?',
          [
            'Our school won 12 of 15 matches.',
            'Cricket is the best game.',
            'The pitch is 22 yards long.'
          ],
          'Cricket is the best game.'),
    ],
    const ['Evidence and opinion'],
  ),
  _l(
    9,
    'Reading media critically',
    'Question a headline, a source and a purpose.',
    'Media',
    'Media literacy',
    'Ask of any media: who made it, why, and how do they know? Headlines may exaggerate; adverts aim to persuade.',
    const [
      L3Q(
          'Headline: “SHOCKING! Exam stress ruins every student!” What is wrong with it?',
          [
            'It exaggerates to grab attention',
            'It gives too many facts',
            'It is too short'
          ],
          'It exaggerates to grab attention'),
      L3Q(
          'Why should you check the source of a news item?',
          [
            'To count its words',
            'To see its font',
            'To judge if it is trustworthy'
          ],
          'To judge if it is trustworthy'),
      L3Q(
          'An advertisement for a soft drink shows happy athletes. Its main purpose is to...',
          ['teach science', 'persuade people to buy', 'report news'],
          'persuade people to buy'),
      L3Q('A news story gives both sides of a dispute, with quotes from each. This shows...',
          ['bias', 'advertising', 'balanced reporting'], 'balanced reporting'),
      L3Q(
          'A forwarded message says “Share this with 10 people or face bad luck” and names no source. What should you do?',
          [
            'Forward it at once',
            'Check it before sharing',
            'Believe it because it is urgent'
          ],
          'Check it before sharing'),
    ],
    const ['Headline, source, purpose'],
  ),
  _l(
    10,
    'Integrated passage',
    'Answer mixed questions on one passage.',
    'Reading',
    'Reading review',
    'Read the passage twice. Decide the main idea, check word meanings in context, then test each answer against the text.',
    const [
      L3Q(
          '$_village Main idea?',
          [
            'The panchayat closed the library',
            'Children dislike reading',
            'A revived library still needs new books'
          ],
          'A revived library still needs new books'),
      L3Q(
          '$_village In the passage, “buzzes” means...',
          ['is full of lively activity', 'makes a bee sound', 'is closed'],
          'is full of lively activity'),
      L3Q(
          '$_village What does “Yet” signal?',
          [
            'A cause of the good news',
            'A repeat of the point',
            'A turn to a problem'
          ],
          'A turn to a problem'),
      L3Q(
          '$_village What can we infer?',
          [
            'No one visits it now',
            'The library is valued by the village',
            'The books are all new'
          ],
          'The library is valued by the village'),
      L3Q('$_village Which device appears in “once empty, now buzzes”?',
          ['Contrast', 'Rhetorical question', 'Repetition'], 'Contrast'),
    ],
    const ['Unseen passage'],
  ),
]);
