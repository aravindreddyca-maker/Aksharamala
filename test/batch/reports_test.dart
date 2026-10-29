import 'dart:io';

import 'package:aksharamala/src/batch/asset_manifest.dart';
import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/content/content_loader.dart';
import 'package:aksharamala/src/content/content_validator.dart';
import 'package:aksharamala/src/content/coverage_report.dart';
import 'package:flutter_test/flutter_test.dart';

/// The committed reports must match what the code says.
///
///   flutter test --dart-define=WRITE_REPORTS=true test/batch/reports_test.dart
///
/// rewrites them; without the flag this test fails when they are stale.
const _write = bool.fromEnvironment('WRITE_REPORTS');

String _norm(String s) => s.replaceAll('\r\n', '\n');

void check(String path, String content) {
  final file = File(path);
  if (_write) {
    file.writeAsStringSync(content);
    return;
  }
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  expect(_norm(file.readAsStringSync()), _norm(content),
      reason: '$path is out of date. Regenerate with '
          'flutter test --dart-define=WRITE_REPORTS=true test/batch/reports_test.dart');
}

void main() {
  final manifest = AssetManifest(
    allBatchLessons,
    exists: (p) => File(p).existsSync(),
  );

  test('the asset manifest report is up to date', () {
    check('content/reports/ASSET_MANIFEST.md', manifest.toMarkdown());
    check('content/reports/ASSET_MANIFEST.csv', manifest.toCsv());
  });

  test('the coverage report is up to date', () {
    final loaded = loadContentDirectory('content/pack_v2/content');
    final v = ContentValidator().validate(loaded.packs);
    final merged =
        ValidationReport([...loaded.parseIssues, ...v.issues], v.readiness);
    final cov =
        CoverageReport(loaded.packs, merged, playable: manifest.summary());
    check('content/reports/COVERAGE_REPORT.md', cov.toMarkdown());
    check('content/reports/COVERAGE_REPORT.csv', cov.toCsv());
  });

  group('the manifest says what is true', () {
    test('every Telugu picture word is known and in the pack', () {
      for (final p in manifest.pictures) {
        expect(teluguWords.containsKey(p.word), isTrue);
      }
    });

    test('a present picture is a real file, a missing one is not', () {
      for (final p in manifest.pictures) {
        expect(File(p.suggestedFile).existsSync(), p.status == 'present',
            reason: p.word);
      }
    });

    test('numbers need no new pictures; Telugu needs some', () {
      expect(manifest.pictures.any((p) => p.missing), isTrue);
      expect(manifest.pictures.where((p) => !p.missing).length,
          teluguWordPictures.length);
    });

    test('no audio, and no verified stroke order, is claimed', () {
      expect(manifest.audio, isNotEmpty);
      expect(manifest.templates.any((t) => t.orderVerified), isFalse);
      expect(verifiedTemplateCount, 0);
    });

    test('every glyph written has a row, templates for numbers only', () {
      final glyphs = manifest.templates.map((t) => t.glyph).toSet();
      expect(glyphs.length, 10 + 11);
      for (final t in manifest.templates) {
        expect(t.hasTemplate, t.script == 'numbers', reason: t.glyph);
      }
    });
  });
}
