import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/tasks/datasources/task_local_datasource.dart';
import 'package:wowcare/data/features/tasks/datasources/task_seed_datasource.dart';
import 'package:wowcare/data/features/tasks/models/task_collection.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(
    this._localDataSource,
    this._seedDataSource,
    this._storageService,
  );

  final TaskLocalDataSource _localDataSource;
  final TaskSeedDataSource _seedDataSource;
  final StorageService _storageService;

  /// One-shot flag so user deletions aren't resurrected by reseeding.
  static const String _seededFlagKey = 'tasks_mock_seeded_v1';

  @override
  Future<List<Task>> getTasks() async {
    await _seedIfNeeded();
    final rows = await _localDataSource.getAll();
    final tasks = rows.map((r) => r.toEntity()).toList()
      ..sort((a, b) {
        final byDue = a.dueDate.compareTo(b.dueDate);
        if (byDue != 0) return byDue;
        return a.dueTime.compareTo(b.dueTime);
      });
    return tasks;
  }

  @override
  Future<Task?> getTaskByCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final rows = await _localDataSource.getAll();
    for (final row in rows) {
      if (row.code == trimmed) return row.toEntity();
    }
    return null;
  }

  @override
  Future<Task> createTask(Task task) async {
    await _localDataSource.upsert(TaskCollection.fromEntity(task));
    return task;
  }

  @override
  Future<Task> updateTask(Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _localDataSource.upsert(TaskCollection.fromEntity(updated));
    return updated;
  }

  @override
  Future<void> deleteTask(String code) {
    return _localDataSource.deleteByCode(code.trim());
  }

  Future<void> _seedIfNeeded() async {
    final alreadySeeded =
        await _storageService.getBool(_seededFlagKey) ?? false;
    if (alreadySeeded) return;
    final existing = await _localDataSource.getAll();
    if (existing.isEmpty) {
      final seeds = await _seedDataSource.fetchTasks();
      if (seeds.isNotEmpty) {
        await _localDataSource.upsertAll(
          seeds.map((m) => TaskCollection.fromEntity(m.toEntity())).toList(),
        );
      }
    }
    await _storageService.saveBool(_seededFlagKey, true);
  }
}
