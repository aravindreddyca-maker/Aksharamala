/// The list of everything the first batch still needs: pictures, audio,
/// handwriting templates and native review. Generated from the lessons
/// themselves, so it cannot disagree with what the app plays.
library;

import '../content/content_models.dart';
import '../content/playable_summary.dart';
import '../handwriting/handwriting_registry.dart';
import '../handwriting/digit_templates.dart';
import 'batch_content.dart';
import 'batch_lesson.dart';

typedef AssetExists = bool Function(String path);

class PictureNeed {
  const PictureNeed({
    required this.word,
    required this.meaning,
    required this.record,
    required this.lessons,
    required this.suggestedFile,
    required this.status,
  });

  final String word;
  final String meaning;
  final String record;
  final List<String> lessons;
  final String suggestedFile;
  final String status;

  bool get missing => status != 'present';
}

class AudioNeed {
  const AudioNeed({
    required this.lesson,
    required this.step,
    required this.locale,
    required this.text,
    required this.suggestedFile,
  });

  final String lesson;
  final int step;
  final String locale;
  final String text;
  final String suggestedFile;
}

class TemplateNeed {
  const TemplateNeed({
    required this.glyph,
    required this.script,
    required this.lessons,
    required this.hasTemplate,
    required this.orderVerified,
    required this.checkedBy,
  });

  final String glyph;
  final String script;
  final List<String> lessons;
  final bool hasTemplate;
  final bool orderVerified;
  final String checkedBy;
}

