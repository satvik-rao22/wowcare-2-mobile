import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/features/tasks/models/task_models.dart';

/// Development stand-in for the future tasks remote datasource: returns the
/// bundled `mock-data.json` payload in the same shape the API is expected to
/// use, so swapping in a Dio-backed implementation later only changes where
/// the JSON comes from.
abstract class TaskSeedDataSource {
  Future<List<TaskModel>> fetchTasks();
}

class TaskSeedDataSourceImpl implements TaskSeedDataSource {
  static const String _assetPath = 'assets/data/tasks/mock-data.json';

  @override
  Future<List<TaskModel>> fetchTasks() async {
    final rawTasks = await _loadSection('tasks');
    return rawTasks
        .whereType<Map>()
        .map((m) =>
            TaskModel.fromJson(m.map((k, v) => MapEntry(k.toString(), v))))
        .where((t) => t.code.isNotEmpty && t.title.isNotEmpty)
        .toList();
  }

  Future<List<dynamic>> _loadSection(String key) async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      final section = decoded is Map ? decoded[key] : null;
      return section is List ? section : const [];
    } catch (e) {
      AppLogger.e('[Tasks] Failed to load mock seed data ($key): $e');
      return const [];
    }
  }
}
