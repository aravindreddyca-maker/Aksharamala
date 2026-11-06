import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/exam/exam_store.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late TempEnv env;
  setUp(() async => env = await TempEnv.create());
  tearDown(() async => env.dispose());

  ExamData sample() => ExamData(
        certificates: [
          Certificate(
            id: 'AKS-L1-20260101-ABCD',
            childId: 'kid',
            displayName: 'Asha',
            level: 1,
            issuedAt: DateTime(2026, 1, 1),
            attemptId: 'a',
          ),
        ],
        settings: const {'kid': ChildExamSettings(defaultPassPercent: 70)},
      );

  test('no file: starts empty with status missing', () async {
    final store = env.newStore();
    final d = await store.load();
    expect(d.attempts, isEmpty);
    expect(store.lastLoadStatus, ExamLoadStatus.missing);
    expect(await env.examFile.exists(), isFalse);
  });

  test('saves a version field and round-trips', () async {
    final store = env.newStore();
    await store.save(sample());
    final raw =
        jsonDecode(await env.examFile.readAsString()) as Map<String, dynamic>;
    expect(raw['version'], examStoreVersion);
    final back = await env.newStore().load();
    expect(back.certificates.single.id, 'AKS-L1-20260101-ABCD');
    expect(back.settings['kid']!.defaultPassPercent, 70);
    expect(env.fileNames(), isNot(contains('exams.json.tmp')));
  });

  test('writes a rolling .bak holding the previous good save', () async {
    final store = env.newStore();
    await store.save(sample());
    expect(File('${env.examFile.path}.bak').existsSync(), isFalse);
    await store.save(const ExamData());
    final bak =
        jsonDecode(await File('${env.examFile.path}.bak').readAsString())
            as Map;
    expect((bak['certificates'] as List).length, 1);
    final main = jsonDecode(await env.examFile.readAsString()) as Map;
    expect((main['certificates'] as List).length, 0);
  });

  test('corrupt main file is preserved and the .bak is used', () async {
    final store = env.newStore();
    await store.save(sample());
    await store.save(sample()); // makes a .bak
    await env.examFile.writeAsString('{ not json');
    final fresh = env.newStore();
    final d = await fresh.load();
    expect(fresh.lastLoadStatus, ExamLoadStatus.recoveredFromBackup);
    expect(d.certificates.length, 1);
    final kept =
        env.fileNames().where((n) => n.contains('.unreadable.')).toList();
    expect(kept.length, 1);
    final keptFile = File('${env.dir.path}/${kept.single}');
    expect(await keptFile.readAsString(), '{ not json');
  });

  test('corrupt file and no usable backup: starts empty, damaged file kept',
      () async {
    await env.examFile.writeAsString('garbage');
    await File('${env.examFile.path}.bak').writeAsString('also garbage');
    final store = env.newStore();
    final d = await store.load();
    expect(store.lastLoadStatus, ExamLoadStatus.unreadableStartedEmpty);
    expect(d.attempts, isEmpty);
    expect(env.fileNames().where((n) => n.contains('.unreadable.')).length, 1);
    expect(await env.examFile.readAsString(),
        'garbage'); // not overwritten by load
  });

  test('a file from a newer version is treated as unreadable, not guessed at',
      () async {
    await env.examFile
        .writeAsString(jsonEncode({'version': examStoreVersion + 1}));
    final store = env.newStore();
    await store.load();
    expect(store.lastLoadStatus, ExamLoadStatus.unreadableStartedEmpty);
  });

  test('a corrupt main file never overwrites a good backup on the next save',
      () async {
    final store = env.newStore();
    await store.save(sample());
    await store.save(sample());
    await env.examFile.writeAsString('broken');
    await store.save(const ExamData());
    // The broken file was not copied over .bak.
    final bak =
        jsonDecode(await File('${env.examFile.path}.bak').readAsString())
            as Map;
    expect((bak['certificates'] as List).length, 1);
  });

  test('never touches progress.json', () async {
    await env.progressFile
        .writeAsString('{"version":2,"profiles":[],"progress":{}}');
    final before = await env.progressFile.readAsBytes();
    final store = env.newStore();
    await store.save(sample());
    await store.save(sample());
    await env.examFile.writeAsString('broken');
    await store.load();
    expect(await env.progressFile.readAsBytes(), before);
    expect(env.fileNames().any((n) => n.startsWith('progress.json.')), isFalse);
  });
}
