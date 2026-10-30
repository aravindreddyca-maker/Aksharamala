import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Number Galaxy is English only for now: what a child reads AND what the
/// phone says.
class _S extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

final _indic = RegExp(r'[ऀ-ॿ஀-௿ఀ-౿]');

void main() {
  Future<List<Lesson>> allNumberLessons() async {
    final c = AppController(store: _S());
    await c.initialise();
    return [
      for (final stage in ExperienceStage.values)
        ...() {
          c.activeProfile = ChildProfile(
              id: 'x', name: 'x', age: stage.representativeAge, avatar: 'lion');
          return c.worlds.firstWhere((w) => w.id == 'numbers').lessons;
        }(),
      ...numbersBatch,
    ];
  }

  test('every Number Galaxy lesson is spoken in English', () async {
    final lessons = await allNumberLessons();
    expect(lessons.length, greaterThan(20));
    for (final l in lessons) {
      expect(l.locale.startsWith('en'), isTrue, reason: '${l.id} ${l.locale}');
      expect(_indic.hasMatch(l.speech), isFalse, reason: '${l.id} speech');
      if (l is BatchLesson) {
        for (final s in l.steps) {
          expect(_indic.hasMatch(s.speech), isFalse, reason: '${l.id} step');
          expect(_indic.hasMatch(s.prompt), isFalse, reason: '${l.id} prompt');
        }
      }
    }
  });

  test('every Number Galaxy lesson reads in English', () async {
    for (final l in await allNumberLessons()) {
      for (final text in [
        l.title,
        l.subtitle,
        l.challenge,
        l.answer,
        ...l.options,
        l.symbol,
      ]) {
        expect(_indic.hasMatch(text), isFalse, reason: '${l.id}: "$text"');
      }
    }
  });

  test('Number Names asks for the English word', () {
    final names = curriculum
        .firstWhere((w) => w.id == 'numbers')
        .lessons
        .firstWhere((l) => l.id == 'num-names');
    expect(names.options, ['five', 'three', 'seven']);
    expect(names.answer, 'five');
    expect(names.speech, 'Five.');
  });
}
