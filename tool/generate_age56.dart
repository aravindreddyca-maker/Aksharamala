import 'dart:convert';
import 'dart:io';

String q(String value) =>
    "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r'\n').replaceAll('\r', r'\r')}'";

String list(Iterable<String> values) => '[${values.map(q).join(', ')}]';

String localeFor(String module) => switch (module) {
      'telugu' => 'te-IN',
      'hindi' => 'hi-IN',
      'tamil' => 'ta-IN',
      'english' => 'en-US',
      'numbers' => 'en-IN',
      _ => throw ArgumentError(module),
    };

String worldFor(String module) => module == 'numbers' ? 'numbers' : module;

String difficultyFor(int level) =>
    level >= 3 ? 'LessonDifficulty.intermediate' : 'LessonDifficulty.beginner';

String activityFor(String topic, String skill) {
  if (skill == 'blend_cvc') {
    return 'phonicsBlend';
  }
  if ({'combine_vowel_sign', 'combine_matra', 'form_uyirmei'}.contains(skill)) {
    return 'letterCombination';
  }
  if ({'recognize_sight_word', 'read_simple_sentence', 'read_short_sentence'}
      .contains(skill)) {
    return 'wordBuilding';
  }
  if (skill == 'distinguish_letter_shapes') {
    return 'guidedTracing';
  }
  if ({'add_within_20', 'subtract_within_20'}.contains(skill)) {
    return 'dragArithmetic';
  }
  if ({
    'identify_tens_and_ones',
    'identify_tens',
    'compare_numbers',
    'compare_two_digit_numbers',
    'extend_pattern',
    'continue_number_pattern',
  }.contains(skill)) {
    return 'counting';
  }
  return 'pictureWordMatch';
}

