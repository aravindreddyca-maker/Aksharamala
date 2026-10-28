import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('experience stages', () {
    test('maps every supported age to the correct stage', () {
      expect(stageForAge(3), ExperienceStage.explorer);
      expect(stageForAge(4), ExperienceStage.explorer);
      expect(stageForAge(5), ExperienceStage.creator);
      expect(stageForAge(6), ExperienceStage.creator);
      expect(stageForAge(7), ExperienceStage.scholar);
      expect(stageForAge(9), ExperienceStage.scholar);
      expect(stageForAge(10), ExperienceStage.champion);
      expect(stageForAge(12), ExperienceStage.champion);
    });
  });

  test('vertical slice has five distinct worlds and playable lessons', () {
    expect(curriculum.map((world) => world.id).toSet(),
        {'english', 'telugu', 'hindi', 'tamil', 'numbers'});
    for (final world in curriculum) {
      expect(world.lessons.length, greaterThanOrEqualTo(4));
      expect(world.lessons.every((lesson) => lesson.speech.isNotEmpty), isTrue);
      expect(world.lessons.any((lesson) => lesson.kind == LessonKind.tracing || lesson.kind == LessonKind.game), isTrue);
    }
  });

  test('number names contain English, Telugu, Hindi and Tamil', () {
    expect(numberNames.length, 10);
    for (final names in numberNames.values) {
      expect(names.keys.toSet(), {'en', 'te', 'hi', 'ta'});
      expect(names.values.every((name) => name.isNotEmpty), isTrue);
    }
  });
}

