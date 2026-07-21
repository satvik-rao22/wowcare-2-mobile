import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/tasks/datasources/task_remote_datasource.dart';
import 'package:wowcare/data/features/tasks/models/task_models.dart';
import 'package:wowcare/data/features/tasks/repositories/task_repository_impl.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_occurrence.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/entities/task_upload_session.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

class _FakeTaskRemoteDataSource implements TaskRemoteDataSource {
  /// Pages of assignments keyed by page index; the repo walks these in order.
  Map<int, List<TaskAssignmentModel>> assignmentPages = const {};
  TaskAssignmentModel? nextStatusCard;
  TaskSeriesPage nextSeriesPage = const TaskSeriesPage(
    items: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
  );
  TaskBoard nextBoard = const TaskBoard.empty();
  TaskUploadSession nextSession = const TaskUploadSession(
    sessionCode: 'SES_1',
    documentApiBasePath: '/document-ms/api/v1',
  );

  TaskSeriesModel nextSeries =
      const TaskSeriesModel(code: 'TSK_1', title: 'x');
  TaskAssignmentModel? nextAssignmentCard;
  TaskOccurrence nextOccurrence = TaskOccurrence(
    code: 'TOC_1',
    taskCode: 'TSK_1',
    originalStartDate: DateTime(2026, 7, 15),
  );
  List<TaskOccurrence> nextOccurrences = const [];

  final List<TaskQuery> assignmentQueries = [];
  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;
  String? lastDeletedCode;
  Map<String, dynamic>? lastRemovedAssignee;
  Map<String, dynamic>? lastStatusArgs;
  Map<String, dynamic>? lastAssigneePriorityArgs;
  Map<String, dynamic>? lastAssignmentPatchArgs;
  String? lastFetchedTaskCode;
  String? lastFetchedAssignmentCode;
  String? lastDeletedAssignmentCode;
  String? lastOccurrencesCode;
  Map<String, dynamic>? lastOccurrenceUpdateArgs;
  Map<String, dynamic>? lastOccurrenceCancelArgs;
  int uploadSessionCalls = 0;

  @override
  Future<List<TaskAssignmentModel>> getAssignments(TaskQuery query) async {
    assignmentQueries.add(query);
    return assignmentPages[query.page] ?? const [];
  }