const conceptImages = <String, String>{
  'cat': 'assets/images/quiz/cat.png',
  'dog': 'assets/images/age56/dog.webp',
  'कुत्ता': 'assets/images/age56/dog.webp',
  'కుక్క': 'assets/images/age56/dog.webp',
  'fish': 'assets/images/age56/fish.webp',
  'pin': 'assets/images/age56/pin.webp',
  'pig': 'assets/images/age56/pig.webp',
  'sit': 'assets/images/age56/sit.webp',
  'tree': 'assets/images/age56/tree.webp',
  'மரம்': 'assets/images/age56/tree.webp',
  'sun': 'assets/images/age56/sun.webp',
  'सूरज': 'assets/images/age56/sun.webp',
  'triangle': 'assets/images/age56/triangle.webp',
  'square': 'assets/images/age56/square.webp',
  'rectangle': 'assets/images/age56/rectangle.webp',
  'circle': 'assets/images/age56/circle.webp',
  'morning': 'assets/images/age56/morning.webp',
  'longer': 'assets/images/age56/longer.webp',
  'rupees': 'assets/images/age56/rupees.webp',
  'man': 'assets/images/age56/man.webp',
  'cap': 'assets/images/age56/cap.webp',
  'pet': 'assets/images/age56/pet.webp',
  'top': 'assets/images/age56/top.webp',
  'bug': 'assets/images/age56/insect.webp',
  'कीड़ा': 'assets/images/age56/insect.webp',
  'కీటకం': 'assets/images/age56/insect.webp',
  'किताब': 'assets/images/age56/book.webp',
  'कूड़ा': 'assets/images/age56/garbage.webp',
  'केला': 'assets/images/age56/banana.webp',
  'कंघी': 'assets/images/age56/comb.webp',
  'कौआ': 'assets/images/age56/crow.webp',
  'కాకి': 'assets/images/age56/crow.webp',
  'माला': 'assets/images/age56/garland.webp',
  'पानी': 'assets/images/age56/water.webp',
  'बादल': 'assets/images/age56/cloud.webp',
  'तीन': 'assets/images/age56/three.webp',
  'राजा': 'assets/images/age56/king.webp',
  'காடு': 'assets/images/age56/forest.webp',
  'கீரை': 'assets/images/age56/leafy_greens.webp',
  'குடம்': 'assets/images/age56/water_pot.webp',
  'கூடு': 'assets/images/age56/nest.webp',
  'கெண்டை': 'assets/images/age56/catfish.webp',
  'கேணி': 'assets/images/age56/well.webp',
  'கை': 'assets/images/age56/hand.webp',
  'கொடி': 'assets/images/age56/flag.webp',
  'கோழி': 'assets/images/age56/chicken.webp',
  'சங்கு': 'assets/images/age56/conch.webp',
  'தலை': 'assets/images/age56/head.webp',
  'நரி': 'assets/images/age56/fox.webp',
  'பல்': 'assets/images/age56/tooth.webp',
  'வானம்': 'assets/images/age56/sky.webp',
  'కిరణం': 'assets/images/age56/ray.webp',
  'కూర': 'assets/images/age56/vegetables.webp',
  'కెరటం': 'assets/images/age56/wave.webp',
  'కేక': 'assets/images/age56/cake.webp',
  'కొంగ': 'assets/images/age56/crane.webp',
  'కోతి': 'assets/images/age56/monkey.webp',
  'పాలు': 'assets/images/age56/milk.webp',
  'काला': 'assets/images/age56/black.webp',
  // 'कैसा' (how / what kind) has no picture yet: the first candidate showed a
  // boy building a toy car, which does not convey the concept.
  'कोयल': 'assets/images/age56/cuckoo.webp',
  // 'चाचा' (paternal uncle) has no picture yet: the first candidate showed a
  // father with his son, which teaches the wrong relationship.
  'pen': 'assets/images/quiz/te_pen.webp',
  'नाव': 'assets/images/quiz/boat.png',
  'गाय': 'assets/images/quiz/te_cow.webp',
  'கல்': 'assets/images/quiz/ta_stone.webp',
  'கிளி': 'assets/images/stories/parrot.webp',
  'చిలుక': 'assets/images/stories/parrot.webp',
  'हाथी': 'assets/images/quiz/te_elephant.webp',
  'யானை': 'assets/images/quiz/te_elephant.webp',
  'பூனை': 'assets/images/quiz/cat.png',
  'mango': 'assets/images/quiz/mango.png',
  'आम': 'assets/images/quiz/mango.png',
  'ఆవు': 'assets/images/quiz/te_cow.webp',
};

Map<String, String> imagesFor(Iterable<String> concepts) => {
      for (final concept in concepts)
        if (conceptImages.containsKey(concept))
          concept: conceptImages[concept]!,
    };

List<String> requiredImagesFor(String activity, List<String> examples) {
  if ({'guidedTracing', 'counting', 'dragArithmetic', 'wordBuilding'}
      .contains(activity)) {
    return const [];
  }
  return examples.take(1).toList();
}

