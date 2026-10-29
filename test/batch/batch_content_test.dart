import 'dart:io';

import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/content/content_loader.dart';
import 'package:aksharamala/src/content/content_models.dart';
import 'package:aksharamala/src/content/content_validator.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:flutter_test/flutter_test.dart';

final _telugu = RegExp(r'[ఀ-౿]');
final _latin = RegExp(r'[A-Za-z]');

void main() {
  final loaded = loadContentDirectory('content/pack_v2/content');
  final records = <String, LessonRecord>{
    for (final p in loaded.packs)
      for (final l in p.lessons) l.id: l,
  };
  final validation = ContentValidator().validate(loaded.packs);

  LessonRecord rec(String id) {
    final r = records[id];
    expect(r, isNotNull, reason: 'pack has no record "$id"');
    return r!;
  }

  group('the batch', () {
    test('has 10 Telugu lessons and Number Galaxy 0 to 10', () {
      expect(teluguBatch.length, 10);
      expect(numbersBatch.length, 11);
      expect(numbersBatch.map((l) => l.symbol), [
        for (var n = 0; n <= 10; n++) '$n',
      ]);
    });

    test('lesson ids are unique and do not collide with existing quests', () {
      final ids = allBatchLessons.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
      final existing = {
        for (final w in curriculum) ...w.lessons.map((l) => l.id),
      };
      expect(ids.where(existing.contains), isEmpty);
    });

    test('every lesson has the shape a child can play', () {
      for (final l in allBatchLessons) {
        expect(l.steps.first.kind, StepKind.listen, reason: l.id);
        expect(l.questions, isNotEmpty, reason: l.id);
        expect(l.steps.where((s) => s.kind == StepKind.write).length, 2,
            reason: '${l.id}: one guided and one independent writing step');
        expect(l.steps.last.kind, StepKind.write, reason: l.id);
        expect(
          l.steps
              .where((s) => s.kind == StepKind.write)
              .map((s) => s.writeMode),
          [WriteMode.guided, WriteMode.independent],
          reason: l.id,
        );
      }
    });

    test('writing is practice: no writing step is required', () {
      for (final l in allBatchLessons) {
        for (final s in l.steps.where((s) => s.kind == StepKind.write)) {
          expect(s.kind.isRequired, isFalse);
        }
        expect(l.questions.every((s) => s.kind != StepKind.write), isTrue);
      }
    });
  });

  group('answers', () {
    test('every question has a right answer among unique options', () {
      for (final l in allBatchLessons) {
        for (final s in l.questions) {
          expect(s.options.length, greaterThanOrEqualTo(2), reason: l.id);
          expect(s.options.toSet().length, s.options.length,
              reason: '${l.id} ${s.kind} has duplicate options');
          expect(s.options, contains(s.answer), reason: '${l.id} ${s.kind}');
          expect(s.answer, isNotEmpty);
        }
      }
    });

    test('Telugu answers match the pack record they come from', () {
      for (final l in teluguBatch) {
        final r = rec(l.id);
        final pick = l.steps.firstWhere((s) => s.kind == StepKind.pickLetter);
        expect(pick.answer, r.target, reason: l.id);
        expect(pick.answer, r.correctAnswer, reason: l.id);
        expect(pick.options.toSet(), r.options!.toSet(), reason: l.id);
        for (final w in l.steps.where((s) => s.kind == StepKind.pickWord)) {
          final v = rec(w.sourceRecord!);
          expect(w.answer, v.target);
          expect(w.answer, v.correctAnswer);
          expect(w.options.toSet(), v.options!.toSet());
          expect(w.answer.startsWith(pick.answer), isTrue,
              reason: '${l.id}: the picture word must start with the letter');
        }
      }
    });

    test('number answers are right', () {
      for (final l in numbersBatch) {
        final n = int.parse(l.symbol);
        final qty = l.steps.firstWhere((s) => s.kind == StepKind.pickQuantity);
        final count = l.steps.firstWhere((s) => s.kind == StepKind.count);
        final cmp = l.steps.firstWhere((s) => s.kind == StepKind.compare);
        expect(qty.answer, '$n');
        expect(count.answer, '$n');
        expect(count.quantity, n);
        for (final o in [...qty.options, ...count.options]) {
          final v = int.parse(o);
          expect(v, inInclusiveRange(0, 10));
        }
        expect(numbersAround(n).length, 3);
        expect(numbersAround(n).toSet().length, 3);
        expect(numbersAround(n), contains('$n'));
        final nums = cmp.options.map(int.parse).toList();
        expect(nums.length, 2);
        expect(nums, contains(n));
        final bigger = cmp.prompt.contains('bigger');
        expect(
            int.parse(cmp.answer),
            bigger
                ? nums.reduce((a, b) => a > b ? a : b)
                : nums.reduce((a, b) => a < b ? a : b),
            reason: l.id);
      }
    });

    test('the pack agrees: count and recognise records for each number', () {
      for (final l in numbersBatch) {
        final n = int.parse(l.symbol);
        final c = rec(l.sourceRecords[0]);
        final r = rec(l.sourceRecords[1]);
        expect(c.type, 'count_objects');
        expect(c.quantity, n);
        expect(c.correctAnswer, '$n');
        expect(r.type, 'numeral_recognition');
        expect(r.target, '$n');
        expect(r.correctAnswer, '$n');
      }
    });
  });

  group('source records', () {
    test('every record the lessons name exists in the pack', () {
      for (final l in allBatchLessons) {
        for (final id in l.sourceRecords) {
          rec(id);
        }
        for (final s in l.steps) {
          if (s.sourceRecord != null) rec(s.sourceRecord!);
        }
      }
    });

    test('the pack records behind the questions are text-complete drafts', () {
      // Never build a child lesson on a placeholder, outline or blueprint.
      for (final l in allBatchLessons) {
        for (final s in l.questions) {
          final r = rec(s.sourceRecord!);
          final level = validation.readiness['${r.module.name}/${r.id}'];
          expect(
            level == Readiness.draft || level == Readiness.needsMedia,
            isTrue,
            reason: '${l.id}: ${r.id} is $level',
          );
        }
      }
    });

    test(
        'writing steps point at handwriting placeholders, so they are practice',
        () {
      for (final l in allBatchLessons) {
        for (final s in l.steps.where((s) => s.kind == StepKind.write)) {
          final r = rec(s.sourceRecord!);
          expect(r.isHandwriting, isTrue, reason: s.sourceRecord);
          expect(r.handwriting!.hasStrokes, isFalse);
          expect(r.handwriting!.masteryAwardEnabled, isFalse);
          expect(r.handwriting!.glyph, s.glyph, reason: s.sourceRecord);
        }
      }
    });

    test('numbers 0-10 point at the right writing records', () {
      for (var n = 0; n <= 10; n++) {
        final g = rec(numberWriteRecord(n, WriteMode.guided));
        final i = rec(numberWriteRecord(n, WriteMode.independent));
        expect(g.type, 'guided_tracing');
        expect(i.type, 'independent_writing');
        expect(g.handwriting!.glyph, '$n');
        expect(i.handwriting!.glyph, '$n');
      }
    });
  });

  group('Telugu choices', () {
    test('rare letters and letters with no picture word are not forced', () {
      final ids = teluguBatch.map((l) => l.id).toList();
      expect(ids, isNot(contains('telugu-recognise-007')),
          reason: 'ఋ is left for later');
      final e = teluguBatch.firstWhere((l) => l.symbol == 'ఎ');
      expect(e.steps.any((s) => s.kind == StepKind.pickWord), isFalse);
      expect(e.sourceRecords.any((r) => r.contains('vocab')), isFalse);
    });

    test('the lessons run in the order proposed', () {
      expect(teluguBatch.map((l) => l.symbol),
          ['అ', 'ఆ', 'ఇ', 'ఈ', 'ఉ', 'ఊ', 'ఎ', 'ఏ', 'ఐ', 'ఒ']);
    });

    test('pictures that are claimed exist on disk', () {
      for (final path in {
        ...teluguWordPictures.values,
        ...batchQuestArt.values,
      }) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('only words with a real picture get one', () {
      for (final l in teluguBatch) {
        for (final s in l.steps.where((s) => s.kind == StepKind.pickWord)) {
          expect(s.pictures.keys.every(s.options.contains), isTrue);
          expect(s.pictures.keys.every(teluguWordPictures.containsKey), isTrue);
        }
      }
    });
  });

  group('prerequisites', () {
    test('each resolves to an earlier lesson of the same world', () {
      for (final world in [teluguBatch, numbersBatch]) {
        final seen = <String>{};
        for (final l in world) {
          for (final p in l.prerequisites) {
            expect(seen, contains(p), reason: '${l.id} needs $p first');
          }
          seen.add(l.id);
        }
        expect(world.first.prerequisites, isEmpty);
        for (var i = 1; i < world.length; i++) {
          expect(world[i].prerequisites, [world[i - 1].id]);
        }
      }
    });
  });

  group('language of what the child reads and hears', () {
    test('Telugu lessons speak and write Telugu, with no stray Latin', () {
      for (final l in teluguBatch) {
        expect(l.locale, 'te-IN');
        for (final s in l.steps) {
          expect(_telugu.hasMatch(s.prompt), isTrue, reason: s.prompt);
          expect(_latin.hasMatch(s.prompt), isFalse, reason: s.prompt);
          expect(_telugu.hasMatch(s.speech), isTrue, reason: s.speech);
          expect(_latin.hasMatch(s.speech), isFalse, reason: s.speech);
        }
        expect(_latin.hasMatch(l.title), isFalse);
        expect(_latin.hasMatch(l.subtitle), isFalse);
      }
    });

    test('Number Galaxy is English, as decided for maths', () {
      for (final l in numbersBatch) {
        expect(l.locale, 'en-IN');
        for (final s in l.steps) {
          expect(_telugu.hasMatch(s.prompt), isFalse, reason: s.prompt);
          expect(s.prompt.trim(), isNotEmpty);
          expect(s.speech.trim(), isNotEmpty);
        }
      }
    });

    test('the right messages exist in both languages', () {
      for (final t in [BatchText.telugu, BatchText.english]) {
        for (final s in [
          t.rightMessage,
          t.tryAgainMessage,
          t.goodWriting,
          t.writeAgain,
          t.strokeHint,
          t.directionHint,
          t.orderHint,
          t.strokesHint,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      }
      expect(_telugu.hasMatch(BatchText.telugu.directionHint), isTrue);
      expect(_latin.hasMatch(BatchText.telugu.directionHint), isFalse);
      expect(BatchText.forLocale('te-IN'), same(BatchText.telugu));
      expect(BatchText.forLocale('en-IN'), same(BatchText.english));
    });
  });

  group('writing messages in every language', () {
    final hindi = RegExp(r'[\u0900-\u097F]');
    final tamil = RegExp(r'[\u0B80-\u0BFF]');
    List<String> all(BatchText t) => [
          t.rightMessage,
          t.tryAgainMessage,
          t.goodWriting,
          t.writeAgain,
          t.strokeHint,
          t.directionHint,
          t.orderHint,
          t.strokesHint,
        ];

    test('Hindi and Tamil use their own script and no Latin', () {
      for (final s in all(BatchText.hindi)) {
        expect(hindi.hasMatch(s), isTrue, reason: s);
        expect(_latin.hasMatch(s), isFalse, reason: s);
      }
      for (final s in all(BatchText.tamil)) {
        expect(tamil.hasMatch(s), isTrue, reason: s);
        expect(_latin.hasMatch(s), isFalse, reason: s);
      }
    });

    test('each locale gets its own messages', () {
      expect(BatchText.forLocale('hi-IN'), same(BatchText.hindi));
      expect(BatchText.forLocale('ta-IN'), same(BatchText.tamil));
      expect(BatchText.forLocale('te-IN'), same(BatchText.telugu));
      expect(BatchText.forLocale('en-US'), same(BatchText.english));
    });
  });

  group('existing curriculum is untouched', () {
    test('worldsWithBatch only appends, never changes or removes', () {
      final merged = worldsWithBatch(curriculum);
      expect(merged.map((w) => w.id), curriculum.map((w) => w.id));
      for (var i = 0; i < curriculum.length; i++) {
        final base = curriculum[i];
        final now = merged[i];
        expect(now.lessons.take(base.lessons.length).toList(), base.lessons,
            reason: base.id);
        final added = now.lessons.length - base.lessons.length;
        expect(added, batchByWorld[base.id]?.length ?? 0, reason: base.id);
      }
      expect(
          identical(merged.firstWhere((w) => w.id == 'hindi'),
              curriculum.firstWhere((w) => w.id == 'hindi')),
          isTrue);
    });

    test('the original quest ids are exactly as before', () {
      expect(
        [for (final w in curriculum) ...w.lessons.map((l) => l.id)],
        [
          'en-a',
          'en-word',
          'en-trace',
          'en-story',
          'te-a',
          'te-word',
          'te-trace',
          'te-story',
          'hi-a',
          'hi-word',
          'hi-trace',
          'hi-story',
          'ta-a',
          'ta-word',
          'ta-trace',
          'ta-story',
          'num-count',
          'num-add',
          'num-subtract',
          'num-names',
        ],
      );
    });
  });
}
