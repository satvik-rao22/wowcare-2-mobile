import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/data/features/tasks/models/task_collection.dart';

/// Isar-backed persistence for tasks. All reads/writes go through the shared
/// [CacheService] so they live in the same database (and follow the same
/// wipe-on-logout rules) as the rest of the app's local data.
abstract class TaskLocalDataSource {
  Future<List<TaskCollection>> getAll();

  Future<void> upsert(TaskCollection task);

  Future<void> upsertAll(List<TaskCollection> tasks);

  Future<void> deleteByCode(String code);

  Future<void> clear();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  TaskLocalDataSourceImpl(this._cacheService);

  final CacheService _cacheService;

  @override
  Future<List<TaskCollection>> getAll() {
    return _cacheService.getAll<TaskCollection>();
  }

  @override
  Future<void> upsert(TaskCollection task) {
    return _cacheService.put<TaskCollection>(task);
  }

  @override
  Future<void> upsertAll(List<TaskCollection> tasks) {
    return _cacheService.putAll<TaskCollection>(tasks);
  }

  @override
  Future<void> deleteByCode(String code) {
    return _cacheService.delete<TaskCollection>(fastHash(code));
  }

  @override
  Future<void> clear() {
    return _cacheService.clear<TaskCollection>();
  }
}
