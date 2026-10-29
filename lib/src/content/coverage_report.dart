/// Builds the coverage report for a set of content packs.
///
/// It separates a lesson *template* from a lesson a child could use: the
/// headline record count is mostly handwriting targets, so every number here is
/// broken down by [Readiness] and by age band.
library;

import 'content_issue.dart';
import 'content_models.dart';
import 'content_validator.dart';
import 'playable_summary.dart';

const _bands = ['3-4', '5-6', '7-9', '10-12'];
const _levels = Readiness.values;

String _levelName(Readiness r) => switch (r) {
      Readiness.placeholder => 'handwriting placeholder',
      Readiness.outline => 'outline only',
      Readiness.blueprint => 'blueprint',
      Readiness.needsMedia => 'needs images',
      Readiness.draft => 'text-complete draft',
    };

class CoverageReport {
  CoverageReport(this.packs, this.validation, {this.playable});

  final List<ContentPack> packs;
  final ValidationReport validation;

  /// What the app can play today. When given, the report opens with it.
  final PlayableSummary? playable;

  Readiness readinessOf(LessonRecord l) =>
      validation.readiness['${l.module.name}/${l.id}']!;

  /// module -> readiness -> count
  Map<ContentModule, Map<Readiness, int>> byModuleReadiness() => {
        for (final p in packs)
          p.module: {
            for (final r in _levels)
              r: p.lessons.where((l) => readinessOf(l) == r).length,
          },
      };

  /// Lessons a child could meet once media is added: drafts and needs-images.
  /// Placeholders, outlines and blueprints are excluded.
  Iterable<LessonRecord> teachable(ContentPack p) => p.lessons.where((l) {
        final r = readinessOf(l);
        return r == Readiness.draft || r == Readiness.needsMedia;
      });

  Map<String, int> teachableByBand(ContentPack p) {
    final out = {for (final b in _bands) b: 0};
    for (final l in teachable(p)) {
      out[l.stage] = (out[l.stage] ?? 0) + 1;
    }
    return out;
  }

  Map<String, Map<Readiness, int>> byChapter(ContentPack p) {
    final out = <String, Map<Readiness, int>>{};
    for (final l in p.lessons) {
      final m =
          out.putIfAbsent(l.chapter, () => {for (final r in _levels) r: 0});
      m[readinessOf(l)] = m[readinessOf(l)]! + 1;
    }
    return out;
  }

