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
      id: 'english-l5-${n.toString().padLeft(3, '0')}',
      module: 'english',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      questions: questions,
      examples: examples,
      ageBand: '10-12',
      level: 5,
    );

/// Level 5 english: 15 lessons (english-l5-001 .. 015). Level 5: pass `ageBand: '10-12', level: 5`.
final List<BatchLesson> englishLevel5Lessons = List.unmodifiable(<BatchLesson>[
  _l(
    1,
    'Author purpose and audience',
    'Identify why a text was written and who it is for.',
    'Reading',
    'Author purpose',
    'Authors write to inform, persuade or entertain. Words and tone show the purpose and the audience.',
    const [
      L3Q(
          "A notice says: 'Class 7 trip on Friday. Bring lunch and a cap.' What is its purpose?",
          [
            'To give information',
            'To persuade readers to buy',
            'To tell a funny story'
          ],
          'To give information'),
      L3Q(
          "'Every child must plant a tree. Surely nobody can disagree!' What is the author trying to do?",
          ['Give a recipe', 'Convince readers', 'Describe a place'],
          'Convince readers'),
      L3Q(
          "A story begins: 'Once, a tiny dragon feared fire.' Who is the likely audience?",
          ['Bank managers', 'Tax officers', 'Young children who enjoy tales'],
          'Young children who enjoy tales'),
      L3Q(
          'Which clue shows an article is meant to persuade?',
          [
            'A list of dates',
            "Strong words like 'must' and 'best'",
            'A table of figures'
          ],
          "Strong words like 'must' and 'best'"),
      L3Q(
          'A science textbook explains how volcanoes erupt. What is its main purpose?',
          [
            'To explain facts to students',
            'To make readers laugh',
            'To sell a product'
          ],
          'To explain facts to students'),
    ],
    const ['Notice versus opinion article'],
  ),
  _l(
    2,
    'Fact, opinion and evidence',
    'Tell facts from opinions and find evidence for a claim.',
    'Reading',
    'Evidence',
    'A fact can be checked. An opinion is a belief. Good evidence, like data or an example, supports a claim.',
    const [
      L3Q(
          'Which statement is a fact?',
          [
            'Water boils at 100 C at sea level',
            'Tea tastes better than coffee',
            'Boiling water is a boring job'
          ],
          'Water boils at 100 C at sea level'),
      L3Q(
          'Which statement is an opinion?',
          [
            'India has 28 states',
            'Cricket is the most exciting sport',
            'The pitch is 22 yards long'
          ],
          'Cricket is the most exciting sport'),
      L3Q(
          "Claim: 'Our school library is well used.' Which detail is the best evidence?",
          [
            'The library has green walls',
            'Many students love books',
            'Students borrowed 900 books last month'
          ],
          'Students borrowed 900 books last month'),
      L3Q('Which word often signals an opinion?',
          ['population', 'best', 'kilometre'], 'best'),
      L3Q(
          "Rahul says, 'Homework is useless.' What would make his claim stronger?",
          [
            'A survey showing marks did not improve',
            'Saying it louder',
            'Asking friends to agree'
          ],
          'A survey showing marks did not improve'),
    ],
    const ['Claim and supporting detail'],
  ),
  _l(
    3,
    'Inference across paragraphs',
    'Combine clues from two paragraphs to make an inference.',
    'Reading',
    'Inference',
    'An inference is a conclusion drawn from clues. Combine clues from different paragraphs to support it.',
    const [
      L3Q(
          'Para 1: Asha packed her bag at dawn. Para 2: She hugged her mother tightly at the station. Where is Asha most likely going?',
          ['To a hospital', 'Away on a journey', 'To a cricket match'],
          'Away on a journey'),
      L3Q(
          "Para 1: Ravi's shoes were caked with mud. Para 2: His umbrella dripped at the door. What can we infer about the weather?",
          ['It had been raining', 'It was a dry day', 'It was extremely hot'],
          'It had been raining'),
      L3Q(
          "Para 1: Kabir's name was missing from the winners' list. Para 2: He smiled and clapped for his friend. What does this show?",
          ['He is sleepy', 'He is jealous and rude', 'He is a good sport'],
          'He is a good sport'),
      L3Q(
          'Which is the best way to justify an inference?',
          [
            'Say it feels right',
            'Point to clues in the text',
            'Pick the longest option'
          ],
          'Point to clues in the text'),
      L3Q(
          "Para 1: The shop's lights were off and the shutter was down. Para 2: A board read 'Back on Monday'. Which inference is best supported?",
          [
            'The shop is closed for now',
            'The shop was robbed',
            'The shop has moved abroad'
          ],
          'The shop is closed for now'),
    ],
    const ['Multi-paragraph narrative'],
  ),
  _l(
    4,
    'Figurative language',
    'Explain similes, idioms and metaphors.',
    'Language',
    'Figurative language',
    "Similes compare using 'like' or 'as'. Idioms mean something other than their words. Metaphors say one thing is another.",
    const [
      L3Q("'As brave as a lion' tells us a person is...",
          ['very tall', 'very courageous', 'very noisy'], 'very courageous'),
      L3Q(
          "What does the idiom 'a piece of cake' mean?",
          ['A sweet snack', 'Something expensive', 'Something very easy'],
          'Something very easy'),
      L3Q("'Time is a thief.' This sentence is a...",
          ['simile', 'metaphor', 'question'], 'metaphor'),
      L3Q(
          "'It is raining cats and dogs' means...",
          [
            'It is raining heavily',
            'The sky is clear',
            'Pets are lost in the rain'
          ],
          'It is raining heavily'),
      L3Q(
          'Which sentence is a simile?',
          [
            'The classroom was a zoo',
            'The wind whispered',
            'He ran as fast as a cheetah'
          ],
          'He ran as fast as a cheetah'),
    ],
    const ['as brave as a lion'],
  ),
  _l(
    5,
    'Advanced vocabulary',
    'Use word roots and context to work out meanings.',
    'Vocabulary',
    'Word roots',
    "Roots help decode words: 'port' means carry, 'pre' means before, 'vis' means see. Use context too.",
    const [
      L3Q("'Transport' has the root 'port'. It means to...",
          ['carry across', 'cut apart', 'write down'], 'carry across'),
      L3Q("'Preview' begins with 'pre', meaning before. To preview is to see something...",
          ['long afterwards', 'in advance', 'by mistake'], 'in advance'),
      L3Q(
          "'Benefactor': 'bene' means good. A benefactor is someone who...",
          ['avoids others', 'hurts others', 'does good for others'],
          'does good for others'),
      L3Q("The drought was so severe that crops withered. 'Severe' means...",
          ['very harsh', 'very short', 'very pleasant'], 'very harsh'),
      L3Q(
          "'Unanimous': 'uni' means one. A unanimous vote is one where...",
          ['nobody votes', 'everyone agrees', 'most people argue'],
          'everyone agrees'),
    ],
    const ['transport, preview'],
  ),
  _l(
    6,
    'Direct and indirect speech',
    'Turn spoken words into reported speech.',
    'Grammar',
    'Reported speech',
    "In reported speech, drop the quotation marks, add 'that', and shift the tense back: 'am' becomes 'was'.",
    const [
      L3Q(
          "She said, 'I am ready.' Choose the reported speech.",
          [
            'She said that she was ready.',
            'She said that I am ready.',
            'She said that she is ready.'
          ],
          'She said that she was ready.'),
      L3Q(
          "Ravi said, 'I like mangoes.' Choose the reported form.",
          [
            'Ravi said that I liked mangoes.',
            'Ravi said that he liked mangoes.',
            'Ravi said, that he like mangoes.'
          ],
          'Ravi said that he liked mangoes.'),
      L3Q(
          "The teacher said, 'Open your books.' Which is correct?",
          [
            'The teacher said us open books.',
            'The teacher told open our books.',
            'The teacher told us to open our books.'
          ],
          'The teacher told us to open our books.'),
      L3Q("Which word usually follows 'said' in a reported statement?",
          ['that', 'also', 'since'], 'that'),
      L3Q("Meena said, 'I will call you tomorrow.' In reported speech 'will' changes to...",
          ['shall', 'would', 'did'], 'would'),
    ],
    const ['She said, "I am ready."'],
  ),
  _l(
    7,
    'Active and passive voice',
    'Recognise and change active and passive sentences.',
    'Grammar',
    'Voice',
    'Active: the doer comes first (Ravi kicked the ball). Passive: the receiver comes first (The ball was kicked).',
    const [
      L3Q(
          'Which sentence is passive?',
          [
            'The cat chased the mouse.',
            'The mouse was chased by the cat.',
            'The cat is chasing the mouse.'
          ],
          'The mouse was chased by the cat.'),
      L3Q(
          "Change to passive: 'The teacher praised Anu.'",
          [
            'Anu was praised by the teacher.',
            'Anu praised the teacher.',
            'The teacher was praised by Anu.'
          ],
          'Anu was praised by the teacher.'),
      L3Q(
          "Change to active: 'The window was broken by Rahul.'",
          [
            'The window broke Rahul.',
            'Rahul was breaking the window.',
            'Rahul broke the window.'
          ],
          'Rahul broke the window.'),
      L3Q(
          "Why might a writer choose the passive: 'The bridge was built in 1950'?",
          [
            'To avoid using any verb',
            'The builder is unimportant here',
            'To make it a question'
          ],
          'The builder is unimportant here'),
      L3Q(
          'Which sentence has the doer as its subject?',
          [
            'The cake was eaten by Raju.',
            'The cake was eaten.',
            'Raju ate the cake.'
          ],
          'Raju ate the cake.'),
    ],
    const ['The ball was kicked'],
  ),
  _l(
    8,
    'Complex sentences',
    'Join ideas with subordinate clauses.',
    'Grammar',
    'Complex sentences',
    'A complex sentence joins a main clause to a subordinate clause with words like although, because, when or if.',
    const [
      L3Q(
          'Which is a complex sentence?',
          [
            'We played although it rained.',
            'We played and it rained.',
            'We played. It rained.'
          ],
          'We played although it rained.'),
      L3Q("Choose the best word: '___ the bus was late, we missed the quiz.'",
          ['Unless', 'Because', 'Whereas'], 'Because'),
      L3Q(
          "Which ending fits? 'Although Meena was tired, ...'",
          ['she felt sleepy', 'she was extremely tired', 'she kept studying'],
          'she kept studying'),
      L3Q(
          'What is true of a subordinate clause?',
          [
            'It always starts a paragraph',
            'It never has a verb',
            'It cannot stand alone as a sentence'
          ],
          'It cannot stand alone as a sentence'),
      L3Q(
          'Which sentence uses a comma correctly?',
          [
            'If it rains, we will stay home.',
            'If it rains we, will stay home.',
            'If, it rains we will stay home.'
          ],
          'If it rains, we will stay home.'),
    ],
    const ['Although it rained, we played'],
  ),
  _l(
    9,
    'Narrative writing',
    'Plan a story with setting, conflict and resolution.',
    'Writing',
    'Narrative',
    'A good story has a setting, a problem (conflict) and a resolution. Plan these before you write.',
    const [
      L3Q(
          "Which is a story's setting?",
          [
            'A rainy night in a village library',
            'Reena felt very sad',
            'The lost book was found'
          ],
          'A rainy night in a village library'),
      L3Q(
          'Plan: a lost library book. Which is the best conflict?',
          [
            'The library opens at nine',
            'Mohan cannot find the book that is due today',
            'Mohan has a red bag'
          ],
          'Mohan cannot find the book that is due today'),
      L3Q(
          'Which resolution fits a story about a lost library book?',
          [
            'Mohan buys a new bag',
            'The bell rings for lunch',
            'He finds it under his bed and returns it'
          ],
          'He finds it under his bed and returns it'),
      L3Q(
          'Which opening line hooks the reader best?',
          [
            'The book had vanished; it was due today.',
            'This story is about a book.',
            'Once there was a book, and it was a book.'
          ],
          'The book had vanished; it was due today.'),
      L3Q(
          'Which tip improves narrative writing?',
          [
            'Skip the ending',
            'Repeat each sentence',
            'Show scenes with sight and sound details'
          ],
          'Show scenes with sight and sound details'),
    ],
    const ['A lost library book'],
  ),
  _l(
    10,
    'Expository writing',
    'Organise facts under one central topic.',
    'Writing',
    'Expository writing',
    'An expository paragraph has a topic sentence, supporting facts in a clear order, and a closing sentence.',
    const [
      L3Q(
          'Which is the best topic sentence for a paragraph on recycling?',
          [
            'I like green bins.',
            'Recycling turns used items into new things.',
            'Yesterday was Sunday.'
          ],
          'Recycling turns used items into new things.'),
      L3Q(
          'Which sentence does not belong in a paragraph on how recycling works?',
          [
            'Waste is sorted into paper, glass, plastic.',
            'Sorted material is cleaned and melted.',
            'My cousin owns a red scooter.'
          ],
          'My cousin owns a red scooter.'),
      L3Q('Which word helps show the order of steps?',
          ['Next', 'Although', 'Perhaps'], 'Next'),
      L3Q(
          'What should a closing sentence do?',
          ['Start a new topic', 'Add a joke', 'Sum up the main point'],
          'Sum up the main point'),
      L3Q(
          'Which order best explains how rain forms?',
          [
            'Rain falls, clouds form, water evaporates',
            'Water evaporates, clouds form, rain falls',
            'Clouds form, rain evaporates, vapour falls'
          ],
          'Water evaporates, clouds form, rain falls'),
    ],
    const ['How recycling works'],
  ),
  _l(
    11,
    'Persuasive writing',
    'State a position and support it with two reasons.',
    'Writing',
    'Persuasion',
    'A persuasive paragraph states a position, gives two reasons with evidence, and ends with a call to action.',
    const [
      L3Q(
          'Which is the clearest position statement?',
          [
            'Trees are green.',
            'Our school should plant more trees.',
            'Some schools have gardens.'
          ],
          'Our school should plant more trees.'),
      L3Q(
          'Which reason best supports planting trees at school?',
          [
            'Trees give shade and cool the playground.',
            'Trees are sometimes tall.',
            'I saw a tree once.'
          ],
          'Trees give shade and cool the playground.'),
      L3Q(
          'Which sentence is a call to action?',
          [
            'Trees grow slowly.',
            'Many birds live in trees.',
            'Let us plant a sapling this month.'
          ],
          'Let us plant a sapling this month.'),
      L3Q(
          'Which sentence persuades most respectfully?',
          [
            'Shade helps all, so please consider this.',
            'Anyone against trees is silly.',
            'Do it or else.'
          ],
          'Shade helps all, so please consider this.'),
      L3Q(
          "Which is evidence for the claim 'Trees cool the school'?",
          [
            'Trees look lovely',
            'Everyone loves trees',
            'Shaded ground was 4 C cooler'
          ],
          'Shaded ground was 4 C cooler'),
    ],
    const ['More trees at school'],
  ),
  _l(
    12,
    'Comparing sources',
    'Find agreement, differences and gaps in two sources.',
    'Reading',
    'Comparing sources',
    'Compare sources: what do both say, where do they differ, and what is missing? Check who wrote each one.',
    const [
      L3Q(
          "A: 'The fair drew 500 visitors.' B: 'Around 500 people came to the fair.' How do the sources relate?",
          ['They agree', 'They contradict', 'They are unrelated'],
          'They agree'),
      L3Q("A: 'The match ended 2-1.' B: 'The match ended 3-1.' What is different?",
          ['The date', 'The final score', 'The venue'], 'The final score'),
      L3Q(
          'Which is likelier to be biased about sugar: a school health page or a sweet maker\'s advert?',
          [
            'Both are always neutral',
            'The school page',
            "The sweet maker's ad"
          ],
          "The sweet maker's ad"),
      L3Q(
          'A gives a flood date. B gives its damage. Neither says how people were helped. What is the gap?',
          [
            'Missing information on relief',
            'Too many photos',
            'A spelling mistake'
          ],
          'Missing information on relief'),
      L3Q(
          'Which is the most reliable source for rainfall data?',
          [
            "A friend's guess",
            "The Meteorological Department's records",
            'An unsigned forwarded message'
          ],
          "The Meteorological Department's records"),
    ],
    const ['Two accounts of an event'],
  ),
  _l(
    13,
    'Editing for clarity',
    'Revise wordy or unclear sentences.',
    'Writing',
    'Editing',
    'Cut extra words, fix punctuation, and link ideas smoothly so every sentence is clear to the reader.',
    const [
      L3Q(
          'Which sentence is the clearest?',
          [
            'Due to the fact it rained, we went inside.',
            'Because it rained, we went inside.',
            'It was rain that caused us to go inside.'
          ],
          'Because it rained, we went inside.'),
      L3Q(
          'Which sentence is correctly punctuated?',
          [
            'Anu bought pens, books and a bag.',
            'Anu bought, pens books, and a bag.',
            'Anu bought pens books, and, a bag.'
          ],
          'Anu bought pens, books and a bag.'),
      L3Q(
          "Fix the run-on: 'I was late the bus left.'",
          [
            'I was late the bus had left.',
            'I was late the, bus had left.',
            'I was late, and the bus had left.'
          ],
          'I was late, and the bus had left.'),
      L3Q("Which word fits? 'It was raining. ___, we carried umbrellas.'",
          ['Although', 'Therefore', 'Unless'], 'Therefore'),
      L3Q(
          "Which revision removes the repeated idea in 'The sunrise was beautiful and lovely'?",
          [
            'The sunrise was beautiful.',
            'The sunrise was very beautiful and lovely.',
            'The sunrise was lovely and beautiful, too.'
          ],
          'The sunrise was beautiful.'),
    ],
    const ['Short draft paragraph'],
  ),
  _l(
    14,
    'Listening and note-taking',
    'Pick the best notes from a spoken passage.',
    'Listening',
    'Note-taking',
    'While listening, note key words, numbers and names, not full sentences. Group notes under headings.',
    const [
      L3Q(
          "Talk: 'The Nilgiri tahr lives in the Western Ghats. Only about 3,000 remain. Hunting and lost habitat are the main threats.' Best notes?",
          [
            'Tahr; W. Ghats; 3,000 left; hunting',
            'The talk was long',
            'Tahr is nice'
          ],
          'Tahr; W. Ghats; 3,000 left; hunting'),
      L3Q(
          'Which is NOT a key detail to note from a talk about an animal?',
          [
            "The animal's name",
            'The number remaining',
            "The speaker's blue shirt"
          ],
          "The speaker's blue shirt"),
      L3Q(
          'Why use short notes while listening?',
          [
            'Teachers dislike full sentences',
            'You can keep up with the speaker',
            'Ink is costly'
          ],
          'You can keep up with the speaker'),
      L3Q(
          "Speaker: 'First, wash hands. Second, wet the soap. Third, scrub twenty seconds.' How should you organise notes?",
          ['A random drawing', 'One long sentence', 'A numbered list of steps'],
          'A numbered list of steps'),
      L3Q(
          'What should you do after the talk ends?',
          [
            'Throw the notes away',
            'Review and fill gaps in your notes',
            "Copy a friend's notes without reading"
          ],
          'Review and fill gaps in your notes'),
    ],
    const ['Short recorded talk'],
  ),
  _l(
    15,
    'Integrated reading project',
    'Read, summarise and present a short report.',
    'Project',
    'Report',
    'A report: choose a topic, read sources, note key points, summarise in your words, then present clearly.',
    const [
      L3Q(
          'What is the best first step for a report on solar energy?',
          [
            'Read reliable sources on the topic',
            'Write the conclusion only',
            'Choose a font'
          ],
          'Read reliable sources on the topic'),
      L3Q(
          "Summarise: 'Solar panels turn sunlight into power. They cost more to fit, but bills fall over years.'",
          [
            'Solar panels are black',
            'Solar costs more at first but saves later',
            'Power bills are high'
          ],
          'Solar costs more at first but saves later'),
      L3Q(
          'Which source is the most reliable for a report on solar energy?',
          [
            'An anonymous forwarded message',
            "A friend's guess",
            'A government energy agency page'
          ],
          'A government energy agency page'),
      L3Q(
          'Which is a good way to present a report?',
          [
            'Use headings and speak clearly to the class',
            'Read it word for word, looking down',
            'Whisper to save time'
          ],
          'Use headings and speak clearly to the class'),
      L3Q(
          'Why should a report list its sources?',
          [
            'To fill space',
            'So readers can check the facts',
            'To hide the facts'
          ],
          'So readers can check the facts'),
    ],
    const ['One-page topic report'],
  ),
]);
