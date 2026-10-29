import 'package:aksharamala/src/content/content_loader.dart';
import 'package:aksharamala/src/content/content_models.dart';
import 'package:aksharamala/src/content/content_validator.dart';
import 'package:aksharamala/src/content/coverage_report.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the importer over the real pack in `content/pack_v2`.
///
/// These numbers are the pack's own (COVERAGE_SUMMARY.csv). If the pack is
/// replaced, this test should fail loudly and be updated on purpose.
void main() {
  final loaded = loadContentDirectory('content/pack_v2/content');
  final report = ContentValidator().validate(loaded.packs);
  final merged = ValidationReport(
    [...loaded.parseIssues, ...report.issues],
    report.readiness,
  );
  ContentPack pack(ContentModule m) =>
      loaded.packs.firstWhere((p) => p.module == m);

  test('all five packs load with no parse problems', () {
    expect(loaded.packs.map((p) => p.module).toSet(),
        ContentModule.values.toSet());
    expect(loaded.parseIssues, isEmpty);
  });

  test('record counts match the pack summary', () {
    expect(pack(ContentModule.telugu).lessons.length, 1490);
    expect(pack(ContentModule.tamil).lessons.length, 597);
    expect(pack(ContentModule.hindi).lessons.length, 1071);
    expect(pack(ContentModule.english).lessons.length, 210);
    expect(pack(ContentModule.numbers).lessons.length, 1164);
  });

  test('lesson ids are unique across the whole pack', () {
    final ids = [for (final p in loaded.packs) ...p.lessons.map((l) => l.id)];
    expect(ids.toSet().length, ids.length);
  });

  test('the pack has no structural errors', () {
    expect(merged.errors, isEmpty, reason: merged.errors.take(5).join('\n'));
  });

  test('every prerequisite resolves to a lesson or a declared gate', () {
    expect(merged.byCode('W101'), isEmpty);
    for (final p in loaded.packs) {
      final ids = p.lessons.map((l) => l.id).toSet();
      for (final l in p.lessons) {
        for (final pre in l.prerequisites) {
          expect(ids.contains(pre) || p.gates.containsKey(pre), isTrue,
              reason: '${l.id} -> $pre');
        }
      }
    }
  });

  test('the mastery gate points at declared chapters that have lessons', () {
    for (final p in loaded.packs) {
      final used = p.lessons.map((l) => l.chapter).toSet();
      for (final g in p.gates.entries) {
        for (final c in g.value) {
          expect(p.chapters, contains(c), reason: '${p.module.name} $c');
          expect(used, contains(c),
              reason: '${p.module.name} gate $c is empty');
        }
      }
    }
  });

  test('no handwriting record can award mastery or score strokes yet', () {
    for (final p in loaded.packs) {
      for (final l in p.lessons.where((l) => l.handwriting != null)) {
        expect(l.handwriting!.masteryAwardEnabled, isFalse, reason: l.id);
        expect(l.handwriting!.strokeValidationEnabled, isFalse, reason: l.id);
        expect(l.handwriting!.hasStrokes, isFalse, reason: l.id);
      }
    }
  });

  test('every record is flagged for educator review; nothing is verified', () {
    for (final p in loaded.packs) {
      for (final l in p.lessons) {
        expect(l.educatorReview, 'required', reason: l.id);
        expect(l.audio?.verifiedByNativeSpeaker, isNot(true), reason: l.id);
      }
    }
  });

  test('every record gets a readiness level', () {
    final total = loaded.packs.fold<int>(0, (n, p) => n + p.lessons.length);
    expect(merged.readiness.length, total);
  });

  test('readiness totals', () {
    final c = CoverageReport(loaded.packs, merged).byModuleReadiness();
    int sum(Readiness r) => c.values.fold<int>(0, (n, m) => n + m[r]!);
    expect(sum(Readiness.placeholder), 3184);
    expect(sum(Readiness.outline), 88);
    expect(sum(Readiness.blueprint), 133);
    expect(sum(Readiness.needsMedia), 94);
    expect(sum(Readiness.draft), 1033);
  });

  test('there is no teachable language content for ages 5-6', () {
    final cov = CoverageReport(loaded.packs, merged);
    for (final m in [
      ContentModule.telugu,
      ContentModule.tamil,
      ContentModule.hindi,
      ContentModule.english,
    ]) {
      expect(cov.teachableByBand(pack(m))['5-6'], 0, reason: m.name);
    }
    expect(cov.teachableByBand(pack(ContentModule.numbers))['5-6'], 482);
  });

  test('the reports render', () {
    final cov = CoverageReport(loaded.packs, merged);
    expect(cov.toMarkdown(), contains('No record is'));
    expect(cov.toCsv().split('\n').first,
        'module,chapter,age_band,readiness,count');
  });
}
