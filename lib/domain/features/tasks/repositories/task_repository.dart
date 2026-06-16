import '../entities/task.dart';

abstract class TaskRepository {
  /// Returns every locally stored task, seeding the bundled mock dataset on
  /// the first call when the store is empty.
  Future<List<Task>> getTasks();

  Future<Task?> getTaskByCode(String code);

  /// Persists a new task. The caller assigns the code and audit fields.
  Future<Task> createTask(Task task);

  Future<Task> updateTask(Task task);

  Future<void> deleteTask(String code);
}
