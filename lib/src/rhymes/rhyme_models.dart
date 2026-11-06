import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The four rhyme languages, in the order the filter chips show them.
const rhymeLanguages = <String>['english', 'telugu', 'hindi', 'tamil'];

const rhymeLanguageLabels = <String, String>{
  'english': 'English',
  'telugu': 'Telugu',
  'hindi': 'Hindi',
  'tamil': 'Tamil',
};

const rhymeAssetPath = 'content/rhymes/rhymes.json';

class RhymeLine {
  const RhymeLine({required this.text, required this.speech, this.meaningEn});

  /// What is shown.
  final String text;

  /// What the phone's voice reads (differs from [text] only for pauses).
  final String speech;

  /// For parents; never shown to the child as an answer.
  final String? meaningEn;
}

/// One missing-word question: [answer] is blanked out of line [lineIndex].
class RhymeBlankItem {
  const RhymeBlankItem({
    required this.lineIndex,
    required this.answer,
    required this.options,
  });

  final int lineIndex;
  final String answer;

  /// Authoring order (the answer is often first); screens shuffle it.
  final List<String> options;
}

class Rhyme {
  const Rhyme({
    required this.id,
    required this.language,
    required this.locale,
    required this.level,
    required this.title,
    required this.lines,
    this.picture = '',
    this.pictureConcept = '',
    this.items = const [],
    this.source = '',
    this.meaningHiddenDuringActivity = false,
    this.hideTitleDuringActivity = false,
  });

  final String id;
  final String language;
  final String locale;
  final int level;
  final String title;
  final List<RhymeLine> lines;
  final String picture;
  final String pictureConcept;
  final List<RhymeBlankItem> items;
  final String source;

  /// While the blank is open the screen must not show meaning_en or the
  /// picture concept (either could give the word away).
  final bool meaningHiddenDuringActivity;

  /// The title contains the answer, so it is hidden while the game is open.
  final bool hideTitleDuringActivity;

  bool get hasActivity => items.isNotEmpty;

  /// Line [item] with its answer replaced by `____`.
  String blankedLine(RhymeBlankItem item) {
    final text = lines[item.lineIndex].text;
    final at = _indexOfWord(text, item.answer);
    if (at < 0) return text;
    return text.replaceRange(at, at + item.answer.length, '____');
  }
}

int _indexOfWord(String text, String word) {
  final exact = text.indexOf(word);
  if (exact >= 0) return exact;
  return text.toLowerCase().indexOf(word.toLowerCase());
}

/// A rhyme that was left out, and why. Messages carry ids only (never rhyme
/// text), so they are safe to print on any console.
class RhymeIssue {
  const RhymeIssue(this.rhymeId, this.message);
  final String rhymeId;
  final String message;

  @override
  String toString() => '$rhymeId: $message';
}

class RhymeLibrary {
  const RhymeLibrary({this.rhymes = const [], this.issues = const []});

  static const empty = RhymeLibrary();

  final List<Rhyme> rhymes;
  final List<RhymeIssue> issues;

  List<Rhyme> forLanguage(String language) => [
        for (final r in rhymes)
          if (r.language == language) r
      ];

