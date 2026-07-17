import 'package:wowcare/data/features/tasks/datasources/task_remote_datasource.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';

/// Remote-only implementation backed by the events-todo Tasks API. No Isar
/// persistence or mock seeding — mirrors the Events/Holidays modules.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<List<Task>> getTasks({String? query}) async {
    final models = await _remoteDataSource.getAssignments(q: query);
    // Defensive de-duplication by assignment code: a single assignment must
    // never surface as two cards even if the API echoes a row twice.
    final seen = <String>{};
    final tasks = <Task>[];
    for (final model in models) {
      if (!seen.add(model.code)) continue;
      tasks.add(model.toEntity());
    }
    return tasks
      ..sort((a, b) {
        final byDue = a.dueDate.compareTo(b.dueDate);
        if (byDue != 0) return byDue;
        return a.dueTime.compareTo(b.dueTime);
      });
  }

  @override
  Future<void> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
  }) async {
    await _remoteDataSource.createTask(draft: draft, assignees: assignees);
  }

  @override
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
  }) async {
    await _remoteDataSource.updateTask(
      code: seriesCode.trim(),
      title: title,
      description: description,
      holidayPolicy: holidayPolicy,
      schedule: schedule,
      assignees: assignees,
    );
  }

  @override
  Future<void> deleteTask(String seriesCode) {
    return _remoteDataSource.deleteTask(seriesCode.trim());
  }

  @override
  Future<Task> updateAssignmentStatus({
    required String assignmentCode,
    required TaskStatus status,
  }) async {
    final model = await _remoteDataSource.updateAssignmentStatus(
      code: assignmentCode.trim(),
      status: status,
    );
    return model.toEntity();
  }
}
