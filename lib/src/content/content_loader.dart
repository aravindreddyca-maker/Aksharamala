/// Reads content packs from disk. Uses `dart:io`, so it is for tools and tests
/// (and could be used by the app on Android), never for widgets.
library;

import 'dart:convert';
import 'dart:io';

import 'content_issue.dart';
import 'content_models.dart';
import 'content_validator.dart';

class LoadedContent {
  LoadedContent(this.packs, this.parseIssues);

  final List<ContentPack> packs;

  /// Problems found while reading (before validation).
  final List<ContentIssue> parseIssues;
}

/// Reads `<dir>/<module>.json` for every module that has a file.
LoadedContent loadContentDirectory(String directory) {
  final packs = <ContentPack>[];
  final issues = <ContentIssue>[];
  for (final module in ContentModule.values) {
    final file = File('$directory/${module.name}.json');
    if (!file.existsSync()) continue;
    Object? json;
    try {
      json = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      issues.add(ContentIssue(
        code: 'E002',
        severity: IssueSeverity.error,
        module: module.name,
        message: 'not valid JSON: ${e.message}',
      ));
      continue;
    }
    final parsed = parseContentPack(json, expected: module);
    issues.addAll(parsed.issues);
    if (parsed.pack != null) packs.add(parsed.pack!);
  }
  return LoadedContent(packs, issues);
}

/// Parse, then validate. Parse problems are merged into the report.
ValidationReport validateContentDirectory(
  String directory, {
  AssetExists? assetExists,
}) {
  final loaded = loadContentDirectory(directory);
  final report =
      ContentValidator(assetExists: assetExists).validate(loaded.packs);
  return ValidationReport(
    [...loaded.parseIssues, ...report.issues],
    report.readiness,
  );
}