  @override
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? q,
    int page = 0,
    int size = 20,
  }) async =>
      nextSeriesPage;

  @override
  Future<TaskBoard> getBoard(TaskQuery query) async => nextBoard;

  @override
  Future<TaskSeriesModel> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) async {
    lastCreateArgs = {
      'draft': draft,
      'assignees': assignees,
      'holidayPolicy': holidayPolicy,
      'assetCodes': assetCodes,
    };
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
    List<String>? assetCodes,
    String? parentTaskCode,
    TaskUpdateScope scope = TaskUpdateScope.all,
    String? anchorOccurrenceCode,
  }) async {
    lastUpdateArgs = {
      'code': code,
      'title': title,
      'description': description,
      'holidayPolicy': holidayPolicy,
      'schedule': schedule,
      'assignees': assignees,
      'assetCodes': assetCodes,
      'parentTaskCode': parentTaskCode,
      'scope': scope,
      'anchorOccurrenceCode': anchorOccurrenceCode,
    };
    return const TaskSeriesModel(code: 'TSK_1', title: 'x');
  }

  @override
  Future<TaskSeriesModel> getTask(String code) async {
    lastFetchedTaskCode = code;
    return nextSeries;
  }

  @override
  Future<void> deleteTask(String code) async {
    lastDeletedCode = code;
  }

  @override
  Future<void> removeAssignee({
    required String code,
    required String staffCode,
  }) async {
    lastRemovedAssignee = {'code': code, 'staffCode': staffCode};
  }

  @override
  Future<void> updateAssigneePriority({
    required String code,
    required String staffCode,
    required TaskPriority priority,
  }) async {
    lastAssigneePriorityArgs = {
      'code': code,
      'staffCode': staffCode,
      'priority': priority,
    };
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

  @override
  Future<TaskAssignmentModel> getAssignment(String code) async {
    lastFetchedAssignmentCode = code;
    return nextAssignmentCard ??
        TaskAssignmentModel(
          code: code,
          taskCode: 'TSK_1',
          title: 'x',
          occurrenceDate: DateTime(2026, 7, 15),
          dueAt: DateTime(2026, 7, 17, 17),
        );
  }

  @override
  Future<TaskAssignmentModel> updateAssignment({
    required String code,
    String? title,
    String? description,
    DateTime? dueAt,
    TaskPriority? priority,
    TaskStatus? status,
    double? effort,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
  }) async {
    lastAssignmentPatchArgs = {
      'code': code,
      'title': title,
      'description': description,
      'dueAt': dueAt,
      'priority': priority,
      'status': status,
      'effort': effort,
      'schedule': schedule,
      'assignees': assignees,
      'assetCodes': assetCodes,
    };
    return nextAssignmentCard ??
        TaskAssignmentModel(
          code: code,
          taskCode: 'TSK_1',
          title: 'x',
          occurrenceDate: DateTime(2026, 7, 15),
          dueAt: dueAt ?? DateTime(2026, 7, 17, 17),
          priority: (priority ?? TaskPriority.medium).value,
        );
  }

  @override
  Future<void> deleteAssignment(String code) async {
    lastDeletedAssignmentCode = code;
  }

  @override
  Future<List<TaskOccurrence>> getOccurrences(String code) async {
    lastOccurrencesCode = code;
    return nextOccurrences;
  }

  @override
  Future<TaskOccurrence> getOccurrence({
    required String code,
    required String occurrenceCode,
  }) async {
    lastOccurrenceUpdateArgs = {
      'code': code,
      'occurrenceCode': occurrenceCode,
      'get': true,
    };
    return nextOccurrence;
  }

  @override
  Future<TaskOccurrence> updateOccurrence({
    required String code,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  }) async {
    lastOccurrenceUpdateArgs = {
      'code': code,
      'occurrenceCode': occurrenceCode,
      'scheduledStartDate': scheduledStartDate,
      'scheduledStartTime': scheduledStartTime,
      'scheduledEndTime': scheduledEndTime,
      'overrideTitle': overrideTitle,
      'overrideDescription': overrideDescription,
    };
    return nextOccurrence;
  }

  @override
  Future<TaskOccurrence> cancelOccurrence({
    required String code,
    required String occurrenceCode,
    String? reason,
  }) async {
    lastOccurrenceCancelArgs = {
      'code': code,
      'occurrenceCode': occurrenceCode,
      'reason': reason,
    };
    return nextOccurrence;
  }

  @override
  Future<TaskUploadSession> createUploadSession() async {
    uploadSessionCalls++;
    return nextSession;
  }
}

/// Fake [ImageUploadService] — implemented as an interface so no real
/// [ApiClient] is needed. Records the §9 steps and returns a canned presign.
class _FakeImageUpload implements ImageUploadService {
  final List<String> steps = [];
  Map<String, dynamic>? presignArgs;
  List<String>? waitedFor;

  @override
  Future<AssetPresignResult> createAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    String? checksumSha256,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  }) async {
    steps.add('presign');
    presignArgs = {
      'sessionCode': sessionCode,
      'documentApiBasePath': documentApiBasePath,
      'fileName': fileName,
      'contentType': contentType,
      'contentLengthBytes': contentLengthBytes,
      'mediaType': mediaType,
      'ownerType': ownerType,
      'ownerCode': ownerCode,
    };
    return const AssetPresignResult(
      assetCode: 'AST_READY',
      presignedPutUrl: 'https://storage/put',
      requiredHeaders: {'Content-Type': 'application/pdf'},
    );
  }

  @override
  Future<void> uploadFileToPresignedUrl({
    required File file,
    required String presignedPutUrl,
    Map<String, String> requiredHeaders = const {},
    String fallbackContentType = 'image/jpeg',
    void Function(int sent, int total)? onSendProgress,
    void Function(int sentBytes, int totalBytes, int percent)? onProgress,
  }) async {
    steps.add('put');
  }

  @override
  Future<void> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
  }) async {
    steps.add('complete');
  }

  @override
  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> expectedAssetCodes,
    Duration pollEvery = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    steps.add('poll');
    waitedFor = expectedAssetCodes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? 'SCH_1' : null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TaskAssignmentModel _assignment(String code, DateTime due) =>
    TaskAssignmentModel(
      code: code,
      taskCode: 'TSK_$code',
      title: code,
      occurrenceDate: DateTime(2026, 7, 15),
      dueAt: due,
    );