  Rhyme? byId(String id) {
    for (final r in rhymes) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Parses the rhymes file. A rhyme that does not validate is skipped and
  /// reported in [issues]; nothing here ever throws.
  factory RhymeLibrary.parse(String source) {
    final Object? root;
    try {
      root = jsonDecode(source);
    } on Object {
      return const RhymeLibrary(
        issues: [RhymeIssue('(file)', 'rhymes file is not valid JSON')],
      );
    }
    final list = root is Map ? root['rhymes'] : null;
    if (list is! List) {
      return const RhymeLibrary(
        issues: [RhymeIssue('(file)', 'no "rhymes" list in the file')],
      );
    }
    final rhymes = <Rhyme>[];
    final issues = <RhymeIssue>[];
    final seen = <String>{};
    for (var i = 0; i < list.length; i++) {
      final raw = list[i];
      final id = raw is Map &&
              raw['id'] is String &&
              (raw['id'] as String).trim().isNotEmpty
          ? (raw['id'] as String).trim()
          : '(entry $i)';
      try {
        if (raw is! Map) throw const FormatException('not an object');
        if (!seen.add(id)) throw const FormatException('duplicate id');
        rhymes.add(_parseRhyme(id, raw));
      } on FormatException catch (e) {
        issues.add(RhymeIssue(id, e.message));
      } on Object {
        issues.add(RhymeIssue(id, 'unreadable entry'));
      }
    }
    return RhymeLibrary(rhymes: rhymes, issues: issues);
  }
}

String _text(Object? v) => v is String ? v.trim() : '';

Rhyme _parseRhyme(String id, Map raw) {
  if (id.startsWith('(entry')) throw const FormatException('missing id');
  final language = _text(raw['language']).toLowerCase();
  if (!rhymeLanguages.contains(language)) {
    throw const FormatException('unknown language');
  }
  final locale = _text(raw['locale']);
  if (locale.isEmpty) throw const FormatException('missing locale');
  final title = _text(raw['title']);
  if (title.isEmpty) throw const FormatException('missing title');
  final rawLines = raw['lines'];
  if (rawLines is! List || rawLines.length < 2 || rawLines.length > 6) {
    throw const FormatException('a rhyme needs 2 to 6 lines');
  }
  final lines = <RhymeLine>[];
  for (final l in rawLines) {
    final text = l is Map ? _text(l['text']) : '';
    if (text.isEmpty) throw const FormatException('empty line');
    final speech = _text((l as Map)['speech']);
    final meaning = _text(l['meaning_en']);
    lines.add(
      RhymeLine(
        text: text,
        speech: speech.isEmpty ? text : speech,
        meaningEn: meaning.isEmpty ? null : meaning,
      ),
    );
  }
  final items = <RhymeBlankItem>[];
  final activity = raw['activity'];
  if (activity != null) {
    if (activity is! Map || activity['kind'] != 'missing_word') {
      throw const FormatException('unknown activity kind');
    }
    final rawItems = activity['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      throw const FormatException('activity has no items');
    }
    for (final it in rawItems) {
      if (it is! Map) throw const FormatException('bad activity item');
      final index = it['line_index'];
      if (index is! int || index < 0 || index >= lines.length) {
        throw const FormatException('activity line_index out of range');
      }
      final answer = _text(it['answer']);
      final blank = _text(it['blank_word']);
      final rawOptions = it['options'];
      if (answer.isEmpty || rawOptions is! List) {
        throw const FormatException('activity needs an answer and options');
      }
      final options = [for (final o in rawOptions) _text(o)];
      if (options.length < 2 || options.any((o) => o.isEmpty)) {
        throw const FormatException('activity needs 2 or more options');
      }
      if (options.toSet().length != options.length) {
        throw const FormatException('activity options repeat');
      }
      if (!options.contains(answer)) {
        throw const FormatException('activity answer is not in the options');
      }
      if (blank.isNotEmpty && blank != answer) {
        throw const FormatException('blank_word differs from the answer');
      }
      if (_indexOfWord(lines[index].text, answer) < 0) {
        throw const FormatException('answer word is not in the indicated line');
      }
      items.add(
          RhymeBlankItem(lineIndex: index, answer: answer, options: options));
    }
  }
  final level = raw['level'];
  return Rhyme(
    id: id,
    language: language,
    locale: locale,
    level: level is int ? level : 1,
    title: title,
    lines: lines,
    picture: _text(raw['picture']),
    pictureConcept: _text(raw['picture_concept']),
    items: items,
    source: _text(raw['source']),
    meaningHiddenDuringActivity: raw['meaning_hidden_during_activity'] == true,
    hideTitleDuringActivity: raw['hide_title_during_activity'] == true,
  );
}

/// Supplies the rhymes file text (tests pass their own).
typedef RhymeLoader = Future<String> Function();

Future<String> assetRhymeLoader() => rootBundle.loadString(rhymeAssetPath);

/// Loads and validates the rhymes. A missing or broken file gives an empty
/// library plus an issue; skipped rhymes are reported with [debugPrint]
/// (ids only).
Future<RhymeLibrary> loadRhymeLibrary(
    [RhymeLoader loader = assetRhymeLoader]) async {
  RhymeLibrary library;
  try {
    library = RhymeLibrary.parse(await loader());
  } on Object {
    library = const RhymeLibrary(
      issues: [RhymeIssue('(file)', 'rhymes file could not be read')],
    );
  }
  for (final issue in library.issues) {
    debugPrint('Rhyme skipped: $issue');
  }
  return library;
}
