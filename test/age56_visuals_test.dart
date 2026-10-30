import 'dart:io';

import 'package:aksharamala/src/batch/age56_content.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/widgets/learning_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reducedMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  test('all curriculum media paths resolve and completeness is honest', () {
    var incomplete = 0;
    final activities = <LearningVisualActivity>{};
    for (final lesson in allAge56Lessons) {
      activities.add(lesson.media.activity);
      for (final path in [
        ...lesson.media.images.values,
        ...lesson.media.audio,
        ...lesson.media.animations,
      ]) {
        if (path == 'code-native') continue;
        expect(File(path).existsSync(), isTrue,
            reason: '${lesson.id} references $path');
      }
      expect(
          lesson.media.isVisuallyComplete, lesson.media.missingImages.isEmpty,
          reason: lesson.id);
      if (!lesson.media.isVisuallyComplete) incomplete++;
      expect(lesson.media.pronunciationVerified, isFalse, reason: lesson.id);
    }
    expect(incomplete, greaterThan(0),
        reason: 'Absent production art must not be called complete.');
    expect(
      activities,
      containsAll(<LearningVisualActivity>{
        LearningVisualActivity.pictureWordMatch,
        LearningVisualActivity.phonicsBlend,
        LearningVisualActivity.letterCombination,
        LearningVisualActivity.wordBuilding,
        LearningVisualActivity.counting,
        LearningVisualActivity.dragArithmetic,
        LearningVisualActivity.guidedTracing,
      }),
    );
  });

  test('asset manifest contains one row per imported lesson', () {
    final rows = File('audit/AGE_5_6_ASSET_MANIFEST.csv').readAsLinesSync();
    expect(rows, hasLength(allAge56Lessons.length + 1));
    for (final lesson in allAge56Lessons) {
      expect(
          rows.where((row) => row.startsWith('${lesson.id},')), hasLength(1));
    }
  });

  test('new production illustrations are compact WebP assets', () {
    final files =
        Directory('assets/images/age56').listSync().whereType<File>().toList();
    expect(files, hasLength(54));
    for (final file in files) {
      expect(file.path.endsWith('.webp'), isTrue, reason: file.path);
      expect(file.lengthSync(), lessThan(100 * 1024), reason: file.path);
      expect(file.readAsBytesSync().take(4), [0x52, 0x49, 0x46, 0x46],
          reason: file.path);
    }
  });

  testWidgets('all reusable activity widgets render with large native text',
      (tester) async {
    await tester.pumpWidget(_host(SingleChildScrollView(
      child: Column(children: const [
        PictureWordMatchingVisual(
          words: ['cat'],
          images: {'cat': 'assets/images/quiz/cat.png'},
          color: Colors.indigo,
        ),
        PhonicsBlendingVisual(
          title: 'C + A + T',
          examples: ['cat'],
          color: Colors.indigo,
        ),
        LetterCombinationVisual(
          expression: 'క + ా = కా',
          color: Colors.indigo,
        ),
        LetterCombinationVisual(
          expression: 'क + ा = का',
          color: Colors.indigo,
        ),
        LetterCombinationVisual(
          expression: 'க + ா = கா',
          color: Colors.indigo,
        ),
        WordBuildingVisual(sentence: 'I can read', color: Colors.indigo),
        CountingLearningVisual(expression: 'Count 5', color: Colors.indigo),
        DragArithmeticVisual(expression: '5 + 2', color: Colors.indigo),
        GuidedTracingVisual(
          glyph: 'A',
          color: Colors.indigo,
          child: SizedBox(width: 120, height: 80),
        ),
      ]),
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('కా'), findsOneWidget);
    expect(find.text('का'), findsOneWidget);
    expect(find.text('கா'), findsOneWidget);
    expect(find.byType(DragTarget<int>), findsOneWidget);
  });

  testWidgets('reduced-motion mode produces zero activity animation duration',
      (tester) async {
    await tester.pumpWidget(_host(
      const PhonicsBlendingVisual(
        title: 'CAT',
        examples: ['cat'],
        color: Colors.indigo,
      ),
      reducedMotion: true,
    ));
    expect(
        learningMotionDuration(tester.element(find.byType(AnimatedSwitcher))),
        Duration.zero);
    expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero);
  });

  testWidgets('all referenced illustrations decode on a phone-sized screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final paths = allAge56Lessons
        .expand((lesson) => lesson.media.images.values)
        .toSet()
        .toList()
      ..sort();
    await tester.pumpWidget(_host(SingleChildScrollView(
      child: Column(children: [
        for (final path in paths)
          SizedBox(
            height: 120,
            child: Image.asset(path, fit: BoxFit.contain, cacheWidth: 216),
          ),
      ]),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNWidgets(paths.length));
  });
}