void main() {
  late _FakeTaskRemoteDataSource remote;
  late _FakeImageUpload imageUpload;
  late TaskRepositoryImpl repo;

  setUp(() {
    remote = _FakeTaskRemoteDataSource();
    imageUpload = _FakeImageUpload();
    repo = TaskRepositoryImpl(remote, imageUpload, _FakeStorage());
  });

  test('getTasks maps assignments to entities and sorts by due date/time',
      () async {
    remote.assignmentPages = {
      0: [
        _assignment('C', DateTime(2026, 7, 20, 10)),
        _assignment('A', DateTime(2026, 7, 18, 9)),
        _assignment('B', DateTime(2026, 7, 18, 8)),
      ],
    };

    final result = await repo.getTasks();

    // 18@08, 18@09, 20@10
    expect(result.map((t) => t.code).toList(), ['B', 'A', 'C']);
    expect(result.first.taskCode, 'TSK_B');
  });

  test('getTasks forwards the search query to the datasource', () async {
    await repo.getTasks(query: 'report');
    expect(remote.assignmentQueries.first.query, 'report');
  });

  test('getTasks de-duplicates assignments that share a code', () async {
    remote.assignmentPages = {
      0: [
        _assignment('A', DateTime(2026, 7, 18, 9)),
        _assignment('A', DateTime(2026, 7, 18, 9)), // duplicate row
        _assignment('B', DateTime(2026, 7, 19, 9)),
      ],
    };
    final result = await repo.getTasks();
    expect(result.map((t) => t.code).toList(), ['A', 'B']);
  });

  test('getTasks pages through the endpoint until a short page (Fix C)',
      () async {
    // A full first page (100 rows, the repo's page size) must trigger a second
    // fetch; the short second page ends the walk — no 500-row silent cap.
    remote.assignmentPages = {
      0: List.generate(
        100,
        (i) => _assignment('P0_$i', DateTime(2026, 7, 18, 9)),
      ),
      1: [_assignment('P1_0', DateTime(2026, 7, 19, 9))],
    };

    final result = await repo.getTasks();

    expect(result, hasLength(101));
    expect(remote.assignmentQueries.map((q) => q.page), [0, 1]);
  });

  test('createTask forwards holidayPolicy and assetCodes', () async {
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
      holidayPolicy: TaskHolidayPolicy.keep,
      assetCodes: const ['AST_1'],
    );
    expect(remote.lastCreateArgs!['draft'], draft);
    expect(remote.lastCreateArgs!['holidayPolicy'], TaskHolidayPolicy.keep);
    expect(remote.lastCreateArgs!['assetCodes'], ['AST_1']);
  });

  test('updateTask trims the series code and forwards new fields', () async {
    await repo.updateTask(
      seriesCode: '  TSK_1  ',
      title: 'Renamed',
      assetCodes: const ['AST_1'],
      parentTaskCode: '',
    );
    expect(remote.lastUpdateArgs!['code'], 'TSK_1');
    expect(remote.lastUpdateArgs!['title'], 'Renamed');
    expect(remote.lastUpdateArgs!['assetCodes'], ['AST_1']);
    expect(remote.lastUpdateArgs!['parentTaskCode'], '');
  });

  test('deleteTask trims the code before delegating', () async {
    await repo.deleteTask('  TSK_1  ');
    expect(remote.lastDeletedCode, 'TSK_1');
  });

  test('removeAssignee trims and forwards series + staff codes (§4a)',
      () async {
    await repo.removeAssignee(seriesCode: '  TSK_1 ', staffCode: ' STF_4 ');
    expect(remote.lastRemovedAssignee, {'code': 'TSK_1', 'staffCode': 'STF_4'});
  });

  test('getTaskSeries delegates to the datasource (§2)', () async {
    remote.nextSeriesPage = const TaskSeriesPage(
      items: [TaskSeries(code: 'TSK_1', title: 'A')],
      page: 0,
      size: 20,
      totalElements: 1,
      totalPages: 1,
    );
    final page = await repo.getTaskSeries(seriesStatus: TaskSeriesStatus.active);
    expect(page.items.single.code, 'TSK_1');
  });

  test('getBoard delegates to the datasource (§6)', () async {
    remote.nextBoard = TaskBoard(
      toDo: TaskBoardColumn(
        cards: [_assignment('A', DateTime(2026, 7, 18)).toEntity()],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
      ),
      inProgress: const TaskBoardColumn.empty(),
      completed: const TaskBoardColumn.empty(),
    );
    final board = await repo.getBoard(const TaskQuery());
    expect(board.toDo.cards.single.code, 'A');
  });

  test('updateAssignmentStatus forwards and maps the returned card', () async {
    final task = await repo.updateAssignmentStatus(
      assignmentCode: '  TSA_1  ',
      status: TaskStatus.completed,
    );
    expect(remote.lastStatusArgs!['code'], 'TSA_1');
    expect(remote.lastStatusArgs!['status'], TaskStatus.completed);
    expect(task.status, TaskStatus.completed);
  });

  test('getTask trims and maps the series detail (§2a)', () async {
    remote.nextSeries = const TaskSeriesModel(
      code: 'TSK_1',
      title: 'Detail',
      recurringFlag: true,
      rruleFreq: 'WEEKLY',
      rruleByDay: ['MO', 'WE'],
    );
    final series = await repo.getTask('  TSK_1  ');
    expect(remote.lastFetchedTaskCode, 'TSK_1');
    expect(series.recurrenceByDay, ['MO', 'WE']);
    expect(series.recurrencePattern, TaskRecurrence.weekly);
  });

  test('updateTask forwards scope + anchor for THIS_AND_FUTURE (§3d)',
      () async {
    await repo.updateTask(
      seriesCode: 'TSK_1',
      scope: TaskUpdateScope.thisAndFuture,
      anchorOccurrenceCode: 'TOC_7',
    );
    expect(remote.lastUpdateArgs!['scope'], TaskUpdateScope.thisAndFuture);
    expect(remote.lastUpdateArgs!['anchorOccurrenceCode'], 'TOC_7');
  });

  test('updateAssigneePriority trims and forwards (§4b)', () async {
    await repo.updateAssigneePriority(
      seriesCode: ' TSK_1 ',
      staffCode: ' STF_1 ',
      priority: TaskPriority.high,
    );
    expect(remote.lastAssigneePriorityArgs, {
      'code': 'TSK_1',
      'staffCode': 'STF_1',
      'priority': TaskPriority.high,
    });
  });

  test('getAssignment trims and maps the card (§5a)', () async {
    final task = await repo.getAssignment('  TSA_1  ');
    expect(remote.lastFetchedAssignmentCode, 'TSA_1');
    expect(task.code, 'TSA_1');
  });

  test('updateAssignment forwards dueAt/priority and maps the card (§5b)',
      () async {
    final due = DateTime.utc(2026, 7, 18, 17);
    final task = await repo.updateAssignment(
      assignmentCode: ' TSA_1 ',
      dueAt: due,
      priority: TaskPriority.high,
    );
    expect(remote.lastAssignmentPatchArgs!['code'], 'TSA_1');
    expect(remote.lastAssignmentPatchArgs!['dueAt'], due);
    expect(remote.lastAssignmentPatchArgs!['priority'], TaskPriority.high);
    expect(task.priority, TaskPriority.high);
  });

  test('deleteAssignment trims before delegating (§5c)', () async {
    await repo.deleteAssignment('  TSA_1  ');
    expect(remote.lastDeletedAssignmentCode, 'TSA_1');
  });

  test('getOccurrences trims and delegates (§11a)', () async {
    remote.nextOccurrences = [
      TaskOccurrence(
        code: 'TOC_1',
        taskCode: 'TSK_1',
        originalStartDate: DateTime(2026, 7, 15),
      ),
    ];
    final occ = await repo.getOccurrences('  TSK_1  ');
    expect(remote.lastOccurrencesCode, 'TSK_1');
    expect(occ.single.code, 'TOC_1');
  });

  test('updateOccurrence trims + forwards the override fields (§11c)',
      () async {
    await repo.updateOccurrence(
      seriesCode: ' TSK_1 ',
      occurrenceCode: ' TOC_7 ',
      scheduledStartDate: DateTime(2026, 7, 18),
      overrideTitle: 'Moved',
    );
    expect(remote.lastOccurrenceUpdateArgs!['code'], 'TSK_1');
    expect(remote.lastOccurrenceUpdateArgs!['occurrenceCode'], 'TOC_7');
    expect(remote.lastOccurrenceUpdateArgs!['overrideTitle'], 'Moved');
  });

  test('cancelOccurrence trims + forwards the reason (§11d)', () async {
    await repo.cancelOccurrence(
      seriesCode: ' TSK_1 ',
      occurrenceCode: ' TOC_7 ',
      reason: 'Closed',
    );
    expect(remote.lastOccurrenceCancelArgs!['code'], 'TSK_1');
    expect(remote.lastOccurrenceCancelArgs!['occurrenceCode'], 'TOC_7');
    expect(remote.lastOccurrenceCancelArgs!['reason'], 'Closed');
  });

  group('uploadAttachment (§8/§9)', () {
    test('runs session→presign→put→complete→poll and returns the asset code',
        () async {
      final tmp = await File(
        '${Directory.systemTemp.path}/task_attach_${DateTime.now().microsecondsSinceEpoch}.pdf',
      ).create();
      await tmp.writeAsBytes(List.filled(1234, 0));
      addTearDown(() => tmp.existsSync() ? tmp.delete() : null);

      final assetCode = await repo.uploadAttachment(
        filePath: tmp.path,
        fileName: 'notes.pdf',
        contentType: 'application/pdf',
      );

      expect(assetCode, 'AST_READY');
      // Steps happen in the documented order (§9.1→§9.5).
      expect(imageUpload.steps, ['presign', 'put', 'complete', 'poll']);
      expect(remote.uploadSessionCalls, 1);
      // Presign is scoped to the school with the real file size & media type.
      expect(imageUpload.presignArgs!['ownerType'], 'SCHOOL');
      expect(imageUpload.presignArgs!['ownerCode'], 'SCH_1');
      expect(imageUpload.presignArgs!['contentLengthBytes'], 1234);
      expect(imageUpload.presignArgs!['mediaType'], 'DOCUMENT');
      expect(imageUpload.presignArgs!['sessionCode'], 'SES_1');
      expect(imageUpload.waitedFor, ['AST_READY']);
    });

    test('classifies an image content type as media type IMAGE', () async {
      final tmp = await File(
        '${Directory.systemTemp.path}/task_img_${DateTime.now().microsecondsSinceEpoch}.png',
      ).create();
      await tmp.writeAsBytes(List.filled(10, 0));
      addTearDown(() => tmp.existsSync() ? tmp.delete() : null);

      await repo.uploadAttachment(
        filePath: tmp.path,
        fileName: 'photo.png',
        contentType: 'image/png',
      );
      expect(imageUpload.presignArgs!['mediaType'], 'IMAGE');
    });
  });
}
