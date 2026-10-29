// Validates content/pack_v2 and writes the coverage report.
//
//   dart run tool/content_report.dart
//
// Read-only on the pack. Writes content/reports/COVERAGE_REPORT.md and .csv.
import 'dart:io';

import 'package:aksharamala/src/content/content_loader.dart';
import 'package:aksharamala/src/content/content_validator.dart';
import 'package:aksharamala/src/content/coverage_report.dart';

void main(List<String> args) {
  const dir = 'content/pack_v2/content';
  final loaded = loadContentDirectory(dir);
  final report = ContentValidator().validate(loaded.packs);
  final merged = ValidationReport(
    [...loaded.parseIssues, ...report.issues],
    report.readiness,
  );
  final coverage = CoverageReport(loaded.packs, merged);

  Directory('content/reports').createSync(recursive: true);
  File('content/reports/COVERAGE_REPORT.md')
      .writeAsStringSync(coverage.toMarkdown());
  File('content/reports/COVERAGE_REPORT.csv')
      .writeAsStringSync(coverage.toCsv());

  stdout.writeln('wrote content/reports/COVERAGE_REPORT.md and .csv');
  stdout.writeln('structural errors: ${merged.errors.length}');
}
