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
      id: 'english-l7-${n.toString().padLeft(3, '0')}',
      module: 'english',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      questions: questions,
      examples: examples,
      ageBand: '10-12',
      level: 7,
    );

/// Level 7 english: 10 lessons (english-l7-001 .. 010), about age 14 (Class 8).
/// Uses `ageBand: '10-12', level: 7` (levels above 5 have no age band of their
/// own). Hand-written; test/level7_english_test.dart checks the shape.
final List<BatchLesson> englishLevel7Lessons = List.unmodifiable(<BatchLesson>[
  _l(
    1,
    'Theme across a passage',
    'Find the theme by tracing how a story develops.',
    'Reading',
    'Theme',
    "A theme is the big idea a story or poem shows about life. Trace how events and the character's feelings change.",
    const [
      L3Q(
          'Kavya hid her low marks from everyone and felt lonely. When she finally told her teacher, she got help and felt lighter. What is the theme?',
          [
            'Marks are the only thing that matters',
            'Honesty brings relief and support',
            'Teachers give too much homework'
          ],
          'Honesty brings relief and support'),
      L3Q(
          'Raju laughs at a boy who stammers, but later he stands up for him when others tease. This change shows the theme of...',
          [
            'the joy of winning games',
            'fear of the unknown',
            'growing kindness and empathy'
          ],
          'growing kindness and empathy'),
      L3Q(
          'Which statement is a theme, not just a topic?',
          [
            'True friends stand by us in hard times',
            'Friendship',
            'Two friends at school'
          ],
          'True friends stand by us in hard times'),
      L3Q(
          'A poem shows a farmer sowing seeds in a drought, waiting patiently, and finally seeing green shoots. Its theme is...',
          [
            'Drought is common in summer',
            'Patience and hope are rewarded',
            'Farmers should use tractors'
          ],
          'Patience and hope are rewarded'),
      L3Q(
          "Which detail best builds the theme 'Hard work leads to success' in a story about a girl training for a race?",
          [
            'Her shoes are blue',
            'The track is near a river',
            'She wakes at 5 a.m. every day to train'
          ],
          'She wakes at 5 a.m. every day to train'),
    ],
    const ['Theme: a big idea about life'],
  ),
  _l(
    2,
    "Author's craft and word choice",
    'See how word choice and figures of speech create effects.',
    'Reading',
    "Author's craft",
    "Word choice creates effect: 'stormed' feels angrier than 'walked'.",
    const [
      L3Q(
          'Which sentence shows anger most strongly?',
          [
            'She slammed the door and stormed out.',
            'She closed the door and left.',
            'She went out through the door.'
          ],
          'She slammed the door and stormed out.'),
      L3Q(
          "'The classroom was a beehive before the bell.' This metaphor suggests the classroom was...",
          ['full of honey', 'completely silent', 'busy and buzzing with noise'],
          'busy and buzzing with noise'),
      L3Q("'Her smile was as bright as the morning sun.' Which figure of speech is this?",
          ['Metaphor', 'Simile', 'Personification'], 'Simile'),
      L3Q(
          "Why might a writer say 'the old house sighed in the wind' instead of 'the old house made a noise'?",
          [
            'To give the house human feeling and mood',
            'To make the sentence shorter',
            'To state an exact fact'
          ],
          'To give the house human feeling and mood'),
      L3Q('Which word describes a careful spender in a negative way?',
          ['thrifty', 'economical', 'miserly'], 'miserly'),
    ],
    const ['stormed / walked', 'simile and metaphor'],
  ),
  _l(
    3,
    'Arguments and bias',
    'Judge reasons and spot one-sided writing.',
    'Reading',
    'Argument and bias',
    'An argument gives a claim and reasons. Bias is one-sided language or leaving out facts. Ask: is the evidence fair?',
    const [
      L3Q(
          "The claim is 'Our school should have a weekly library period.' Which is the strongest supporting reason?",
          [
            'Libraries have many shelves',
            'Regular reading improves vocabulary and marks',
            'My cousin likes books'
          ],
          'Regular reading improves vocabulary and marks'),
      L3Q(
          'Which sentence shows bias?',
          [
            'Our team won four of its six matches.',
            'The match began at 4 p.m.',
            'Our team is the best; the rest are useless.'
          ],
          'Our team is the best; the rest are useless.'),
      L3Q(
          "'Don't buy from that shop; the owner is a cheat and everything there is stale.' What is wrong with this argument?",
          [
            'It attacks the owner and gives no evidence',
            'It uses too many facts',
            'It is too short to be an argument'
          ],
          'It attacks the owner and gives no evidence'),
      L3Q(
          "An advert says '9 out of 10 cricketers drink Zing', but it asked only 10 players paid by the company. The flaw is...",
          [
            'a large, fair survey',
            'a small, biased sample',
            'too many questions'
          ],
          'a small, biased sample'),
      L3Q(
          'Which claim is a fact, not an opinion?',
          [
            'Summer is the best season.',
            'Cricket is more exciting than football.',
            'Water boils at 100°C at sea level.'
          ],
          'Water boils at 100°C at sea level.'),
    ],
    const ['fact vs opinion'],
  ),
  _l(
    4,
    'Modifiers and voice',
    'Fix misplaced or dangling modifiers and use active and passive voice.',
    'Grammar',
    'Modifiers and voice',
    'A modifier must sit next to the word it describes. Active voice: the doer acts. Passive: the action is done to something.',
    const [
      L3Q(
          'Which sentence has a dangling modifier?',
          [
            'Tired after school, Meena slept early.',
            'Running for the bus, I dropped my bag.',
            'Running for the bus, my bag fell open.'
          ],
          'Running for the bus, my bag fell open.'),
      L3Q(
          "Choose the clearest version of: 'I saw a snake in the yard with a long tail.'",
          [
            'I saw a snake with a long tail in the yard.',
            'With a long tail, I saw a snake in the yard.',
            'In the yard with a long tail, I saw a snake.'
          ],
          'I saw a snake with a long tail in the yard.'),
      L3Q(
          "Change to the passive voice: 'The students planted trees.'",
          [
            'Trees planted the students.',
            'Trees were planted by the students.',
            'Trees are planted by the students.'
          ],
          'Trees were planted by the students.'),
      L3Q(
          'Which sentence is in the active voice?',
          [
            'The meal was prepared by the cook.',
            'The meal has been prepared.',
            'The cook prepared the meal.'
          ],
          'The cook prepared the meal.'),
      L3Q(
          'Which sentence suits the passive voice best because the doer is unknown?',
          [
            'My bicycle was stolen last night.',
            'The thief stole my bicycle last night.',
            'I lost my bicycle last night.'
          ],
          'My bicycle was stolen last night.'),
    ],
    const ['Passive: Trees were planted'],
  ),
  _l(
    5,
    'Tenses in reported speech',
    'Move the tense back when reporting what someone said.',
    'Grammar',
    'Reported speech',
    'In reported speech the tense moves back: is becomes was, will becomes would, can becomes could.',
    const [
      L3Q(
          "Ravi said, 'I am hungry.' Choose the correct reported speech.",
          [
            'Ravi said that I was hungry.',
            'Ravi said that he will be hungry.',
            'Ravi said that he was hungry.'
          ],
          'Ravi said that he was hungry.'),
      L3Q(
          "Meena said, 'I will call you tomorrow.' Choose the correct report.",
          [
            'She said she would call me the next day.',
            'She said she will call you tomorrow.',
            'She said I would call her the next day.'
          ],
          'She said she would call me the next day.'),
      L3Q(
          "Arjun said, 'I have finished my homework.' Choose the correct report.",
          [
            'He said I had finished my homework.',
            'He said he had finished his homework.',
            'He said he would finish his homework.'
          ],
          'He said he had finished his homework.'),
      L3Q(
          "'Where do you live?' she asked me. Choose the correct report.",
          [
            'She asked me where did I live.',
            'She asked me where I lived.',
            'She asked me where you lived.'
          ],
          'She asked me where I lived.'),
      L3Q("In reported speech, 'can' usually changes to...",
          ['should', 'will', 'could'], 'could'),
    ],
    const ['is -> was, will -> would'],
  ),
  _l(
    6,
    'Subject-verb agreement',
    'Choose the verb that agrees with the true subject.',
    'Grammar',
    'Agreement',
    "The verb agrees with the true subject, not the nearby noun. 'Each' takes a singular verb; with 'nor' use the nearer subject.",
    const [
      L3Q('The books on the shelf ___ new.', ['is', 'was', 'are'], 'are'),
      L3Q('Each of the students ___ a notebook.', ['have', 'has', 'are'],
          'has'),
      L3Q('Neither the students nor the teacher ___ present today.',
          ['is', 'are', 'were'], 'is'),
      L3Q('Mathematics ___ my favourite subject.', ['are', 'is', 'were'], 'is'),
      L3Q('My brother and my best friend ___ coming to the match.',
          ['is', 'has', 'are'], 'are'),
    ],
    const ['Each of the students has'],
  ),
  _l(
    7,
    'Summary and paraphrase',
    'Tell a summary from a paraphrase.',
    'Writing',
    'Summary and paraphrase',
    'A summary is shorter and keeps only the main points. A paraphrase restates all the ideas in your own words.',
    const [
      L3Q(
          "Original: 'Heavy rain flooded the village, so classes were shut for a week.' Which is the best summary?",
          [
            'Rain is good for crops.',
            'Floods shut the village school for a week.',
            'The village looks lovely in rain.'
          ],
          'Floods shut the village school for a week.'),
      L3Q(
          "Which is a paraphrase of 'The cricketer practised tirelessly before the match'?",
          [
            'The player trained very hard before the game.',
            'Cricket matches need tireless practice.',
            'The cricketer rested before the match.'
          ],
          'The player trained very hard before the game.'),
      L3Q(
          'What is the main difference between a summary and a paraphrase?',
          [
            'A summary uses exactly the same words',
            'A paraphrase is always shorter',
            'A summary is shorter; a paraphrase is not'
          ],
          'A summary is shorter; a paraphrase is not'),
      L3Q(
          'A passage explains how bees make honey. Which sentence does NOT belong in its summary?',
          [
            'Bees turn nectar into honey in the hive.',
            'My favourite honey brand is the sweetest.',
            'Worker bees collect nectar from flowers.'
          ],
          'My favourite honey brand is the sweetest.'),
      L3Q(
          "Which is a good paraphrase of 'Time and tide wait for no man'?",
          [
            'Tides rise higher at night.',
            'Wait patiently for the tide.',
            'Time never stops for anyone, so do not delay.'
          ],
          'Time never stops for anyone, so do not delay.'),
    ],
    const ['summary = short, paraphrase = same ideas'],
  ),
  _l(
    8,
    'Judging sources',
    'Decide how far a source can be trusted.',
    'Reading',
    'Credibility of sources',
    'Ask who wrote it, whether they know the subject, if evidence is given, and how recent it is. Trusted sources agree.',
    const [
      L3Q(
          "For a report on India's space missions, which source is most reliable?",
          [
            "A friend's social media post",
            'An anonymous blog comment',
            'The official ISRO website'
          ],
          'The official ISRO website'),
      L3Q(
          "A forward says: 'Doctors hate this! Cures every illness in one day!' Which clue shows it is not credible?",
          [
            'It makes a huge claim with no evidence',
            'It is written in short sentences',
            'It was received on a phone'
          ],
          'It makes a huge claim with no evidence'),
      L3Q(
          "Which source is best for this year's board exam dates?",
          [
            'A rumour in a class group',
            "The board's official notice",
            'A coaching poster from 2015'
          ],
          "The board's official notice"),
      L3Q(
          'Why should you check whether an author is an expert on the topic?',
          [
            'Experts are more likely to be accurate',
            'Experts always write longer articles',
            'Experts never make mistakes'
          ],
          'Experts are more likely to be accurate'),
      L3Q(
          "A shampoo company's own website says its shampoo is 'the best in the world'. How far should you trust this claim?",
          [
            'Fully, because companies know their product',
            'Less, because the seller gains from the claim',
            'Fully, because the site looks colourful'
          ],
          'Less, because the seller gains from the claim'),
    ],
    const ['Who wrote it? Is there evidence?'],
  ),
  _l(
    9,
    'Persuasive appeals',
    'Recognise appeals to logic, emotion and trust in a speech.',
    'Writing',
    'Persuasion',
    "Logos uses facts and reasons, pathos stirs feelings, and ethos builds trust through the speaker's credibility.",
    const [
      L3Q(
          "'Surveys of 500 students show that 8 hours of sleep raises marks by 10%.' This mainly appeals to...",
          ['emotion (pathos)', 'logic (facts and data)', 'trust (credibility)'],
          'logic (facts and data)'),
      L3Q(
          "'Imagine a small puppy shivering alone in the cold tonight.' This mainly appeals to...",
          ['logic (facts and data)', 'trust (credibility)', 'emotion (pathos)'],
          'emotion (pathos)'),
      L3Q(
          "'As a doctor with twenty years' experience, I urge you to wash your hands.' This mainly appeals to...",
          ['trust (credibility)', 'emotion (pathos)', 'logic (facts and data)'],
          'trust (credibility)'),
      L3Q(
          'Which sentence in a speech on school cleanliness appeals to logic?',
          [
            'Picture sad children in dirty lanes.',
            'Trust me; I have cleaned for years.',
            'Clean schools mean fewer sick days.'
          ],
          'Clean schools mean fewer sick days.'),
      L3Q(
          'A speaker wants listeners to trust her. Which would help most?',
          [
            'Mentioning her years of work on the topic',
            'Speaking as fast as possible',
            'Showing a very sad picture'
          ],
          'Mentioning her years of work on the topic'),
    ],
    const ['logos, pathos, ethos'],
  ),
  _l(
    10,
    'Conflict, climax, resolution',
    'Name the parts of a story plot.',
    'Reading',
    'Story elements',
    'Conflict is the problem the character faces. The climax is the turning point. The resolution shows how it ends.',
    const [
      L3Q(
          'Mohan wants to join the school team but is afraid of the strict coach. What is the conflict?',
          [
            'The team plays on Saturday',
            'His wish to join against his fear',
            'Mohan owns new shoes'
          ],
          'His wish to join against his fear'),
      L3Q(
          "'Lata hears the dam crack. She races to the bell and rings it. All escape. Next day they rebuild.' Which part is the climax?",
          [
            'Lata hears the dam crack',
            'They rebuild the next day',
            'Lata acts and rings the bell'
          ],
          'Lata acts and rings the bell'),
      L3Q(
          'Which describes the resolution of a story?',
          [
            'The problem is solved and the tale ends',
            'The problem first appears',
            'Characters and setting are introduced'
          ],
          'The problem is solved and the tale ends'),
      L3Q(
          'Which is an example of a person-versus-nature conflict?',
          [
            'Two friends quarrel over a game',
            'A fisherman battles a cyclone to reach shore',
            'A boy doubts his own courage'
          ],
          'A fisherman battles a cyclone to reach shore'),
      L3Q('The part of a story that shows the characters, place and time is called the...',
          ['climax', 'resolution', 'exposition'], 'exposition'),
    ],
    const ['conflict -> climax -> resolution'],
  ),
]);
