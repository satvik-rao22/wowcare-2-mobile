import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';
import 'package:wowcare/domain/features/tasks/usecases/cancel_task_occurrence_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/create_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_assignment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/detach_task_attachment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_attachments_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_occurrences_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_tasks_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/remove_task_assignee_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_status_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_occurrence_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/upload_task_attachments_usecase.dart';
import 'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_scope.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_edit_scope_sheet.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_manager.dart';

/// Minimal fakes: only the series fetch (§2a) is exercised here.
class _FakeStorage implements StorageService {
  final Map<String, Object> _data = {
    StorageKeys.userCode: 'USR_ME',
    StorageKeys.displayName: 'Me',
    StorageKeys.staffCode: 'STF_ME',
    StorageKeys.activeSchoolRole: 'ADMIN',
  };

  @override
  Future<String?> getString(String key) async => _data[key] as String?;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeTaskRepository implements TaskRepository {
  TaskSeries? series;
  int getTaskCalls = 0;

  @override
  Future<TaskSeries> getTask(String seriesCode) async {
    getTaskCalls++;
    final resolved = series;
    if (resolved == null) throw Exception('not found');
    return resolved;
  }

  @override
  Future<List<Task>> getTasks({String? query}) async => const [];

  @override
  Future<TaskBoard> getBoard(TaskQuery query) async => const TaskBoard.empty();

  @override
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? query,
    int page = 0,
    int size = 20,
  }) async =>
      const TaskSeriesPage(
        items: [],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeStaffRepository implements StaffRepository {
  @override
  Future<List<StaffMember>> getAllStaff({
    required String organizationCode,
    required String schoolCode,
    List<String>? statuses,
    int size = 200,
  }) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Only needs to satisfy the cubit's constructor — this suite never uploads.
class _FakeUploadManager implements AttachmentUploadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TasksCubit _buildCubit(_FakeTaskRepository repo) => TasksCubit(
      GetTasksUseCase(repo),
      CreateTaskUseCase(repo),
      DeleteTaskUseCase(repo),
      RemoveTaskAssigneeUseCase(repo),
      UpdateTaskAssignmentStatusUseCase(repo),
      UploadTaskAttachmentsUseCase(repo, _FakeUploadManager()),
      GetTaskAttachmentsUseCase(repo),
      DetachTaskAttachmentUseCase(repo),
      AssetService(ApiClient(baseUrl: 'http://localhost')),
      GetAllStaffUseCase(_FakeStaffRepository()),
      _FakeStorage(),
      UpdateTaskAssignmentUseCase(repo),
      DeleteTaskAssignmentUseCase(repo),
      GetTaskUseCase(repo),
      GetTaskOccurrencesUseCase(repo),
      UpdateTaskOccurrenceUseCase(repo),
      CancelTaskOccurrenceUseCase(repo),
      UpdateTaskUseCase(repo),
    );

Task _card({DateTime? occurrenceDate, String taskCode = 'TSK_1'}) => Task(
      code: 'TSA_1',
      taskCode: taskCode,
      title: 'Mobile task',
      startDate: occurrenceDate ?? DateTime.now().add(const Duration(days: 7)),
      dueDate: occurrenceDate ?? DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

const _recurringSeries = TaskSeries(
  code: 'TSK_1',
  title: 'Mobile task',
  recurring: true,
  recurrencePattern: TaskRecurrence.weekly,
  recurrenceByDay: ['MO'],
);

const _oneOffSeries = TaskSeries(code: 'TSK_1', title: 'Mobile task');

void main() {
  late _FakeTaskRepository repo;
  late TasksCubit cubit;

  setUp(() {
    repo = _FakeTaskRepository();
    cubit = _buildCubit(repo);
  });

  tearDown(() => cubit.close());

  /// Pumps an "Edit" button that runs [askTaskEditScope], so the tests exercise
  /// the same entry point the list and detail screens use.
  Future<TaskEditScopeChoice?> tapEdit(
    WidgetTester tester, {
    required Task task,
    TaskSeries? series,
    Future<void> Function(WidgetTester tester)? interact,
  }) async {
    TaskEditScopeChoice? choice;
    await tester.pumpWidget(
      BlocProvider<TasksCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  choice = await askTaskEditScope(
                    context: context,
                    cubit: cubit,
                    task: task,
                    series: series,
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    if (interact != null) {
      await interact(tester);
      await tester.pumpAndSettle();
    }
    return choice;
  }

  testWidgets('tapping Edit on a recurring task shows the scope sheet',
      (tester) async {
    repo.series = _recurringSeries;

    final choice = await tapEdit(
      tester,
      task: _card(),
      interact: (tester) async {
        expect(find.text('Modify "Mobile task"'), findsOneWidget);
        for (final scope in TaskEditScope.values) {
          expect(find.text(scope.label), findsOneWidget);
        }
        await tester.tap(find.text('Proceed'));
      },
    );

    expect(choice!.cancelled, isFalse);
    expect(choice.scope, TaskEditScope.thisOccurrence);
  });

  testWidgets('the chosen scope is handed back to the caller', (tester) async {
    repo.series = _recurringSeries;

    final choice = await tapEdit(
      tester,
      task: _card(),
      interact: (tester) async {
        await tester.tap(
          find.byKey(const ValueKey('task-edit-scope-entireSeries')),
        );
        await tester.pump();
        await tester.tap(find.text('Proceed'));
      },
    );

    expect(choice!.scope, TaskEditScope.entireSeries);
  });

  testWidgets('dismissing the sheet cancels — the form must not open',
      (tester) async {
    repo.series = _recurringSeries;

    final choice = await tapEdit(
      tester,
      task: _card(),
      interact: (tester) async => tester.tap(find.text('Cancel')),
    );

    expect(choice!.cancelled, isTrue);
    expect(choice.scope, isNull);
  });

  testWidgets('a one-off task is never asked and edits in place',
      (tester) async {
    repo.series = _oneOffSeries;

    final choice = await tapEdit(tester, task: _card());

    expect(find.text('Modify "Mobile task"'), findsNothing);
    expect(choice!.cancelled, isFalse);
    expect(choice.scope, TaskEditScope.thisOccurrence);
  });

  testWidgets('an already-loaded series is reused instead of refetched',
      (tester) async {
    // The detail screen has the series in hand; asking must not cost a §2a call.
    final choice = await tapEdit(
      tester,
      task: _card(),
      series: _recurringSeries,
      interact: (tester) async => tester.tap(find.text('Proceed')),
    );

    expect(repo.getTaskCalls, 0);
    expect(choice!.scope, TaskEditScope.thisOccurrence);
  });

  testWidgets('a series that cannot be fetched still lets the edit through',
      (tester) async {
    // getTask throws (series left null): degrade to the narrow scope rather
    // than blocking the user from editing at all.
    final choice = await tapEdit(tester, task: _card());

    expect(find.text('Modify "Mobile task"'), findsNothing);
    expect(choice!.cancelled, isFalse);
    expect(choice.scope, TaskEditScope.thisOccurrence);
  });

  testWidgets('a card with no series code is never asked', (tester) async {
    repo.series = _recurringSeries;

    final choice = await tapEdit(tester, task: _card(taskCode: ''));

    expect(repo.getTaskCalls, 0);
    expect(find.text('Modify "Mobile task"'), findsNothing);
    expect(choice!.scope, TaskEditScope.thisOccurrence);
  });

  testWidgets('a past occurrence cannot anchor a split (§3d)', (tester) async {
    repo.series = _recurringSeries;

    await tapEdit(
      tester,
      task: _card(occurrenceDate: DateTime(2020, 1, 15)),
      interact: (tester) async {
        expect(find.text('This occurrence has already passed'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
      },
    );
  });
}
