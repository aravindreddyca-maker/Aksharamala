import 'dart:convert';

import 'package:aksharamala/src/art/art_registry.dart';
import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Map<String, dynamic> _onePlan() {
  final root = jsonDecode(pilotJson()) as Map<String, dynamic>;
  return Map<String, dynamic>.from(
    jsonDecode(jsonEncode((root['lessons'] as List).first)) as Map,
  );
}

TeachingPlanLibrary _lib(Map<String, dynamic> lesson) =>
    TeachingPlanLibrary.parse([
      jsonEncode({
        'schema_version': 1,
        'status': 't',
        'lessons': [lesson],
      }),
    ]);

void main() {
  test('the real pilot file loads clean: five plans, no issues', () {
    final lib = pilotLibrary();
    expect(lib.issues, isEmpty);
    expect(
      lib.plansById.keys.toSet(),
      {'en-a', 'te-a', 'hi-a', 'ta-a', 'num-add'},
    );
    final add = lib.planFor('num-add')!;
    expect(add.prerequisites, ['num-count']);
    expect(add.mastery.checkPass, 2);
    expect(add.mastery.maxRemediationCycles, 2);
    expect(add.check, hasLength(3));
    expect(lib.planFor('en-a')!.guided.first.task, isNotEmpty);
  });

  test('a lesson with no plan has none', () {
    expect(pilotLibrary().planFor('en-b'), isNull);
    expect(TeachingPlanLibrary.empty.planFor('en-a'), isNull);
  });

  test('answer must be one of the options', () {
    final l = _onePlan();
    (l['guided'] as List).first['answer'] = 'ZZZ';
    final lib = _lib(l);
    expect(lib.planFor('en-a'), isNull);
    expect(lib.issues.join(), contains('is not in its options'));
  });

  test('duplicate ids are refused', () {
    final l = _onePlan();
    (l['practice'] as List).first['id'] = (l['guided'] as List).first['id'];
    expect(_lib(l).issues.join(), contains('duplicate id'));
  });

  test('an unknown visual type falls back to none instead of crashing', () {
    final l = _onePlan();
    (l['introduce'] as List).first['visual'] = {'type': 'hologram'};
    final lib = _lib(l);
    expect(lib.planFor('en-a')!.introduce.first.visual.type, VisualType.none);
  });

  test('picture without an asset is refused', () {
    final l = _onePlan();
    (l['introduce'] as List).first['visual'] = {'type': 'picture', 'asset': ''};
    expect(_lib(l).issues.join(), contains('no asset'));
  });

  test('pass mark above the number of check items is refused', () {
    final l = _onePlan();
    l['mastery']['check_pass'] = 9;
    expect(_lib(l).issues.join(), contains('check_pass'));
  });

  test('bad JSON is reported, not thrown', () {
    final lib = TeachingPlanLibrary.parse(['{not json', '[]']);
    expect(lib.isEmpty, isTrue);
    expect(lib.issues, hasLength(2));
  });

  test('every art registry spec is well formed', () {
    for (final e in artRegistry.entries) {
      expect(e.key, e.value.id);
      expect(e.value.width, greaterThan(0));
    }
  });
}
