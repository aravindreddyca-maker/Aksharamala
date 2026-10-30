import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models.dart';

class LocalSnapshot {
  const LocalSnapshot({required this.profiles, required this.progress});

  final List<ChildProfile> profiles;
  final Map<String, ProgressRecord> progress;
}

/// The save file format. Version 2 stores each child's level (1-5) and answer
/// statistics per level and world. Version 1 saves (an age and no level) load
/// into it without losing anything: the file is first copied to
/// `progress.json.v1.bak`, and nothing is removed from what was saved.
const int saveFormatVersion = 2;

class LocalStore {
  LocalStore({this.fileOverride});

  final File? fileOverride;

  Future<File> _file() async {
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
    return File('${dataDirectory.path}/progress.json');
  }

  Future<LocalSnapshot> load() async {
    final file = await _file();
    if (!await file.exists()) {
      return const LocalSnapshot(profiles: [], progress: {});
    }
    final snapshot = await _read(file);
    if (snapshot != null) {
      await _backUpOlderFormat(file);
      return snapshot;
    }
    // The file could not be read. Keep it for recovery rather than let the
    // next save write over it, and try the copy kept from the last good save.
    await _keepUnreadable(file);
    final backup = File('${file.path}.bak');
    if (await backup.exists()) {
      final fromBackup = await _read(backup);
      if (fromBackup != null) return fromBackup;
    }
    return const LocalSnapshot(profiles: [], progress: {});
  }

  Future<LocalSnapshot?> _read(File file) async {
    try {
      final value =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final profiles = (value['profiles'] as List? ?? const [])
          .map(
            (item) =>
                ChildProfile.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      final progress = <String, ProgressRecord>{};
      for (final entry in (value['progress'] as Map? ?? const {}).entries) {
        progress[entry.key as String] = ProgressRecord.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
      return LocalSnapshot(profiles: profiles, progress: progress);
    } on Object {
      return null;
    }
  }

  /// A save from before levels is copied once, untouched, before the first
  /// write in the new format.
  Future<void> _backUpOlderFormat(File file) async {
    try {
      final value = jsonDecode(await file.readAsString());
      final version = value is Map ? value['version'] : null;
      if (version is int && version >= saveFormatVersion) return;
      final copy = File('${file.path}.v1.bak');
      if (!await copy.exists()) await file.copy(copy.path);
    } on Object {
      // A missing backup must never stop the app from opening.
    }
  }

  Future<void> _keepUnreadable(File file) async {
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await file.copy('${file.path}.unreadable.$stamp');
    } on Object {
      // Nothing more can be done; the app still opens empty.
    }
  }

  Future<void> save(LocalSnapshot snapshot) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      jsonEncode({
        'version': saveFormatVersion,
        'profiles':
            snapshot.profiles.map((profile) => profile.toJson()).toList(),
        'progress': snapshot.progress.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      }),
    );
    if (await file.exists()) {
      // Keep the last good save beside the new one.
      try {
        await file.copy('${file.path}.bak');
      } on Object {
        // Not having a copy must not stop a save.
      }
      await file.delete();
    }
    await temp.rename(file.path);
  }
}
