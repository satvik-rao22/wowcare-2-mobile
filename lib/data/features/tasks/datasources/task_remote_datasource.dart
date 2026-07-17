import 'package:dio/dio.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/tasks/entities/task.dart';
import '../../../../domain/features/tasks/entities/task_assignee.dart';
import '../models/task_models.dart';

/// Talks to the Tasks API on the events-todo microservice (`/api/v1/tasks`).
/// Org/school scoping headers are attached globally by `AuthInterceptor`, so
/// nothing tenant-specific is set here.
///
/// The list is served by the flat assignments endpoint (§7) rather than the
/// grouped board (§6): the tasks cubit filters and groups into Kanban columns
/// client-side, so one ungrouped page keeps that logic untouched.
abstract class TaskRemoteDataSource {
  /// `GET /api/v1/tasks/assignments` — one page of assignment cards. [q] is
  /// the server-side free-text search filter (Tasks API §7).
  Future<List<TaskAssignmentModel>> getAssignments({
    int page,
    int size,
    String? q,
  });

  /// `POST /api/v1/tasks` — create a series and its roster.
  Future<TaskSeriesModel> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    List<String> assetCodes,
  });

  /// `PATCH /api/v1/tasks/{code}` — partial series update / roster replace.
  /// [schedule], when non-null, carries the recurrence rule and series
  /// dates/times to persist (Tasks API §3 full parity).
  Future<TaskSeriesModel> updateTask({
    required String code,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
  });

  /// `DELETE /api/v1/tasks/{code}` — soft-delete the series.
  Future<void> deleteTask(String code);

  /// `PATCH /api/v1/tasks/assignments/{code}/status` — change one card's status.
  Future<TaskAssignmentModel> updateAssignmentStatus({
    required String code,
    required TaskStatus status,
  });
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._client, this._storage);

  final Dio _client;
  final StorageService _storage;

  /// The cubit filters client-side, so we pull a single generous page rather
  /// than paginating. Sized well above any realistic per-school task count.
  static const int _defaultPageSize = 500;

  /// `POST /api/v1/tasks` needs `X-Staff-Code` — the logged-in user's staff
  /// code, used as `assignedBy` on the `TASK_ASSIGNED` notification (Tasks API
  /// header table). Org/school scoping headers are attached globally by
  /// `AuthInterceptor`; this one is create-specific so it lives here and is
  /// only sent when [withStaffCode] is set. The value is the staff code
  /// resolved and cached at load time (see the tasks cubit).
  Future<Options> _options({bool withStaffCode = false}) async {
    if (!withStaffCode) return Options();
    final staffCode =
        (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
    return Options(
      headers: <String, dynamic>{
        if (staffCode.isNotEmpty) 'X-Staff-Code': staffCode,
      },
    );
  }

  @override
  Future<List<TaskAssignmentModel>> getAssignments({
    int page = 0,
    int size = _defaultPageSize,
    String? q,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.taskAssignments,
      ApiConstants.eventsTodoBaseUrl,
    );

    final query = (q ?? '').trim();
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'page': page,
        'size': size,
        if (query.isNotEmpty) 'q': query,
      },
      options: await _options(),
    );

    return _parseAssignmentList(response.data);
  }

  @override
  Future<TaskSeriesModel> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    List<String> assetCodes = const [],
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.tasks,
      ApiConstants.eventsTodoBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: TaskRequestBuilder.createBody(
        draft: draft,
        assignees: assignees,
        assetCodes: assetCodes,
      ),
      options: await _options(withStaffCode: true),
    );

    return _parseSeries(response.data, action: 'create');
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
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.taskByCode(code),
      ApiConstants.eventsTodoBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: TaskRequestBuilder.updateBody(
        title: title,
        description: description,
        holidayPolicy: holidayPolicy,
        schedule: schedule,
        assignees: assignees,
      ),
      options: await _options(),
    );

    return _parseSeries(response.data, action: 'update');
  }

  @override
  Future<void> deleteTask(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.taskByCode(code),
      ApiConstants.eventsTodoBaseUrl,
    );
    try {
      await _client.delete<dynamic>(endpoint, options: await _options());
    } on DioException catch (e) {
      // Already deleted on the server → treat as success (idempotent), so a
      // stale card can still be cleared from the board instead of erroring.
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  @override
  Future<TaskAssignmentModel> updateAssignmentStatus({
    required String code,
    required TaskStatus status,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.taskAssignmentStatus(code),
      ApiConstants.eventsTodoBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: TaskRequestBuilder.statusBody(status),
      options: await _options(),
    );

    return _parseAssignmentSingle(response.data);
  }

  static List<TaskAssignmentModel> _parseAssignmentList(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const <TaskAssignmentModel>[];
    final data = raw['data'];
    final items = data is Map<String, dynamic> ? data['items'] : data;
    if (items is! List) return const <TaskAssignmentModel>[];

    final result = <TaskAssignmentModel>[];
    for (final entry in items) {
      if (entry is! Map) continue;
      final model = TaskAssignmentModel.fromJson(
        entry.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (model.code.isNotEmpty) result.add(model);
    }
    return result;
  }

  static TaskSeriesModel _parseSeries(dynamic raw, {required String action}) {
    final data = _requireData(raw, action: action);
    return TaskSeriesModel.fromJson(data);
  }

  static TaskAssignmentModel _parseAssignmentSingle(dynamic raw) {
    final data = _requireData(raw, action: 'status update');
    return TaskAssignmentModel.fromJson(data);
  }

  static Map<String, dynamic> _requireData(dynamic raw, {required String action}) {
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected task $action API response format');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload in task $action response');
    }
    return data;
  }
}
