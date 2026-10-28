import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models.dart';

class LocalSnapshot {
  const LocalSnapshot({required this.profiles, required this.progress});

  final List<ChildProfile> profiles;
  final Map<String, ProgressRecord> progress;
}

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
    if (!await dataDirectory.exists()) await dataDirectory.create(recursive: true);
    return File('${dataDirectory.path}/progress.json');
  }

  Future<LocalSnapshot> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const LocalSnapshot(profiles: [], progress: {});
      }
      final value = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final profiles = (value['profiles'] as List? ?? const [])
          .map((item) => ChildProfile.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      final progress = <String, ProgressRecord>{};
      for (final entry in (value['progress'] as Map? ?? const {}).entries) {
        progress[entry.key as String] = ProgressRecord.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
      return LocalSnapshot(profiles: profiles, progress: progress);
    } on Object {
      return const LocalSnapshot(profiles: [], progress: {});
    }
  }

  Future<void> save(LocalSnapshot snapshot) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode({
      'version': 1,
      'profiles': snapshot.profiles.map((profile) => profile.toJson()).toList(),
      'progress': snapshot.progress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    }));
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }
}

