import 'dart:io';

import 'package:aksharamala/src/content/content_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// The proposal names real records; it must never drift from the pack.
void main() {
  test('every record id in FIRST_LESSONS_PROPOSAL.md exists in the pack', () {
    final loaded = loadContentDirectory('content/pack_v2/content');
    final ids = {
      for (final p in loaded.packs) ...p.lessons.map((l) => l.id),
    };
    final text =
        File('content/reports/FIRST_LESSONS_PROPOSAL.md').readAsStringSync();
    final named = RegExp(r'`((?:telugu|numbers)-[a-z0-9-]+)`')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
    expect(named.length, greaterThanOrEqualTo(30));
    expect(named.where((n) => !ids.contains(n)), isEmpty);
  });
}
