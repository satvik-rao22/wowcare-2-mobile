import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/tasks/datasources/task_remote_datasource.dart';
import 'package:wowcare/data/features/tasks/models/task_models.dart';
import 'package:wowcare/data/features/tasks/repositories/task_repository_impl.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';

class _FakeTaskRemoteDataSource implements TaskRemoteDataSource {
  List<TaskAssignmentModel> nextAssignments = const [];
  TaskAssignmentModel? nextStatusCard;

  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;
  String? lastDeletedCode;
  Map<String, dynamic>? lastStatusArgs;

  String? lastQuery;

  @override
  Future<List<TaskAssignmentModel>> getAssignments({
    int page = 0,
    int size = 500,
    String? q,
  }) async {
    lastQuery = q;
    return nextAssignments;
  }

  @override
  Future<TaskSeriesModel> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    List<String> assetCodes = const [],
  }) async {
    lastCreateArgs = {'draft': draft, 'assignees': assignees, 'assetCodes': assetCodes};
    return const TaskSeriesModel(code: 'TSK_NEW', title: 'x', assigneeCount: 1);
  }

  @override
  Future<TaskSeriesModel> updateTask({
    required String code,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
  }) async {
    lastUpdateArgs = {
      'code': code,
      'title': title,
      'description': description,
      'holidayPolicy': holidayPolicy,
      'schedule': schedule,
      'assignees': assignees,
    };
    return const TaskSeriesModel(code: 'TSK_1', title: 'x');
  }

  @override
  Future<void> deleteTask(String code) async {
    lastDeletedCode = code;
  }

  @override
  Future<TaskAssignmentModel> updateAssignmentStatus({
    required String code,
    required TaskStatus status,
  }) async {
    lastStatusArgs = {'code': code, 'status': status};
    return nextStatusCard ??
        TaskAssignmentModel(
          code: code,
          taskCode: 'TSK_1',
          title: 'x',
          occurrenceDate: DateTime(2026, 7, 15),
          dueAt: DateTime(2026, 7, 17, 17),
          status: status.value,
        );
  }
}

TaskAssignmentModel _assignment(String code, DateTime due) => TaskAssignmentModel(
      code: code,
      taskCode: 'TSK_$code',
      title: code,
      occurrenceDate: DateTime(2026, 7, 15),
      dueAt: due,
    );

void main() {
  late _FakeTaskRemoteDataSource remote;
  late TaskRepositoryImpl repo;

  setUp(() {
    remote = _FakeTaskRemoteDataSource();
    repo = TaskRepositoryImpl(remote);
  });

  test('getTasks maps assignments to entities and sorts by due date/time', () async {
    remote.nextAssignments = [
      _assignment('C', DateTime(2026, 7, 20, 10)),
      _assignment('A', DateTime(2026, 7, 18, 9)),
      _assignment('B', DateTime(2026, 7, 18, 8)),
    ];

    final result = await repo.getTasks();

    // 18@08, 18@09, 20@10
    expect(result.map((t) => t.code).toList(), ['B', 'A', 'C']);
    expect(result.first, isA<Task>());
    expect(result.first.taskCode, 'TSK_B');
  });

  test('getTasks forwards the search query to the datasource', () async {
    remote.nextAssignments = const [];
    await repo.getTasks(query: 'report');
    expect(remote.lastQuery, 'report');
  });

  test('getTasks de-duplicates assignments that share a code', () async {
    remote.nextAssignments = [
      _assignment('A', DateTime(2026, 7, 18, 9)),
      _assignment('A', DateTime(2026, 7, 18, 9)), // duplicate row from the API
      _assignment('B', DateTime(2026, 7, 19, 9)),
    ];

    final result = await repo.getTasks();

    expect(result.map((t) => t.code).toList(), ['A', 'B']);
  });

  test('createTask forwards the draft and roster', () async {
    final draft = Task(
      code: '',
      title: 'New',
      startDate: DateTime(2026, 7, 15),
      dueDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await repo.createTask(
      draft: draft,
      assignees: const [TaskAssignee(staffCode: 'STF_1')],
    );
    expect(remote.lastCreateArgs!['draft'], draft);
    expect((remote.lastCreateArgs!['assignees'] as List), hasLength(1));
  });

  test('updateTask trims the series code and forwards fields', () async {
    final schedule = Task(
      code: '',
      title: 'x',
      startDate: DateTime(2026, 7, 15),
      dueDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await repo.updateTask(
      seriesCode: '  TSK_1  ',
      title: 'Renamed',
      schedule: schedule,
    );
    expect(remote.lastUpdateArgs!['code'], 'TSK_1');
    expect(remote.lastUpdateArgs!['title'], 'Renamed');
    expect(remote.lastUpdateArgs!['schedule'], schedule);
  });

  test('deleteTask trims the code before delegating', () async {
    await repo.deleteTask('  TSK_1  ');
    expect(remote.lastDeletedCode, 'TSK_1');
  });

  test('updateAssignmentStatus forwards and maps the returned card', () async {
    final task = await repo.updateAssignmentStatus(
      assignmentCode: '  TSA_1  ',
      status: TaskStatus.completed,
    );
    expect(remote.lastStatusArgs!['code'], 'TSA_1');
    expect(remote.lastStatusArgs!['status'], TaskStatus.completed);
    expect(task, isA<Task>());
    expect(task.status, TaskStatus.completed);
  });
}
