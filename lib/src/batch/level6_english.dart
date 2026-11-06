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
  String example,
) =>
    level3Lesson(
      id: 'english-l6-${n.toString().padLeft(3, '0')}',
      module: 'english',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      questions: questions,
      examples: [example],
      ageBand: '10-12',
      level: 6,
    );

/// A question whose answer sits at [pos] among three options.
L3Q _q(String prompt, String answer, List<String> wrong, int pos) {
  final options = List<String>.from(wrong)..insert(pos, answer);
  return L3Q(prompt, options, answer);
}

/// Level 6 english: 10 lessons (english-l6-001 .. 010), about age 13.
/// Every item is hand-written; test/level6_english_test.dart checks the
/// structure, option lengths and that no answer appears inside its prompt.
final List<BatchLesson> englishLevel6Lessons = List.unmodifiable(<BatchLesson>[
  _l(
    1,
    'Theme of a short text',
    'Find the message a short text is really teaching.',
    'Reading',
    'Theme',
    'A theme is the lesson or message of a text, not just its topic. Ask: what does the author want me to learn?',
    [
      _q(
          'Ravi lost every race at first, but he practised each morning. At last he won a small medal and smiled at his mother. What is the theme?',
          'Hard work and patience bring success',
          ['Only fast children should race', 'Mothers should watch every race'],
          0),
      _q(
          'A thirsty crow found a jug with little water. She dropped pebbles in until the water rose, and then she drank. What is the theme?',
          'Clever thinking solves problems',
          ['Crows are always thirsty', 'Pebbles are better than water'],
          2),
      _q(
          'What is the difference between a topic and a theme?',
          'A topic is the subject; a theme is the lesson',
          [
            'A theme is the title of the text',
            'A topic is always one word long'
          ],
          1),
      _q(
          'Asha shared her tiffin with a new girl who had none. Soon the two became best friends. What is the theme?',
          'Kindness can build friendship',
          ['Tiffin boxes should be big', 'New students are always shy'],
          1),
      _q(
          'Kiran often lied for fun. One day he really needed help, but nobody believed him. What lesson does the story teach?',
          "Liars lose people's trust",
          ['Nobody should ask for help', 'Fun is bad for children'],
          0),
    ],
    'Theme versus topic',
  ),
  _l(
    2,
    'Tone and mood',
    "Tell the writer's tone from the mood a text creates.",
    'Reading',
    'Tone and mood',
    "Tone is the writer's attitude. Mood is the feeling the text gives the reader. Word choice shows both.",
    [
      _q('The old house creaked, and a cold wind howled through the dark, empty halls. What is the mood?',
          'Eerie and scary', ['Cheerful and bright', 'Calm and sleepy'], 2),
      _q('Wow! What a fantastic day! We won the cup, and the whole school is cheering! What is the tone?',
          'Excited', ['Gloomy', 'Bored'], 0),
      _q(
          'Which sentence has a polite, respectful tone?',
          'Sir, may I please borrow your pen?',
          ['Give me your pen now.', 'Hey, pen, quick!'],
          1),
      _q("'I have told you a hundred times, and you still forget!' sighed Mother. What is her tone?",
          'Annoyed', ['Joyful', 'Playful'], 2),
      _q(
          'What is the difference between tone and mood?',
          "Tone = attitude; mood = reader's feeling",
          [
            "Tone = reader's feeling; mood = attitude",
            'They mean exactly the same thing'
          ],
          0),
    ],
    'Word choice sets the mood',
  ),
  _l(
    3,
    'Point of view',
    'Tell first-person from third-person narration.',
    'Reading',
    'Point of view',
    'First person uses I or we. Third person uses he, she or they. The narrator decides what the reader can know.',
    [
      _q("'I ran to the gate and saw my brother waving.' Which point of view is this?",
          'First person', ['Second person', 'Third person'], 1),
      _q("'Meena opened the box. She gasped at the shiny watch.' Which point of view is this?",
          'Third person', ['First person', 'Second person'], 2),
      _q('Which pronouns show a first-person narrator?', 'I, me, my, we',
          ['he, she, they', 'you, your, yours'], 0),
      _q(
          "Change this to third person, about Ravi: 'I lost my bag in the market.'",
          'Ravi lost his bag in the market.',
          ['Ravi lost my bag in the market.', 'I lost his bag in the market.'],
          1),
      _q(
          'Why might an author choose a first-person narrator?',
          "To show the narrator's own thoughts",
          ['To avoid using any pronouns', 'To list every rule of grammar'],
          2),
    ],
    'I versus she',
  ),
  _l(
    4,
    'Roots and affixes',
    'Use Latin and Greek word parts to work out meanings.',
    'Vocabulary',
    'Roots, prefixes and suffixes',
    'Many words use Latin and Greek roots: aqua = water, port = carry, bio = life, graph = write, tele = far.',
    [
      _q('The root aqua means water. Which word is about water?', 'aquarium',
          ['quarrel', 'equal'], 1),
      _q(
          'The root port means carry. What does transport mean?',
          'To carry from place to place',
          ['To keep in one place', 'To write a letter'],
          0),
      _q(
          'Bio means life and -logy means the study of. What is biology?',
          'The study of life',
          ['The study of the stars', 'The study of rocks'],
          2),
      _q('The prefix tele means far. Which word means seeing from far?',
          'television', ['microscope', 'photograph'], 1),
      _q('The prefix sub means under. Which word names a boat that travels under water?',
          'submarine', ['supermarket', 'steamer'], 0),
    ],
    'aqua, port, bio, tele, sub',
  ),
  _l(
    5,
    'Phrases and clauses',
    'Tell a phrase from a clause.',
    'Grammar',
    'Phrases and clauses',
    'A clause has a subject and a verb. A phrase does not. An independent clause can stand alone; a dependent one cannot.',
    [
      _q('Which group of words is a PHRASE?', 'under the old banyan tree',
          ['the bell rang loudly', 'when school ended'], 1),
      _q(
          'Which group of words is an independent clause?',
          'Meena closed the window.',
          ['Although it was cold', 'Because she was late'],
          0),
      _q("In 'Although it was raining, we played outside', what is 'Although it was raining'?",
          'A dependent clause', ['An independent clause', 'A phrase'], 2),
      _q(
          'Which sentence contains a dependent clause?',
          'I will call you when I reach home.',
          ['Call me now.', 'The phone rang twice.'],
          1),
      _q('What must every clause contain?', 'A subject and a verb',
          ['A comma and a full stop', 'At least ten words'], 0),
    ],
    'Phrase versus clause',
  ),
  _l(
    6,
    'Conditional sentences',
    'Choose the right verb forms in if-sentences.',
    'Grammar',
    'Conditionals',
    'If + present, will: real future. If + past, would: imaginary now. If + had, would have: imaginary past.',
    [
      _q('Choose the best words: If it rains tomorrow, we ____ the match.',
          'will cancel', ['would cancel', 'cancelled'], 1),
      _q('Choose the best word: If I ____ a bird, I would fly over the Himalayas.',
          'were', ['am', 'will be'], 2),
      _q('Choose the best words: If she had studied harder, she ____ the exam.',
          'would have passed', ['will pass', 'would pass'], 0),
      _q(
          'Which sentence talks about an imaginary, impossible situation?',
          'If I had wings, I would fly to school.',
          [
            'If it rains, I will take an umbrella.',
            'If you heat ice, it melts.'
          ],
          2),
      _q(
          'Which sentence is correct?',
          'If Ravi hurries, he will catch the bus.',
          [
            'If Ravi will hurry, he will catch the bus.',
            'If Ravi hurried, he will catch the bus.'
          ],
          1),
    ],
    'If I were a bird',
  ),
  _l(
    7,
    'Colon, semicolon and dash',
    'Use a colon, semicolon or dash in the right place.',
    'Writing',
    'Punctuation',
    'A colon introduces a list. A semicolon joins two linked sentences. A dash adds a sudden break or emphasis.',
    [
      _q(
          'Which sentence uses a colon correctly?',
          'Buy three things: a pen, a ruler, a book.',
          [
            'Buy: three things a pen, a ruler, a book.',
            'Buy three things a pen: a ruler, a book.'
          ],
          0),
      _q(
          'Which sentence uses a semicolon correctly?',
          'Ravi was tired; he went to bed early.',
          [
            'Ravi; was tired he went to bed early.',
            'Ravi was tired; and, went to bed early.'
          ],
          1),
      _q("Which mark best joins two linked sentences: 'It was late ___ the shops had closed.'?",
          'A semicolon', ['A question mark', 'An apostrophe'], 2),
      _q(
          "What does the colon do in 'We need three things: rice, dal and salt'?",
          'It introduces a list',
          ['It ends the sentence', 'It shows a question'],
          1),
      _q(
          'Which sentence uses dashes correctly for sudden emphasis?',
          'The winner — to our surprise — was Ravi.',
          [
            'The — winner was Ravi to our surprise.',
            'The winner was — Ravi to our — surprise.'
          ],
          2),
    ],
    'Rice: dal; salt - and more',
  ),
  _l(
    8,
    'Formal and informal writing',
    'Choose the right style for an email.',
    'Writing',
    'Formal and informal style',
    'Formal writing uses a polite greeting, full words and a clear closing. Informal writing is casual and friendly.',
    [
      _q('You are writing to your principal. Which greeting is best?',
          'Respected Madam,', ['Hey Madam!!', 'Yo principal,'], 1),
      _q('Which closing is best for a formal email to a teacher?',
          'Yours sincerely, Ravi', ['Bye bye, Ravi', 'Cheers!! R'], 0),
      _q('Which sentence is formal?', 'I request leave for two days.',
          ['Gimme two days off, ok?', "Can't come, bye!"], 2),
      _q(
          'Which is the best subject line for an email asking for leave?',
          'Request for leave on 12 and 13 November',
          ['Hi!!', 'Urgent urgent plz read'],
          1),
      _q(
          "Which is the formal version of: Can't make it, sorry!",
          'I regret that I am unable to attend.',
          ['No way, sorry, can not!', 'Sorry bro, not coming'],
          2),
    ],
    'Leave letter by email',
  ),
  _l(
    9,
    'Claim and evidence',
    'Separate a claim from the evidence behind it.',
    'Reading',
    'Argument',
    'A claim is a point you argue. Evidence is a fact or example that supports it. Opinions alone are not evidence.',
    [
      _q('Which sentence is a CLAIM?', 'Our school should plant more trees.',
          ['The school has twenty trees.', 'Trees have green leaves.'], 0),
      _q(
          'Claim: Children should sleep early. Which is the best evidence?',
          'Rested children score higher in tests',
          ['I like my bed very much', 'Everyone is sleepy at night'],
          1),
      _q(
          'Which of these is an opinion, not evidence?',
          'Cricket is the best game ever.',
          [
            'A cricket team has eleven players.',
            'A cricket pitch is 22 yards long.'
          ],
          2),
      _q(
          "Meena says, 'Cycling beats driving on short trips. It costs nothing and gives off no smoke.' What is her claim?",
          'Cycling is the better choice',
          ['Cycling costs no money', 'Cycles give off no smoke'],
          0),
      _q('Which phrase best introduces evidence?', 'For example,',
          ['Good morning,', 'Thank you,'], 1),
    ],
    'Claim, evidence, reasoning',
  ),
  _l(
    10,
    'Poetry devices',
    'Spot alliteration, simile, metaphor and personification.',
    'Reading',
    'Figurative language',
    'Alliteration repeats first sounds, a simile compares with like or as, a metaphor says one thing is another.',
    [
      _q("'Silly snakes slither slowly south.' Which device is used?",
          'Alliteration', ['Simile', 'Metaphor'], 1),
      _q("'Her smile was as bright as the sun.' Which device is used?",
          'Simile', ['Metaphor', 'Personification'], 0),
      _q("'Time is a thief.' Which device is used?", 'Metaphor',
          ['Simile', 'Alliteration'], 2),
      _q("'The wind whispered through the trees.' Which device is used?",
          'Personification', ['Simile', 'Alliteration'], 1),
      _q(
          'Which sentence contains a simile?',
          'The classroom was as quiet as a mouse.',
          ['The classroom was a zoo.', 'The classroom groaned at the test.'],
          2),
    ],
    'Like, as, is, and giving life',
  ),
]);