  Map<String, int> byType(ContentPack p) {
    final out = <String, int>{};
    for (final l in p.lessons) {
      out[l.type] = (out[l.type] ?? 0) + 1;
    }
    return Map.fromEntries(
      out.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // -- Markdown -----------------------------------------------------------

  String toMarkdown({String generatedFor = 'content/pack_v2'}) {
    final b = StringBuffer();
    final total = packs.fold<int>(0, (n, p) => n + p.lessons.length);
    final byLevel = <Readiness, int>{for (final r in _levels) r: 0};
    for (final r in validation.readiness.values) {
      byLevel[r] = byLevel[r]! + 1;
    }

    b.writeln('# Curriculum coverage report');
    b.writeln();
    b.writeln('Source: `$generatedFor` (schema ${packs.first.schemaVersion}). '
        'Produced by the importer in `lib/src/content/`; regenerate with '
        '`flutter test --dart-define=WRITE_REPORTS=true test/batch/reports_test.dart`.');
    b.writeln();
    b.writeln(
        '**Read this first.** The pack holds **$total** lesson records, but '
        'a record is not a lesson. A lesson is only usable once its text, '
        'pictures, audio and native-educator review all exist. This report '
        'sorts every record by how far it is from that. **No record is '
        'published or verified.**');
    b.writeln();
    if (playable != null) _writePlayable(b);

    b.writeln('## 1. Records by readiness');
    b.writeln();
    b.writeln('| Module | Records | ${_levels.map(_levelName).join(' | ')} |');
    b.writeln('|---|---:|${_levels.map((_) => '---:').join('|')}|');
    final grid = byModuleReadiness();
    for (final p in packs) {
      final row = grid[p.module]!;
      b.writeln('| ${p.module.name} | ${p.lessons.length} | '
          '${_levels.map((r) => row[r]).join(' | ')} |');
    }
    b.writeln('| **All** | **$total** | '
        '${_levels.map((r) => '**${byLevel[r]}**').join(' | ')} |');
    b.writeln();
    b.writeln('- *handwriting placeholder*: a letter or number to be written, '
        'with **no stroke geometry**; cannot be scored or taught yet.');
    b.writeln('- *outline only*: a topic heading for authors, not a lesson.');
    b.writeln('- *blueprint*: key content is missing (the combined letter, the '
        'letters to arrange, practice items).');
    b.writeln(
        '- *needs images*: text is complete, the picture does not exist.');
    b.writeln('- *text-complete draft*: nothing missing in the text; still '
        'needs audio and native review.');
    b.writeln();

    b.writeln('## 2. Teachable content by age band');
    b.writeln();
    b.writeln('Text-complete drafts plus those waiting for images '
        '(placeholders, outlines and blueprints excluded).');
    b.writeln();
    b.writeln('| Module | 3–4 | 5–6 | 7–9 | 10–12 | Total |');
    b.writeln('|---|---:|---:|---:|---:|---:|');
    for (final p in packs) {
      final t = teachableByBand(p);
      final sum = t.values.fold<int>(0, (a, c) => a + c);
      b.writeln('| ${p.module.name} | ${t['3-4']} | ${t['5-6']} | '
          '${t['7-9']} | ${t['10-12']} | $sum |');
    }
    b.writeln();

    b.writeln('## 3. What kinds of lesson exist (per module)');
    for (final p in packs) {
      b.writeln();
      b.writeln('**${p.module.name}** — ${p.lessons.length} records');
      b.writeln();
      b.writeln('| Type | Records | Of which usable as drafts |');
      b.writeln('|---|---:|---:|');
      final types = byType(p);
      for (final e in types.entries) {
        final usable = p.lessons
            .where((l) =>
                l.type == e.key &&
                (readinessOf(l) == Readiness.draft ||
                    readinessOf(l) == Readiness.needsMedia))
            .length;
        b.writeln('| ${e.key} | ${e.value} | $usable |');
      }
    }
    b.writeln();

    b.writeln('## 4. Chapters');
    for (final p in packs) {
      b.writeln();
      b.writeln('**${p.module.name}**');
      b.writeln();
      b.writeln('| Chapter | ${_levels.map(_levelName).join(' | ')} |');
      b.writeln('|---|${_levels.map((_) => '---:').join('|')}|');
      final ch = byChapter(p);
      for (final e in ch.entries) {
        b.writeln(
            '| ${e.key} | ${_levels.map((r) => e.value[r]).join(' | ')} |');
      }
      final undeclared = ch.keys.where((c) => !p.chapters.contains(c)).toList();
      if (undeclared.isNotEmpty) {
        b.writeln();
        b.writeln('> **Defect:** lessons use chapter(s) '
            '`${undeclared.join('`, `')}` that the file never declares (E014).');
      }
      final empty = p.chapters.where((c) => !ch.containsKey(c)).toList();
      if (empty.isNotEmpty) {
        b.writeln();
        b.writeln('> Declared but **empty** chapters: ${empty.join(', ')}.');
      }
    }
    b.writeln();

    b.writeln('## 5. Missing media');
    b.writeln();
    b.writeln('| Module | Images needed | Images present | Audio recorded | '
        'Audio native-verified | Verified stroke paths |');
    b.writeln('|---|---:|---:|---:|---:|---:|');
    for (final p in packs) {
      final needImages = p.lessons.where((l) => l.assetKey != null).length;
      final haveImages = p.lessons
          .where((l) =>
              l.assetKey != null && readinessOf(l) != Readiness.needsMedia)
          .length;
      final rec =
          p.lessons.where((l) => l.audio?.recordedAudioAsset != null).length;
      final ver = p.lessons
          .where((l) => l.audio?.verifiedByNativeSpeaker == true)
          .length;
      final strokes =
          p.lessons.where((l) => l.handwriting?.hasStrokes == true).length;
      b.writeln(
          '| ${p.module.name} | $needImages | $haveImages | $rec | $ver | $strokes |');
    }
    b.writeln();

    b.writeln('## 6. Instruction language');
    b.writeln();
    b.writeln('| Module | Records | Instruction in the module language |');
    b.writeln('|---|---:|---:|');
    for (final p in packs) {
      final english = validation
          .byCode('W104')
          .where((i) => i.module == p.module.name)
          .length;
      final inLang = p.module.isRegionalScript
          ? p.lessons.length - english
          : p.lessons.length;
      final note = p.module.isRegionalScript ? '$inLang' : 'n/a (English)';
      b.writeln('| ${p.module.name} | ${p.lessons.length} | $note |');
    }
    b.writeln();

    b.writeln('## 7. Prerequisites');
    b.writeln();
    b.writeln('| Module | Records with a prerequisite | Prerequisite links | '
        'Links that are not lesson ids |');
    b.writeln('|---|---:|---:|---:|');
    for (final p in packs) {
      final withPre = p.lessons.where((l) => l.prerequisites.isNotEmpty).length;
      final links =
          p.lessons.fold<int>(0, (n, l) => n + l.prerequisites.length);
      final unresolved = validation
          .byCode('W101')
          .where((i) => i.module == p.module.name)
          .length;
      b.writeln(
          '| ${p.module.name} | $withPre of ${p.lessons.length} | $links | $unresolved |');
    }
    b.writeln();

    b.writeln('## 8. Answer options');
    b.writeln();
    b.writeln(
        '| Module | Multiple-choice records | Correct answer listed first | '
        '`shuffle_options` true |');
    b.writeln('|---|---:|---:|---:|');
    for (final p in packs) {
      final mcq = p.lessons.where((l) => l.options != null).toList();
      final first =
          mcq.where((l) => l.options!.first == l.correctAnswer).length;
      final shuffled = mcq.where((l) => l.shuffleOptions == true).length;
      b.writeln('| ${p.module.name} | ${mcq.length} | $first | $shuffled |');
    }
    b.writeln();
    b.writeln('The importer requires `shuffle_options`; the app must actually '
        'shuffle at play time (it does for the current 20 quests).');
    b.writeln();

    b.writeln('## 9. Validation results');
    b.writeln();
    b.writeln('| Rule | Meaning | Severity | Count |');
    b.writeln('|---|---|---|---:|');
    final counts = validation.countByCode();
    for (final e in counts.entries) {
      final sev =
          validation.issues.firstWhere((i) => i.code == e.key).severity.name;
      b.writeln(
          '| ${e.key} | ${contentRuleDescriptions[e.key] ?? ''} | $sev | ${e.value} |');
    }
    b.writeln();
    final errors = validation.errors.toList();
    if (errors.isEmpty) {
      b.writeln('**No structural errors.**');
    } else {
      b.writeln('**${errors.length} structural error(s):**');
      b.writeln();
      final grouped = <String, List<ContentIssue>>{};
      for (final e in errors) {
        grouped.putIfAbsent('${e.code} in ${e.module}', () => []).add(e);
      }
      for (final g in grouped.entries) {
        final ids = g.value.map((e) => e.lessonId ?? '—').toList();
        final shown = ids.length > 4
            ? '${ids.take(4).join(', ')}, … (${ids.length} records)'
            : ids.join(', ');
        b.writeln('- ${g.key}: ${g.value.first.message} — $shown');
      }
    }
    b.writeln();

    b.writeln('## 10. What this report does not tell you');
    b.writeln();
    b.writeln('- Whether any Telugu, Tamil or Hindi word, story, answer or '
        'script convention is **correct**. Structure and Unicode script are '
        'checked; meaning and pedagogy need native educators.');
    b.writeln('- Whether audio or pronunciation is right: none exists.');
    b.writeln('- Whether the age bands are right: they are the pack author\'s '
        'indicative labels.');
    return b.toString();
  }

  // -- playable -----------------------------------------------------------

  void _writePlayable(StringBuffer b) {
    final p = playable!;
    b.writeln('## 0. What is playable in the app today');
    b.writeln();
    b.writeln('Only the first batch is imported, behind the parent switch '
        '"Try the new lessons". Everything else in the pack is still data.');
    b.writeln();
    b.writeln('| Module | Playable lessons | Pack records used by questions | '
        'Writing practice records | Still draft (not imported) | '
        'Placeholder, outline or blueprint |');
    b.writeln('|---|---:|---:|---:|---:|---:|');
    for (final pack in packs) {
      final lessons = p.forModule(pack.module).length;
      final q = p.questionRecords(pack.module);
      final w = p.writingRecords(pack.module);
      final ready = teachable(pack).toList();
      final draftLeft = ready.where((l) => !q.contains(l.id)).length;
      final notReady = pack.lessons.length - ready.length;
      b.writeln(
          '| ${pack.module.name} | $lessons | ${q.length} | ${w.length} | '
          '$draftLeft | $notReady |');
    }
    b.writeln();
    b.writeln('- *Playable lesson*: plays end to end offline in the app, every '
        'answer key checked against the pack.');
    b.writeln('- *Writing practice*: the handwriting engine checks the shape '
        'and gives feedback, but **no mastery is awarded** until a teacher '
        'verifies stroke order (see the asset manifest).');
    b.writeln('- Writing records are counted separately: in the pack they are '
        'still placeholders (no stroke geometry).');
    b.writeln();
    b.writeln('### What each playable lesson still lacks');
    b.writeln();
    b.writeln('| Lesson | Module | Picture missing for | Stroke template | '
        'Stroke order verified | Audio recorded | Native review |');
    b.writeln('|---|---|---|---|---|---|---|');
    for (final l in p.lessons) {
      b.writeln('| ${l.id} (${l.title}) | ${l.module.name} | '
          '${l.missingPictures.isEmpty ? '—' : l.missingPictures.join(', ')} | '
          '${l.hasStrokeTemplate ? 'yes' : 'no (font outline only)'} | '
          '${l.strokeOrderVerified ? 'yes' : 'no'} | '
          '${l.audioRecorded ? 'yes' : 'no'} | '
          '${l.nativeReviewed ? 'yes' : 'no'} |');
    }
    b.writeln();
  }

  // -- CSV ----------------------------------------------------------------

  String toCsv() {
    final b = StringBuffer('module,chapter,age_band,readiness,count\n');
    for (final p in packs) {
      final counts = <String, int>{};
      for (final l in p.lessons) {
        final key =
            '${p.module.name},${l.chapter},${l.stage},${readinessOf(l).name}';
        counts[key] = (counts[key] ?? 0) + 1;
      }
      for (final e in counts.entries) {
        b.writeln('${e.key},${e.value}');
      }
    }
    return b.toString();
  }
}