void validateDocument(Map<String, dynamic> doc) {
  final module = doc['module'] as String;
  if (doc['age_band'] != '5-6') {
    throw FormatException('$module has the wrong age band');
  }
  final lessons = (doc['lessons'] as List).cast<Map<String, dynamic>>();
  final ids = lessons.map((lesson) => lesson['id'] as String).toList();
  if (ids.toSet().length != ids.length) {
    throw FormatException('$module has duplicate lesson IDs');
  }
  final prompts = <String>{};
  final placeholder = RegExp(
    r'placeholder|todo|tbd|lorem|coming soon',
    caseSensitive: false,
  );
  for (final lesson in lessons) {
    final id = lesson['id'] as String;
    if (placeholder.hasMatch(jsonEncode(lesson))) {
      throw FormatException('$id contains placeholder content');
    }
    if (lesson['module'] != module || lesson['age_band'] != '5-6') {
      throw FormatException('$id has mismatched module or age');
    }
    for (final field in ['title', 'objective', 'topic', 'skill']) {
      if ((lesson[field] as String?)?.trim().isEmpty ?? true) {
        throw FormatException('$id is missing $field');
      }
    }
    final steps = (lesson['steps'] as List).cast<Map<String, dynamic>>();
    final teaches = steps.where((step) => step['type'] == 'teach').toList();
    final practices =
        steps.where((step) => step['type'] == 'practice').toList();
    if (teaches.length != 1 || practices.length != 1) {
      throw FormatException('$id needs one teach and one practice step');
    }
    if ((teaches.single['text'] as String?)?.trim().isEmpty ?? true) {
      throw FormatException('$id has empty teaching content');
    }
    final practice = practices.single;
    final prompt = practice['prompt'] as String;
    if (!prompts.add(prompt)) {
      throw FormatException('$module has duplicate prompt: $prompt');
    }
    final options = (practice['options'] as List).cast<String>();
    final answer = practice['answer'] as String;
    if (options.length < 2 ||
        options.toSet().length != options.length ||
        !options.contains(answer)) {
      throw FormatException('$id has invalid answer options');
    }
    for (final prerequisite
        in (lesson['prerequisites'] as List).cast<String>()) {
      if (!ids.contains(prerequisite) || prerequisite == id) {
        throw FormatException('$id has invalid prerequisite $prerequisite');
      }
    }
  }
}

