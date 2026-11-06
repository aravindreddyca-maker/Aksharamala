import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/exam_store.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late TempEnv env;
  late TestClock clock;
  final bank = makeBank(lessons: 6, perLesson: 3); // 18 in w1, level 1

  setUp(() async {
    env = await TempEnv.create();
    clock = TestClock();
  });
  tearDown(() async => env.dispose());

  Future<ExamController> controller() async {
    final c = env.newController(bank: bank, clock: clock);
    await c.load();
    return c;
  }

  Future<ExamAttempt> start(ExamController c, ExamConfig config) async {
    final o = await c.startExam(config, seed: 5);
    expect(o, isA<StartExamStarted>(), reason: '$o');
    return (o as StartExamStarted).attempt;
  }

  test('start, answer, submit gives a result and history', () async {
    final c = await controller();
    final a = await start(c, cfg(count: 6));
    expect(a.questions.length, 6);
    expect(c.inProgressFor('kid')!.id, a.id);
    await answerAll(c, a, right: 5);
    clock.advance(const Duration(minutes: 3));
    final r = await c.submit(a.id);
    expect(r.obtainedMarks, 5);
    expect(r.passed, isTrue);
    expect(r.timeTakenSeconds, 180);
    expect(c.inProgressFor('kid'), isNull);
    expect(c.attemptsFor('kid').single.status, AttemptStatus.submitted);
    expect(c.resultsFor('kid').single.attemptId, a.id);
    expect(c.verifyResult(a.id), isTrue);
  });

  test('every answer is saved: a new controller resumes the unfinished attempt',
      () async {
    final c = await controller();
    final a = await start(c, cfg(count: 6));
    final q0 = a.questions[0];
    final q1 = a.questions[1];
    await c.answer(a.id, q0.id, 'B');
    await c.answer(a.id, q1.id, 'C');
    await c.answer(a.id, q1.id, 'A'); // changed mind

    final c2 = await controller(); // "app restarted"
    final resumed = c2.inProgressFor('kid')!;
    expect(resumed.id, a.id);
    expect(resumed.status, AttemptStatus.inProgress);
    expect(resumed.answers[q0.id]!.answer, 'B');
    expect(resumed.answers[q1.id]!.answer, 'A');
    expect(resumed.questions.map((q) => q.id), a.questions.map((q) => q.id));
    expect(resumed.questions.map((q) => q.options.join()),
        a.questions.map((q) => q.options.join()));
    // Starting again resumes instead of making a second attempt.
    final again = await c2.startExam(cfg(count: 6));
    expect(again, isA<StartExamResume>());
    expect((again as StartExamResume).attempt.id, a.id);
    expect(c2.data.attempts.length, 1);
  });

  test('invalid answers are refused', () async {
    final c = await controller();
    final a = await start(c, cfg(count: 4));
    final q = a.questions.first.id;
    expect(await c.answer(a.id, q, 'not an option'), isFalse);
    expect(await c.answer(a.id, 'nope#q9', 'A'), isFalse);
    expect(await c.answer('nope', q, 'A'), isFalse);
    expect(c.attemptById(a.id)!.answers, isEmpty);
    await c.submit(a.id);
    expect(await c.answer(a.id, q, 'A'), isFalse);
  });

  test(
      'time limit: answers after expiry are refused; submit still marks what was answered',
      () async {
    final c = await controller();
    final a = await start(c, cfg(count: 4, limit: 60));
    expect(
        await c.answer(a.id, a.questions[0].id, a.questions[0].correctAnswer),
        isTrue);
    clock.advance(const Duration(seconds: 61));
    expect(c.isExpired(c.attemptById(a.id)!), isTrue);
    expect(
        await c.answer(a.id, a.questions[1].id, a.questions[1].correctAnswer),
        isFalse);
    final r = await c.submit(a.id);
    expect(r.obtainedMarks, 1);
    expect(r.timeTakenSeconds, 60);
  });

  test('submit is idempotent', () async {
    final c = await controller();
    final a = await start(c, cfg(count: 6));
    await answerAll(c, a, right: 4);
    final r1 = await c.submit(a.id);
    clock.advance(const Duration(hours: 1));
    final r2 = await c.submit(a.id);
    expect(r2.checksum, r1.checksum);
    expect(r2.finishedAt, r1.finishedAt);
    expect(c.data.results.length, 1);
    expect(c.attemptById(a.id)!.finishedAt, r1.finishedAt);
    // Also across a restart.
    final c2 = await controller();
    final r3 = await c2.submit(a.id);
    expect(r3.checksum, r1.checksum);
    expect(c2.data.results.length, 1);
  });

  test('abandoned attempts cannot be submitted and make no result', () async {
    final c = await controller();
    final a = await start(c, cfg(count: 4));
    expect(await c.abandon(a.id), isTrue);
    expect(c.inProgressFor('kid'), isNull);
    expect(() => c.submit(a.id), throwsStateError);
    expect(c.data.results, isEmpty);
    // A new exam can start.
    await start(c, cfg(count: 4));
  });

  test('not enough questions: refusal with the available count, nothing saved',
      () async {
    final c = await controller();
    final o = await c.startExam(cfg(count: 40));
    expect(o, isA<StartExamNotEnoughQuestions>());
    expect((o as StartExamNotEnoughQuestions).available, 18);
    expect(c.data.attempts, isEmpty);
    expect(await env.examFile.exists(), isFalse);
  });

  group('retest policy', () {
    test('max attempts', () async {
      final c = await controller();
      const policy = RetestPolicy.maxAttempts(2);
      for (var i = 1; i <= 2; i++) {
        final a = await start(c, cfg(count: 6, policy: policy));
        expect(a.retestNumber, i);
        await c.submit(a.id);
      }
      final o = await c.startExam(cfg(count: 6, policy: policy));
      expect(o, isA<StartExamPolicyRefused>());
      // A different exam scope is unaffected.
      await start(
          c,
          cfg(
              count: 6,
              worlds: ['w1'],
              type: ExamType.finalLevel,
              policy: policy));
    });

    test('abandoned attempts do not use up attempts', () async {
      final c = await controller();
      const policy = RetestPolicy.maxAttempts(1);
      final a = await start(c, cfg(count: 6, policy: policy));
      await c.abandon(a.id);
      await start(c, cfg(count: 6, policy: policy));
    });

    test('wait hours', () async {
      final c = await controller();
      const policy = RetestPolicy.waitHours(24);
      final a = await start(c, cfg(count: 6, policy: policy));
      await c.submit(a.id);
      clock.advance(const Duration(hours: 23));
      final refused = await c.startExam(cfg(count: 6, policy: policy));
      expect(refused, isA<StartExamPolicyRefused>());
      expect((refused as StartExamPolicyRefused).retryAt,
          c.resultsFor('kid').single.finishedAt.add(const Duration(hours: 24)));
      clock.advance(const Duration(hours: 2));
      final b = await start(c, cfg(count: 6, policy: policy));
      expect(b.retestNumber, 2);
    });

    test('unlimited, and a retest prefers questions not asked last time',
        () async {
      final c = await controller();
      final a = await start(c, cfg(count: 9));
      await c.submit(a.id);
      final b = await start(c, cfg(count: 9));
      expect(b.retestNumber, 2);
      final first = {for (final q in a.questions) q.id};
      expect(b.questions.where((q) => first.contains(q.id)), isEmpty);
      await c.submit(b.id);
      final d = await start(c, cfg(count: 9));
      expect(d.retestNumber, 3);
    });
  });

  group('certificates', () {
    final fin = cfg(type: ExamType.finalLevel, worlds: ['w1'], count: 6);

    test(
        'issued once when a final exam is passed; id format; no repeat on a second pass',
        () async {
      final c = await controller();
      final a = await start(c, fin);
      await answerAll(c, a, right: 6);
      await c.submit(a.id);
      final cert = c.certificateFor('kid', 1)!;
      expect(cert.id, matches(RegExp(r'^AKS-L1-20261031-[0-9A-F]{4}$')));
      expect(cert.displayName, 'Asha');
      expect(cert.attemptId, a.id);
      expect(cert.issuedCount, 1);
      expect(cert.statement, contains('completed Level 1'));

      clock.advance(const Duration(days: 3));
      final b = await start(c, fin);
      await answerAll(c, b, right: 6);
      await c.submit(b.id);
      expect(c.certificatesFor('kid').length, 1);
      expect(c.certificateFor('kid', 1)!.id, cert.id);
      expect(c.certificateFor('kid', 1)!.issuedCount, 1);
    });

    test('reissue increments the counter only when asked', () async {
      final c = await controller();
      final a = await start(c, fin);
      await answerAll(c, a, right: 6);
      await c.submit(a.id);
      await c.submit(a.id);
      expect(c.certificateFor('kid', 1)!.issuedCount, 1);
      clock.advance(const Duration(days: 1));
      final again = await c.reissueCertificate('kid', 1);
      expect(again!.issuedCount, 2);
      expect(again.id, c.certificateFor('kid', 1)!.id);
      expect(c.certificatesFor('kid').length, 1);
      expect(await c.reissueCertificate('kid', 2), isNull);
      // Persisted.
      final c2 = await controller();
      expect(c2.certificateFor('kid', 1)!.issuedCount, 2);
    });

    test('none for a failed final, a passed chapter or subject exam', () async {
      final c = await controller();
      final failed = await start(c, fin);
      await answerAll(c, failed, right: 1);
      await c.submit(failed.id);
      final subject = await start(c, cfg(count: 6));
      await answerAll(c, subject, right: 6);
      await c.submit(subject.id);
      final chapter = await start(
          c,
          cfg(
              type: ExamType.chapter,
              worlds: [],
              lessonIds: ['L0', 'L1'],
              count: 6));
      await answerAll(c, chapter, right: 6);
      await c.submit(chapter.id);
      expect(c.certificatesFor('kid'), isEmpty);
      expect(c.readinessFor('kid', 1).ready, isFalse);
    });

    test('a separate certificate per level and per child', () async {
      final l2bank = [
        ...bank,
        ...makeBank(level: 2, lessons: 6, perLesson: 3, prefix: 'M')
      ];
      final c = env.newController(bank: l2bank, clock: clock);
      await c.load();
      for (final level in [1, 2]) {
        final o = await c
            .startExam(cfg(type: ExamType.finalLevel, level: level, count: 6));
        final a = (o as StartExamStarted).attempt;
        await answerAll(c, a, right: 6);
        await c.submit(a.id);
      }
      final o = await c
          .startExam(cfg(childId: 'sib', type: ExamType.finalLevel, count: 6));
      final s = (o as StartExamStarted).attempt;
      await answerAll(c, s, right: 6);
      await c.submit(s.id);
      expect(c.certificatesFor('kid').map((x) => x.level), [1, 2]);
      expect(c.certificatesFor('sib').length, 1);
    });

    test('readiness only after a passed final exam at that level', () async {
      final c = await controller();
      expect(c.readinessFor('kid', 1).ready, isFalse);
      final a = await start(c, fin);
      await answerAll(c, a, right: 2);
      await c.submit(a.id);
      final notYet = c.readinessFor('kid', 1);
      expect(notYet.ready, isFalse);
      expect(notYet.weakObjectives, isNotEmpty);
      final b = await start(c, fin);
      await answerAll(c, b, right: 6);
      await c.submit(b.id);
      expect(c.readinessFor('kid', 1).ready, isTrue);
    });

    test('a tampered stored result is not trusted for readiness', () async {
      final c = await controller();
      final a = await start(c, fin);
      await answerAll(c, a, right: 1);
      await c.submit(a.id);
      // Hand-edit exams.json: flip the result to a pass.
      final raw =
          jsonDecode(await env.examFile.readAsString()) as Map<String, dynamic>;
      final r = (raw['results'] as List).first as Map<String, dynamic>;
      r['passed'] = true;
      r['obtainedMarks'] = r['totalMarks'];
      (r['readiness'] as Map<String, dynamic>)['ready'] = true;
      await env.examFile.writeAsString(jsonEncode(raw));
      final c2 = await controller();
      expect(c2.verifyResult(a.id), isFalse);
      expect(c2.readinessFor('kid', 1).ready, isFalse);
    });
  });

  group('parent-marked questions', () {
    final pbank = [
      ...makeBank(lessons: 6, perLesson: 1),
      mq('W', 0, type: ExamQuestionType.parentMarked),
    ];
    final fin =
        cfg(type: ExamType.finalLevel, worlds: ['w1'], count: 7, parent: true);

    test('result waits, parent marks, result recalculates, certificate follows',
        () async {
      final c = env.newController(bank: pbank, clock: clock);
      await c.load();
      final a = (await c.startExam(fin, seed: 2) as StartExamStarted).attempt;
      await answerAll(c, a, right: 6);
      expect(await c.answer(a.id, 'W#q0', 'x'),
          isFalse); // not answerable by the child
      final r = await c.submit(a.id);
      expect(r.awaitingParentMarks, 1);
      expect(r.isProvisional, isTrue);
      expect(c.certificatesFor('kid'), isEmpty);
      expect(c.readinessFor('kid', 1).ready, isFalse);

      expect(await c.markParentQuestion(a.id, 'L0#q0', true),
          isNull); // not parent-marked
      final done = (await c.markParentQuestion(a.id, 'W#q0', true))!;
      expect(done.awaitingParentMarks, 0);
      expect(done.percent, 100);
      expect(done.passed, isTrue);
      expect(c.certificatesFor('kid').length, 1);
      expect(c.verifyResult(a.id), isTrue);
      expect(c.readinessFor('kid', 1).ready, isTrue);

      // Persisted.
      final c2 = env.newController(bank: pbank, clock: clock);
      await c2.load();
      expect(c2.resultFor(a.id)!.awaitingParentMarks, 0);
      expect(c2.attemptById(a.id)!.parentMarks['W#q0'], isTrue);
    });

    test('a failing mark gives no certificate', () async {
      final c = env.newController(bank: pbank, clock: clock);
      await c.load();
      final a = (await c.startExam(fin.copyWith(passPercent: 100), seed: 2)
              as StartExamStarted)
          .attempt;
      await answerAll(c, a, right: 6);
      await c.submit(a.id);
      final r = (await c.markParentQuestion(a.id, 'W#q0', false))!;
      expect(r.passed, isFalse);
      expect(c.certificatesFor('kid'), isEmpty);
    });
  });

  group('PIN', () {
    test('optional, 4 digits, salted hash stored, never the PIN', () async {
      final c = await controller();
      expect(c.hasPin('kid'), isFalse);
      expect(
          c.verifyPin('kid', '1234'), isTrue); // nothing set, nothing to check
      expect(await c.setPin('kid', '12'), isFalse);
      expect(await c.setPin('kid', 'abcd'), isFalse);
      expect(await c.setPin('kid', '12345'), isFalse);
      expect(await c.setPin('kid', '4821'), isTrue);
      expect(c.hasPin('kid'), isTrue);
      expect(c.verifyPin('kid', '4821'), isTrue);
      expect(c.verifyPin('kid', '4822'), isFalse);
      expect(c.verifyPin('kid', ''), isFalse);
      final text = await env.examFile.readAsString();
      expect(text.contains('4821'), isFalse);
      final s = c.settingsFor('kid');
      expect(s.pinSalt, isNotEmpty);
      expect(s.pinHash, isNot('4821'));
      // Other children are unaffected.
      expect(c.hasPin('sib'), isFalse);
    });

    test('change needs the current PIN; survives restart; clear works',
        () async {
      final c = await controller();
      await c.setPin('kid', '1111');
      final oldHash = c.settingsFor('kid').pinHash;
      expect(await c.setPin('kid', '2222'), isFalse);
      expect(await c.setPin('kid', '2222', currentPin: '9999'), isFalse);
      expect(c.verifyPin('kid', '1111'), isTrue);
      expect(await c.setPin('kid', '2222', currentPin: '1111'), isTrue);
      expect(c.verifyPin('kid', '1111'), isFalse);
      expect(c.verifyPin('kid', '2222'), isTrue);
      expect(c.settingsFor('kid').pinHash, isNot(oldHash));

      final c2 = await controller();
      expect(c2.verifyPin('kid', '2222'), isTrue);
      expect(c2.verifyPin('kid', '1111'), isFalse);
      expect(await c2.clearPin('kid', '0000'), isFalse);
      expect(await c2.clearPin('kid', '2222'), isTrue);
      expect(c2.hasPin('kid'), isFalse);
    });

    test('same PIN gets a different hash for different children (salt)',
        () async {
      final c = await controller();
      await c.setPin('kid', '1234');
      await c.setPin('sib', '1234');
      expect(c.settingsFor('kid').pinHash, isNot(c.settingsFor('sib').pinHash));
    });
  });

  test('default pass mark per child feeds new configs', () async {
    final c = await controller();
    expect(c.passPercentFor('kid'), 60);
    await c.setDefaultPassPercent('kid', 75);
    expect(
        c
            .buildConfig(
                childId: 'kid',
                level: 1,
                type: ExamType.subject,
                questionCount: 5)
            .passPercent,
        75);
    expect(
        c
            .buildConfig(
                childId: 'sib',
                level: 1,
                type: ExamType.subject,
                questionCount: 5)
            .passPercent,
        60);
    expect(() => c.setDefaultPassPercent('kid', 0), throwsArgumentError);
    final c2 = await controller();
    expect(c2.passPercentFor('kid'), 75);
  });

  test(
      'an exam never changes progress.json (bytes identical, no sibling files)',
      () async {
    final local = LocalStore(fileOverride: env.progressFile);
    await local.save(LocalSnapshot(
      profiles: const [
        ChildProfile(id: 'kid', name: 'Asha', age: 4, avatar: 'a', stars: 7)
      ],
      progress: {
        'kid': const ProgressRecord(
          completedLessons: {'en-a'},
          attempts: {'english': 3},
          correct: {'english': 2},
          lastPlayed: {},
          earnedBadges: {},
        ),
      },
    ));
    final before = await env.progressFile.readAsBytes();
    final filesBefore = env.fileNames();

    final c = await controller();
    final fin = cfg(type: ExamType.finalLevel, worlds: ['w1'], count: 6);
    final a = await start(c, fin);
    await answerAll(c, a, right: 6);
    await c.submit(a.id);
    await c.reissueCertificate('kid', 1);
    await c.setPin('kid', '1234');
    await c.setDefaultPassPercent('kid', 70);

    expect(await env.progressFile.readAsBytes(), before);
    final added =
        env.fileNames().where((n) => !filesBefore.contains(n)).toList();
    expect(added.every((n) => n.startsWith('exams.json')), isTrue,
        reason: '$added');
    // And the learning save still loads exactly as before.
    final snap = await local.load();
    expect(snap.profiles.single.stars, 7);
    expect(snap.progress['kid']!.completedLessons, {'en-a'});
  });

  test('history is per child, newest first', () async {
    final c = await controller();
    final a = await start(c, cfg(count: 4));
    await c.submit(a.id);
    clock.advance(const Duration(days: 1));
    final b = await start(c, cfg(count: 4));
    await c.submit(b.id);
    clock.advance(const Duration(days: 1));
    final other = await start(c, cfg(childId: 'sib', count: 4));
    await c.submit(other.id);
    expect(c.attemptsFor('kid').map((x) => x.id), [b.id, a.id]);
    expect(c.attemptsFor('sib').map((x) => x.id), [other.id]);
    expect(c.resultsFor('kid').length, 2);
  });

  test('exam data survives a damaged file via the backup', () async {
    final c = await controller();
    final a = await start(c, cfg(count: 4));
    await answerAll(c, a, right: 4);
    await c.submit(a.id);
    await File(env.examFile.path).writeAsString('{{{');
    final c2 = env.newController(bank: bank, clock: clock);
    await c2.load();
    expect(c2.loadStatus, ExamLoadStatus.recoveredFromBackup);
    expect(c2.data.attempts, isNotEmpty);
  });
}
