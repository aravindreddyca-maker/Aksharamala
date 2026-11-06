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
      id: 'english-l4-${n.toString().padLeft(3, '0')}',
      module: 'english',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      questions: questions,
      examples: examples,
      ageBand: '10-12',
    );

/// Level 4 english: 15 lessons (english-l4-001 .. 015), ages 10-12 (`ageBand: '10-12'`).
final List<BatchLesson> englishLevel4Lessons = List.unmodifiable(<BatchLesson>[
  _l(
    1,
    'Paragraph main idea',
    'Read a paragraph and pick its main idea.',
    'Reading',
    'Main idea',
    'The main idea is what a paragraph is mostly about. The other sentences are details that support it.',
    const [
      L3Q(
          'Bees drink nectar from flowers. Pollen sticks to their legs and reaches other flowers. This helps plants make seeds. Main idea?',
          [
            'Bees help plants make seeds',
            'Bees are black and yellow',
            'Flowers smell sweet'
          ],
          'Bees help plants make seeds'),
      L3Q(
          "Meena's school has a garden. Children water the plants, pull weeds and sell the vegetables. What is the main idea?",
          [
            'Vegetables cost a lot',
            'Children take care of the school garden',
            'Weeds are tall'
          ],
          'Children take care of the school garden'),
      L3Q(
          "Which sentence is a supporting detail for the main idea 'Rain is important for farmers'?",
          [
            'Some farmers own bullocks',
            'Trains run on tracks',
            'Crops need rain water to grow'
          ],
          'Crops need rain water to grow'),
      L3Q(
          'What is a main idea?',
          [
            'The most important point of a paragraph',
            'The longest word in a paragraph',
            'The last full stop'
          ],
          'The most important point of a paragraph'),
      L3Q(
          'Diwali is a festival of lights. People light lamps, share sweets and wear new clothes. Which title fits best?',
          [
            'The History of Lamps',
            'How People Celebrate Diwali',
            'Sweets From Many Lands'
          ],
          'How People Celebrate Diwali'),
    ],
    const ['Short informational paragraph'],
  ),
  _l(
    2,
    'Context clues',
    'Work out the meaning of a new word from the sentence around it.',
    'Vocabulary',
    'Context clues',
    'Context clues are the words around an unfamiliar word. They help you work out its meaning.',
    const [
      L3Q('The desert was so arid that no rain fell for months and the soil cracked. Arid means...',
          ['very cold', 'very dry', 'very green'], 'very dry'),
      L3Q('Ravi was exhausted after the long race, so he lay down and slept. Exhausted means...',
          ['very tired', 'very hungry', 'very angry'], 'very tired'),
      L3Q('The kitten was timid and hid behind the sofa whenever visitors came. Timid means...',
          ['noisy', 'easily frightened', 'very big'], 'easily frightened'),
      L3Q('Meena felt delighted when she won the prize, and she smiled all day. Delighted means...',
          ['very sad', 'a little bored', 'very happy'], 'very happy'),
      L3Q('The path was narrow, so only one person could walk on it at a time. Narrow means...',
          ['very long', 'quite steep', 'not wide'], 'not wide'),
    ],
    const ['Predict meaning from surrounding words'],
  ),
  _l(
    3,
    'Synonyms and antonyms',
    'Choose words with the same or the opposite meaning.',
    'Vocabulary',
    'Synonyms and antonyms',
    'Synonyms mean almost the same (happy, joyful). Antonyms mean the opposite (brave, timid).',
    const [
      L3Q("Which word is a synonym of 'big'?", ['huge', 'tiny', 'narrow'],
          'huge'),
      L3Q("Which word is an antonym of 'brave'?", ['strong', 'timid', 'clever'],
          'timid'),
      L3Q("Choose the antonym of 'ancient'.", ['old', 'historic', 'modern'],
          'modern'),
      L3Q("Which word means almost the same as 'begin'?",
          ['finish', 'start', 'stop'], 'start'),
      L3Q('Which pair are antonyms?',
          ['quick - fast', 'shut - close', 'hot - cold'], 'hot - cold'),
    ],
    const ['happy - joyful', 'brave - timid'],
  ),
  _l(
    4,
    'Prefixes and suffixes',
    'Build new words with common word parts.',
    'Vocabulary',
    'Prefixes and suffixes',
    'A prefix goes before a word, a suffix after it. un- means not, re- again, -ful full of, -less without.',
    const [
      L3Q("What does 'unhappy' mean?",
          ['not happy', 'happy again', 'full of joy'], 'not happy'),
      L3Q("Add 're-' to 'write'. Which word do you get?",
          ['unwrite', 'rewrite', 'writeless'], 'rewrite'),
      L3Q("What does 'careless' mean?",
          ['full of care', 'care again', 'without care'], 'without care'),
      L3Q("Which word means 'full of help'?", ['helpful', 'helpless', 'rehelp'],
          'helpful'),
      L3Q("In 'replay', which part is the prefix?", ['play', 'ay', 're'], 're'),
    ],
    const ['un-', 're-', '-ful', '-less'],
  ),
  _l(
    5,
    'Parts of speech',
    'Tell nouns, pronouns, verbs, adjectives and adverbs apart.',
    'Grammar',
    'Parts of speech',
    'Nouns name things, pronouns replace nouns, verbs show action, adjectives describe nouns, adverbs tell how.',
    const [
      L3Q('Which word is a verb?', ['happy', 'table', 'jump'], 'jump'),
      L3Q('Which word is an adjective?', ['mango', 'eat', 'sweet'], 'sweet'),
      L3Q('Which word is a pronoun?', ['she', 'Asha', 'door'], 'she'),
      L3Q('Which word is an adverb?', ['happy', 'gently', 'garden'], 'gently'),
      L3Q('Which kind of word tells how an action is done?',
          ['noun', 'adverb', 'pronoun'], 'adverb'),
    ],
    const ['A cheerful child runs quickly'],
  ),
  _l(
    6,
    'Verb tense consistency',
    'Keep past, present and future tense steady in a sentence.',
    'Grammar',
    'Verb tense',
    'Keep the same tense in a sentence or paragraph. Say Yesterday we walked home, not Yesterday we walk home.',
    const [
      L3Q(
          'Which sentence keeps the tense consistent?',
          [
            'Yesterday Ravi walked and meets Asha.',
            'Yesterday Ravi walked and met Asha.',
            'Yesterday Ravi walks and met Asha.'
          ],
          'Yesterday Ravi walked and met Asha.'),
      L3Q('Choose the word that fits: Tomorrow Meena ____ her aunt.',
          ['visited', 'visiting', 'will visit'], 'will visit'),
      L3Q('Choose the correct word: Last week, we ____ a kite festival.',
          ['watch', 'watched', 'will watch'], 'watched'),
      L3Q('Which word is in the PAST tense?', ['sang', 'sings', 'will sing'],
          'sang'),
      L3Q("Fix the verb: 'Every morning Asha wakes up and brushed her teeth.' Which is right?",
          ['brush', 'brushing', 'brushes'], 'brushes'),
    ],
    const ['Yesterday we walked home'],
  ),
  _l(
    7,
    'Sentence types',
    'Use statements, questions, commands and exclamations.',
    'Grammar',
    'Sentence types',
    'A statement tells, a question asks, a command orders, and an exclamation shows strong feeling.',
    const [
      L3Q("Which kind of sentence is 'Where is the kite?'",
          ['a statement', 'a question', 'a command'], 'a question'),
      L3Q(
          'Which sentence is a command?',
          ['Please close the door.', 'The door is open.', 'Is the door open?'],
          'Please close the door.'),
      L3Q('Which mark ends this sentence: What a beautiful rangoli',
          ['.', '?', '!'], '!'),
      L3Q(
          'Which sentence is a statement?',
          ['Open your book.', 'Rain falls from clouds.', 'Do you like rain?'],
          'Rain falls from clouds.'),
      L3Q('Which mark ends this sentence: Do you like mangoes', ['?', '.', '!'],
          '?'),
    ],
    const ['Where is the kite?'],
  ),
  _l(
    8,
    'Compound sentences',
    'Join two related ideas with and, but, or and so.',
    'Grammar',
    'Conjunctions',
    'A compound sentence joins two related ideas with and, but, or, so. Put a comma before the joining word.',
    const [
      L3Q('Choose the best joining word: It was raining, ____ we stayed indoors.',
          ['but', 'so', 'or'], 'so'),
      L3Q('Choose the best joining word: Ravi likes tea, ____ Meena likes milk.',
          ['so', 'because', 'but'], 'but'),
      L3Q(
          'Which is a compound sentence?',
          [
            'Asha and Ravi sang.',
            'Asha sang a song.',
            'Asha sang, and Ravi danced.'
          ],
          'Asha sang, and Ravi danced.'),
      L3Q('Choose the best joining word: You can walk to school, ____ you can take the bus.',
          ['but', 'or', 'so'], 'or'),
      L3Q('Which word joins two ideas that go together? She cooked rice ____ he made curry.',
          ['but', 'or', 'and'], 'and'),
    ],
    const ['I read and she drew'],
  ),
  _l(
    9,
    'Paragraph organisation',
    'Put topic, detail and closing sentences in the right order.',
    'Writing',
    'Paragraph structure',
    'A good paragraph starts with a topic sentence, adds details, and ends with a closing sentence.',
    const [
      L3Q(
          'Which sentence is the best TOPIC sentence?',
          [
            'My favourite festival is Pongal.',
            'We eat sweet rice.',
            'I love it very much.'
          ],
          'My favourite festival is Pongal.'),
      L3Q(
          'Which sentence is the best CLOSING sentence for a paragraph about Pongal?',
          [
            'The cows are washed.',
            'That is why Pongal makes me so happy.',
            'Sugarcane is tall.'
          ],
          'That is why Pongal makes me so happy.'),
      L3Q(
          'Which sentence does NOT belong in a paragraph about rain?',
          [
            'Rain fills the lakes.',
            'Farmers sow seeds after rain.',
            'Cricket bats are made of wood.'
          ],
          'Cricket bats are made of wood.'),
      L3Q('Order the parts of a paragraph: which comes FIRST?',
          ['topic sentence', 'details', 'closing sentence'], 'topic sentence'),
      L3Q(
          'What do the detail sentences do?',
          [
            'End the paragraph',
            'Support the topic sentence',
            'Change the topic'
          ],
          'Support the topic sentence'),
    ],
    const ['My favourite festival'],
  ),
  _l(
    10,
    'Compare and contrast',
    'Find how two things are alike and how they differ.',
    'Reading',
    'Compare and contrast',
    'To compare, tell how things are alike. To contrast, tell how they differ. Words like both and but help.',
    const [
      L3Q(
          "Ravi's story is about a dog that is lost. Meena's story is about a lost parrot. How are the stories alike?",
          [
            'Both are about a lost pet',
            'Both have a dog',
            'Both happen at school'
          ],
          'Both are about a lost pet'),
      L3Q('Which word signals a DIFFERENCE?', ['both', 'however', 'also'],
          'however'),
      L3Q('Which word signals a SIMILARITY?', ['but', 'unlike', 'both'],
          'both'),
      L3Q(
          'A cat and a dog are both pets, but a dog barks and a cat meows. What is one DIFFERENCE?',
          ['Dogs bark and cats meow', 'They are both pets', 'Both are animals'],
          'Dogs bark and cats meow'),
      L3Q(
          'Tigers and lions are both big cats. What does the word both tell us?',
          ['They are different', 'They are small', 'They share something'],
          'They share something'),
    ],
    const ['Two short stories'],
  ),
  _l(
    11,
    'Cause and effect',
    'Link what happened with why it happened.',
    'Reading',
    'Cause and effect',
    'A cause is why something happens. The effect is what happens. Words like because and so link them.',
    const [
      L3Q(
          'The plant drooped because nobody watered it. What was the CAUSE?',
          ['It was not given water', 'It had too much sun', 'It was too tall'],
          'It was not given water'),
      L3Q(
          'Asha ate too many sweets, so she got a stomach ache. What was the EFFECT?',
          [
            'She bought more sweets',
            'She felt pain in her tummy',
            'She went to a party'
          ],
          'She felt pain in her tummy'),
      L3Q('Which word links a cause to its effect?', ['or', 'but', 'because'],
          'because'),
      L3Q(
          'What is likely to happen if you do not drink water on a hot day?',
          [
            'You will feel thirsty',
            'You will feel cold',
            'You will grow taller'
          ],
          'You will feel thirsty'),
      L3Q(
          'Roads were flooded after the storm, so the bus came late. What caused the bus to be late?',
          ['A school holiday', 'A broken bell', 'Flooded roads'],
          'Flooded roads'),
    ],
    const ['Rain caused the match to stop'],
  ),
  _l(
    12,
    'Character motivation',
    'Use clues in a story to say why a character acts.',
    'Reading',
    'Character motivation',
    'Motivation is why a character acts. Look for what the character feels, wants or needs.',
    const [
      L3Q(
          'Meena had two oranges. She saw a hungry boy at the gate and gave him one. Why did Meena share?',
          [
            'She wanted to throw it away',
            'She felt sorry for him',
            'She did not like oranges'
          ],
          'She felt sorry for him'),
      L3Q(
          'Ravi practised cricket every evening because he wanted to join the school team. What motivated him?',
          [
            'A wish to join the team',
            'A fear of the dark',
            'Anger at his friend'
          ],
          'A wish to join the team'),
      L3Q('Asha woke early on exam day and revised again, as she wished to score well. Which word describes Asha?',
          ['lazy', 'careless', 'hardworking'], 'hardworking'),
      L3Q('Ravi found a wallet and ran to return it to the owner. This shows that Ravi is...',
          ['honest', 'greedy', 'shy'], 'honest'),
      L3Q(
          'Meena cried when her puppy was sick. What does this show about her feelings?',
          ['She was bored', 'She was sleepy', 'She loves her pet'],
          'She loves her pet'),
    ],
    const ['Why did the child share?'],
  ),
  _l(
    13,
    'Summarising nonfiction',
    'Pick the key facts and say them in a short summary.',
    'Reading',
    'Summarising',
    'A summary gives only the key facts in a few words of your own. Leave out the small details.',
    const [
      L3Q(
          'Seeds need water and warmth to sprout. Roots grow down, then a shoot grows up. Leaves make food from sunlight. Best summary?',
          [
            'A seed grows into a plant',
            'Seeds are sold in shops',
            'Plants only grow in winter'
          ],
          'A seed grows into a plant'),
      L3Q(
          'Which detail is LEAST important in a summary?',
          ['The main point', 'The key facts', 'A minor side detail'],
          'A minor side detail'),
      L3Q(
          'A summary should be...',
          [
            'longer than the text',
            'shorter than the text',
            'a copy of the text'
          ],
          'shorter than the text'),
      L3Q(
          'The Ganga is a long river in India. It begins in the Himalayas and flows to the Bay of Bengal. Millions of people use its water. Best summary?',
          [
            'A long Indian river many people use',
            'A small pond near a village',
            'A mountain with no water'
          ],
          'A long Indian river many people use'),
      L3Q(
          'Which is the best first step in summarising a text?',
          ['Copy every line', 'Add your own opinion', 'Find the key facts'],
          'Find the key facts'),
    ],
    const ['How plants grow'],
  ),
  _l(
    14,
    'Writing an invitation',
    'Choose and arrange the right parts of an invitation.',
    'Writing',
    'Invitations',
    'An invitation tells who is invited, what the event is, when and where, and who is inviting. End with a polite request to come.',
    const [
      L3Q(
          'Which detail must an invitation include?',
          ['The weather last year', 'The date and time', 'A shopping list'],
          'The date and time'),
      L3Q('Which greeting best opens an invitation to a friend?',
          ['Dear Asha,', 'Stop right there', 'Goodbye Asha'], 'Dear Asha,'),
      L3Q(
          'Which line gives the PLACE of a school exhibition?',
          ['At 10 a.m. on Friday', 'From Meena', 'In the school hall'],
          'In the school hall'),
      L3Q(
          'Which line is the best ending for an invitation?',
          ['Please come and join us.', 'I do not care.', 'The end.'],
          'Please come and join us.'),
      L3Q(
          'Which line tells WHO is inviting?',
          ['On 14 November', 'From Meena, Class 6', 'In the library'],
          'From Meena, Class 6'),
    ],
    const ['School exhibition invitation'],
  ),
  _l(
    15,
    'Independent reading review',
    'Read short passages and answer mixed questions.',
    'Reading',
    'Reading review',
    'Read the passage, look for the main idea and clues, and check your answer against the text before choosing.',
    const [
      L3Q(
          'Banyan trees give shade to travellers. Their hanging roots become new trunks. Some live for hundreds of years. Main idea?',
          [
            'Banyan trees have special features',
            'Travellers love long walks',
            'Roots are bad for trees'
          ],
          'Banyan trees have special features'),
      L3Q('The river swelled after three days of rain, and the villagers feared a flood. Swelled means...',
          ['became warm', 'grew bigger', 'went quiet'], 'grew bigger'),
      L3Q(
          'Ravi forgot his umbrella and got wet in the rain. What was the reason he got wet?',
          [
            'The rain was warm',
            'He left school early',
            'He had no umbrella with him'
          ],
          'He had no umbrella with him'),
      L3Q('Meena helped her grandmother carry the heavy bags home. Which word describes Meena?',
          ['helpful', 'rude', 'lazy'], 'helpful'),
      L3Q("What kind of word is 'quickly' in 'Ravi ran quickly'?",
          ['adverb', 'noun', 'verb'], 'adverb'),
    ],
    const ['Unseen passage'],
  ),
]);