void main() {
  final source = Directory('content/age56');
  final files = source
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.length != 5) {
    throw StateError('Expected five Age 5–6 JSON files, found ${files.length}');
  }

  final out = StringBuffer()
    ..writeln(
        '// GENERATED from content/age56/*.json by tool/generate_age56.dart.')
    ..writeln(
        '// Do not edit lesson records by hand; update the JSON and regenerate.')
    ..writeln("import '../models.dart';")
    ..writeln("import 'batch_lesson.dart';")
    ..writeln();

  final byWorld = <String, List<String>>{};
  final manifestRows = <String>[
    'lesson_id,module,activity,required_images,resolved_images,missing_images,audio,animations,visually_complete'
  ];
  var total = 0;
  for (final file in files) {
    final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    validateDocument(doc);
    final module = doc['module'] as String;
    final lessons = (doc['lessons'] as List).cast<Map<String, dynamic>>();
    final variable = '${module}Age56Lessons';
    byWorld[worldFor(module)] = [variable];
    out.writeln('final List<BatchLesson> $variable = List.unmodifiable([');
    String? previous;
    for (final lesson in lessons) {
      total++;
      final id = lesson['id'] as String;
      final steps = (lesson['steps'] as List).cast<Map<String, dynamic>>();
      final teach = steps.firstWhere((s) => s['type'] == 'teach');
      final practice = steps.firstWhere((s) => s['type'] == 'practice');
      final supplied = (lesson['prerequisites'] as List).cast<String>();
      final effective = supplied.isNotEmpty
          ? supplied
          : previous == null
              ? const <String>[]
              : [previous];
      final answer = practice['answer'] as String;
      final sourceExamples = ((lesson['examples'] as List?) ?? const [])
          .map((example) => example is String
              ? example
              : (example as Map<String, dynamic>)['word'] as String)
          .toList();
      final topic = lesson['topic'] as String;
      final shapeConcept = module == 'numbers' && topic == 'shapes'
          ? (lesson['title'] as String).replaceFirst('Shape:', '').trim()
          : null;
      final examples = sourceExamples.isNotEmpty
          ? sourceExamples
          : shapeConcept == null
              ? [answer]
              : [shapeConcept];
      final activity = activityFor(
        topic,
        lesson['skill'] as String,
      );
      final concepts = <String>{
        ...examples,
        ...(practice['options'] as List).cast<String>(),
      };
      final images = imagesFor(concepts);
      final requiredImages = requiredImagesFor(activity, examples);
      final missingImages = requiredImages
          .where((concept) => !images.containsKey(concept))
          .toList();
      final level = lesson['level'] as int;
      out
        ..writeln('  BatchLesson(')
        ..writeln('    id: ${q(id)},')
        ..writeln('    title: ${q(lesson['title'] as String)},')
        ..writeln('    subtitle: ${q(lesson['objective'] as String)},')
        ..writeln(
            "    kind: LessonKind.${module == 'numbers' ? 'game' : 'words'},")
        ..writeln(
            '    symbol: ${q(examples.isNotEmpty ? examples.first : answer)},')
        ..writeln('    locale: ${q(localeFor(module))},')
        ..writeln("    ageBand: '5-6',")
        ..writeln('    difficultyLevel: ${difficultyFor(level)},')
        ..writeln('    learningObjective: ${q(lesson['objective'] as String)},')
        ..writeln('    prerequisites: ${list(effective)},')
        ..writeln('    topic: ${q(topic)},')
        ..writeln('    skill: ${q(lesson['skill'] as String)},')
        ..writeln('    examples: ${list(examples)},')
        ..writeln('    educatorReviewVerified: false,')
        ..writeln('    media: LessonMedia(')
        ..writeln('      activity: LearningVisualActivity.$activity,')
        ..writeln('      images: {')
        ..writeAll(images.entries.map(
          (entry) => '        ${q(entry.key)}: ${q(entry.value)},\n',
        ))
        ..writeln('      },')
        ..writeln('      requiredImages: ${list(requiredImages)},')
        ..writeln('      pronunciationVerified: false,')
        ..writeln('    ),')
        ..writeln('    sourceRecords: [${q(id)}],')
        ..writeln('    steps: [')
        ..writeln('      BatchStep(')
        ..writeln('        kind: StepKind.listen,')
        ..writeln('        prompt: ${q(teach['text'] as String)},')
        ..writeln(
            '        speech: ${q((teach['speech'] ?? teach['text']) as String)},')
        ..writeln(
            '        glyph: ${q(examples.isNotEmpty ? examples.first : answer)},')
        ..writeln('        sourceRecord: ${q(id)},')
        ..writeln('      ),')
        ..writeln('      BatchStep(')
        ..writeln('        kind: StepKind.choice,')
        ..writeln('        prompt: ${q(practice['prompt'] as String)},')
        ..writeln('        speech: ${q(practice['prompt'] as String)},')
        ..writeln(
            '        options: ${list((practice['options'] as List).cast<String>())},')
        ..writeln('        answer: ${q(answer)},')
        ..writeln('        pictures: {')
        ..writeAll(images.entries.map(
          (entry) => '          ${q(entry.key)}: ${q(entry.value)},\n',
        ))
        ..writeln('        },')
        ..writeln('        sourceRecord: ${q(id)},')
        ..writeln('      ),')
        ..writeln('    ],')
        ..writeln('  ),');
      previous = id;
      String csv(Iterable<String> values) =>
          '"${values.join('|').replaceAll('"', '""')}"';
      manifestRows.add([
        id,
        module,
        activity,
        csv(requiredImages),
        csv(images.keys),
        csv(missingImages),
        '""',
        '"code-native"',
        missingImages.isEmpty.toString(),
      ].join(','));
    }
    out
      ..writeln(']);')
      ..writeln();
  }

  out
    ..writeln('final Map<String, List<BatchLesson>> age56ByWorld = {')
    ..writeAll(
        byWorld.entries.map((e) => '  ${q(e.key)}: ${e.value.single},\n'))
    ..writeln('};')
    ..writeln()
    ..writeln('List<BatchLesson> get allAge56Lessons => [')
    ..writeln('  for (final lessons in age56ByWorld.values) ...lessons,')
    ..writeln('];')
    ..writeln()
    ..writeln('const age56GeneratedLessonCount = $total;');

  File('lib/src/batch/age56_content.dart').writeAsStringSync(out.toString());
  File('audit/AGE_5_6_ASSET_MANIFEST.csv')
      .writeAsStringSync('${manifestRows.join('\n')}\n');
}