String _slug(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

class AssetManifest {
  AssetManifest(this.lessons, {required AssetExists exists}) {
    _build(exists);
  }

  final List<BatchLesson> lessons;
  final List<PictureNeed> pictures = [];
  final List<AudioNeed> audio = [];
  final List<TemplateNeed> templates = [];
  final List<String> textForReview = [];

  void _build(AssetExists exists) {
    // Pictures: every Telugu picture word the quizzes can show.
    final usedBy = <String, List<String>>{};
    for (final l in lessons) {
      for (final s in l.steps.where((s) => s.kind == StepKind.pickWord)) {
        for (final w in s.options) {
          usedBy.putIfAbsent(w, () => []).add(l.id);
        }
      }
    }
    for (final e in usedBy.entries) {
      final info = teluguWords[e.key]!;
      final path = teluguWordPictures[e.key];
      pictures.add(PictureNeed(
        word: e.key,
        meaning: info.meaning,
        record: info.record,
        lessons: e.value,
        suggestedFile:
            path ?? 'assets/images/quiz/te_${_slug(info.meaning)}.webp',
        status: path != null && exists(path) ? 'present' : 'missing',
      ));
    }
    pictures.sort((a, b) => a.record.compareTo(b.record));

    // Audio: one line per distinct thing the Listen button says.
    final seen = <String>{};
    for (final l in lessons) {
      for (var i = 0; i < l.steps.length; i++) {
        final s = l.steps[i];
        final key = '${l.locale}|${s.speech}';
        if (!seen.add(key)) continue;
        audio.add(AudioNeed(
          lesson: l.id,
          step: i + 1,
          locale: l.locale,
          text: s.speech,
          suggestedFile:
              'assets/audio/${l.locale.split('-').first}/${l.id}_${i + 1}.mp3',
        ));
      }
    }

    // Handwriting: one row per glyph written.
    final byGlyph = <String, List<BatchLesson>>{};
    for (final l in lessons) {
      for (final s in l.steps.where((s) => s.kind == StepKind.write)) {
        final list = byGlyph.putIfAbsent(s.glyph!, () => []);
        if (!list.contains(l)) list.add(l);
      }
    }
    for (final e in byGlyph.entries) {
      final t = templateFor(e.key);
      templates.add(TemplateNeed(
        glyph: e.key,
        script: e.value.first.locale.startsWith('te') ? 'telugu' : 'numbers',
        lessons: [for (final l in e.value) l.id],
        hasTemplate: t != null,
        orderVerified: t?.strokeOrderVerified ?? false,
        checkedBy: t != null
            ? 'stroke template (order, direction, shape)'
            : 'font outline (shape only)',
      ));
    }

    // Child-facing text a native speaker must approve.
    final text = <String>{};
    for (final l in lessons.where((l) => l.locale.startsWith('te'))) {
      text.add(l.subtitle);
      for (final s in l.steps) {
        text.add(s.prompt);
      }
    }
    for (final t in [
      BatchText.telugu.rightMessage,
      BatchText.telugu.tryAgainMessage,
      BatchText.telugu.goodWriting,
      BatchText.telugu.strokeHint,
      BatchText.telugu.directionHint,
      BatchText.telugu.orderHint,
      BatchText.telugu.strokesHint,
    ]) {
      text.add(t);
    }
    textForReview.addAll(text);
  }

  // -- the summary the coverage report prints -----------------------------

  PlayableSummary summary() => PlayableSummary([
        for (final l in lessons)
          PlayableLesson(
            id: l.id,
            module: l.locale.startsWith('te')
                ? ContentModule.telugu
                : ContentModule.numbers,
            title: l.title,
            questionRecords: {
              for (final s in l.questions)
                if (s.sourceRecord != null) s.sourceRecord!,
            },
            writingRecords: {
              for (final s in l.steps.where((s) => s.kind == StepKind.write))
                s.sourceRecord!,
            },
            missingPictures: [
              for (final s in l.steps.where((s) => s.kind == StepKind.pickWord))
                if (!pictures.any((p) => p.word == s.answer && !p.missing))
                  s.answer,
            ],
            hasStrokeTemplate: l.steps
                .where((s) => s.kind == StepKind.write)
                .every((s) => templateFor(s.glyph!) != null),
            strokeOrderVerified: l.steps
                .where((s) => s.kind == StepKind.write)
                .every(
                    (s) => templateFor(s.glyph!)?.strokeOrderVerified ?? false),
          ),
      ]);

  // -- Markdown / CSV ------------------------------------------------------

  String toMarkdown() {
    final b = StringBuffer();
    final missingPics = pictures.where((p) => p.missing).toList();
    b.writeln('# Asset manifest: first batch');
    b.writeln();
    b.writeln('Generated from the lessons in `lib/src/batch/`; regenerate with '
        '`flutter test --dart-define=WRITE_REPORTS=true test/batch/reports_test.dart`. '
        'A test fails if this file is out of date.');
    b.writeln();
    b.writeln('| What | Needed | Present | Missing |');
    b.writeln('|---|---:|---:|---:|');
    b.writeln('| Pictures (Telugu words) | ${pictures.length} | '
        '${pictures.length - missingPics.length} | ${missingPics.length} |');
    b.writeln(
        '| Recorded audio lines | ${audio.length} | 0 | ${audio.length} |');
    final tmplMissing = templates.where((t) => !t.hasTemplate).length;
    b.writeln('| Stroke templates (glyphs) | ${templates.length} | '
        '${templates.length - tmplMissing} | $tmplMissing |');
    b.writeln('| Teacher-verified stroke orders | ${templates.length} | '
        '${templates.where((t) => t.orderVerified).length} | '
        '${templates.where((t) => !t.orderVerified).length} |');
    b.writeln('| Telugu sentences approved by a native speaker | '
        '${textForReview.length} | 0 | ${textForReview.length} |');
    b.writeln();
    b.writeln('Number Galaxy needs **no new pictures**: it uses the existing '
        'star art. Its English narration still has no recording.');
    b.writeln();

    b.writeln('## 1. Pictures');
    b.writeln();
    b.writeln(
        '| Word | Meaning | Pack record | Used by | Suggested file | Status |');
    b.writeln('|---|---|---|---|---|---|');
    for (final p in pictures) {
      b.writeln('| ${p.word} | ${p.meaning} | ${p.record} | '
          '${p.lessons.length} lesson${p.lessons.length == 1 ? '' : 's'} | '
          '`${p.suggestedFile}` | ${p.status} |');
    }
    b.writeln();
    b.writeln('Until a picture exists, the quiz shows the word on its own. '
        'Nothing breaks and nothing is hidden.');
    b.writeln();

    b.writeln('## 2. Audio');
    b.writeln();
    b.writeln('Today the Listen button uses the phone\'s own voice. No '
        'recordings exist, and nobody has checked that the phone says these '
        'lines correctly.');
    b.writeln();
    b.writeln('| Lesson | Step | Locale | Line | Suggested file |');
    b.writeln('|---|---:|---|---|---|');
    for (final a in audio) {
      b.writeln('| ${a.lesson} | ${a.step} | ${a.locale} | ${a.text} | '
          '`${a.suggestedFile}` |');
    }
    b.writeln();

    b.writeln('## 3. Handwriting templates');
    b.writeln();
    b.writeln(
        '| Glyph | Script | Lessons | Checked by | Stroke order verified |');
    b.writeln('|---|---|---|---|---|');
    for (final t in templates) {
      b.writeln('| ${t.glyph} | ${t.script} | ${t.lessons.length} | '
          '${t.checkedBy} | ${t.orderVerified ? 'yes' : 'no'} |');
    }
    b.writeln();
    b.writeln(
        '- Numbers 0-10 have hand-drawn stroke templates (`digit_templates.dart`): '
        'order, direction and shape are checked. A teacher must confirm them '
        'before the app can award handwriting mastery.');
    b.writeln('- The ten Telugu letters have **no stroke template**. They are '
        'checked by shape against the letter\'s font outline, which proves the '
        'child drew that letter but cannot judge stroke order. Needed: a Telugu '
        'teacher\'s stroke order for each letter.');
    b.writeln();

    b.writeln('## 4. Telugu sentences for native review');
    b.writeln();
    b.writeln('Written for this app; not taken from a verified source.');
    b.writeln();
    for (final t in textForReview) {
      b.writeln('- $t');
    }
    return b.toString();
  }

  String toCsv() {
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    final b = StringBuffer('kind,id,language,detail,suggested_file,status\n');
    for (final p in pictures) {
      b.writeln([
        'picture',
        p.record,
        'telugu',
        '${p.word} (${p.meaning})',
        p.suggestedFile,
        p.status
      ].map(q).join(','));
    }
    for (final a in audio) {
      b.writeln([
        'audio',
        '${a.lesson}#${a.step}',
        a.locale,
        a.text,
        a.suggestedFile,
        'missing'
      ].map(q).join(','));
    }
    for (final t in templates) {
      b.writeln([
        'handwriting_template',
        t.glyph,
        t.script,
        t.checkedBy,
        '',
        t.hasTemplate
            ? (t.orderVerified ? 'verified' : 'unverified')
            : 'missing'
      ].map(q).join(','));
    }
    for (final t in textForReview) {
      b.writeln(
          ['native_review', '', 'telugu', t, '', 'pending'].map(q).join(','));
    }
    return b.toString();
  }
}

/// Handy for tests: how many glyphs have a verified template.
int get verifiedTemplateCount =>
    digitTemplates.values.where((t) => t.strokeOrderVerified).length;
