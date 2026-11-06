/// Persistence for exams: a separate `exams.json` next to `progress.json`.
/// Same safety pattern as `LocalStore` (temp file then rename, rolling
/// `.bak`, an unreadable file is kept as `.unreadable.<ts>`), but a different
/// file, so a failed exam write can never damage learning progress and the
/// reverse. This class never reads or writes `progress.json`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'models.dart';

const int examStoreVersion = 1;

enum ExamLoadStatus {
  /// No file yet: a fresh start.
  missing,
  ok,

  /// The main file was unreadable (kept as `.unreadable.<ts>`); the last good
  /// copy (`.bak`) was used.
  recoveredFromBackup,

  /// The main file was unreadable and there was no usable backup; started
  /// empty. The damaged file is still kept.
  unreadableStartedEmpty,
}

class ExamData {
  const ExamData({
    this.attempts = const [],
    this.results = const [],
    this.certificates = const [],
    this.settings = const {},
  });

  final List<ExamAttempt> attempts;
  final List<ExamResult> results;
  final List<Certificate> certificates;
  final Map<String, ChildExamSettings> settings;

  Map<String, Object?> toJson() => {
        'version': examStoreVersion,
        'attempts': [for (final a in attempts) a.toJson()],
        'results': [for (final r in results) r.toJson()],
        'certificates': [for (final c in certificates) c.toJson()],
        'settings': settings.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory ExamData.fromJson(Map<String, dynamic> json) => ExamData(
        attempts: [
          for (final a in (json['attempts'] as List? ?? const []))
            ExamAttempt.fromJson(Map<String, dynamic>.from(a as Map)),
        ],
        results: [
          for (final r in (json['results'] as List? ?? const []))
            ExamResult.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
        certificates: [
          for (final c in (json['certificates'] as List? ?? const []))
            Certificate.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
        settings: {
          for (final e in (json['settings'] as Map? ?? const {}).entries)
            e.key as String: ChildExamSettings.fromJson(
                Map<String, dynamic>.from(e.value as Map)),
        },
      );
}

class ExamStore {
  ExamStore({this.fileOverride});

  final File? fileOverride;

  /// How the last [load] went, for a "your exam data was recovered" notice.
  ExamLoadStatus lastLoadStatus = ExamLoadStatus.missing;

  Future<File> file() async {
    if (fileOverride != null) return fileOverride!;
    Directory base;
    try {
      const channel = MethodChannel('app.aksharamala/storage');
      final path = await channel.invokeMethod<String>('dataPath');
      base = path == null ? Directory.systemTemp : Directory(path);
    } on Object {
      base = Directory.systemTemp;
    }
    final dataDirectory = Directory('${base.path}/.aksharamala');
    if (!await dataDirectory.exists()) {
      await dataDirectory.create(recursive: true);
    }
    return File('${dataDirectory.path}/exams.json');
  }

  Future<ExamData> load() async {
    final f = await file();
    if (!await f.exists()) {
      lastLoadStatus = ExamLoadStatus.missing;
      return const ExamData();
    }
    final data = await _read(f);
    if (data != null) {
      lastLoadStatus = ExamLoadStatus.ok;
      return data;
    }
    await _keepUnreadable(f);
    final backup = File('${f.path}.bak');
    if (await backup.exists()) {
      final fromBackup = await _read(backup);
      if (fromBackup != null) {
        lastLoadStatus = ExamLoadStatus.recoveredFromBackup;
        return fromBackup;
      }
    }
    lastLoadStatus = ExamLoadStatus.unreadableStartedEmpty;
    return const ExamData();
  }

  Future<ExamData?> _read(File f) async {
    try {
      final value = jsonDecode(await f.readAsString());
      if (value is! Map) return null;
      final json = Map<String, dynamic>.from(value);
      final version = json['version'];
      // A file from a newer app is not guessed at.
      if (version is! int || version < 1 || version > examStoreVersion)
        return null;
      return ExamData.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<void> _keepUnreadable(File f) async {
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await f.copy('${f.path}.unreadable.$stamp');
    } on Object {
      // Nothing more can be done; the exam centre still opens.
    }
  }

  Future<void> save(ExamData data) async {
    final f = await file();
    await f.parent.create(recursive: true);
    final temp = File('${f.path}.tmp');
    await temp.writeAsString(jsonEncode(data.toJson()), flush: true);
    if (await f.exists()) {
      // Keep the last good file beside the new one, but only if it reads.
      try {
        if (await _read(f) != null) await f.copy('${f.path}.bak');
      } on Object {
        // Not having a copy must not stop a save.
      }
      await f.delete();
    }
    await temp.rename(f.path);
  }
}
