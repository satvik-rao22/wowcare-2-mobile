import 'dart:io';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/tasks/datasources/task_remote_datasource.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Remote-only implementation backed by the events-todo Tasks API. No Isar
/// persistence or mock seeding — mirrors the Events/Holidays modules. Attachment
/// uploads (§8/§9) reuse the shared [ImageUploadService] for the document-
/// microservice half of the round trip.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(
    this._remoteDataSource,
    this._imageUploadService,
    this._storage,
  );

  final TaskRemoteDataSource _remoteDataSource;
  final ImageUploadService _imageUploadService;
  final StorageService _storage;

  /// Page size used when exhausting the flat assignments endpoint. Kept modest
  /// so a small school pays for one round trip while a large one still loads
  /// completely across a bounded number of pages.
  static const int _assignmentPageSize = 100;

  /// Hard ceiling on pages walked (safety valve against a misbehaving server
  /// that never shortens a page) — 100 pages × 100 rows = 10k assignments.
  static const int _maxAssignmentPages = 100;

  @override
  Future<List<Task>> getTasks({String? query}) async {
    // Defensive de-duplication by assignment code: a single assignment must
    // never surface as two cards even if the API echoes a row twice or across
    // page boundaries.
    final seen = <String>{};
    final tasks = <Task>[];
    var page = 0;
    while (page < _maxAssignmentPages) {
      final models = await _remoteDataSource.getAssignments(
        TaskQuery(query: query, page: page, size: _assignmentPageSize),
      );
      for (final model in models) {
        if (seen.add(model.code)) tasks.add(model.toEntity());
      }
      if (models.length < _assignmentPageSize) break;
      page++;
    }
    return tasks
      ..sort((a, b) {
        final byDue = a.dueDate.compareTo(b.dueDate);
        if (byDue != 0) return byDue;
        return a.dueTime.compareTo(b.dueTime);
      });
  }

  @override
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? query,
    int page = 0,
    int size = 20,
  }) {
    return _remoteDataSource.getTaskSeries(
      seriesStatus: seriesStatus,
      recurring: recurring,
      q: query,
      page: page,
      size: size,
    );
  }

  @override
  Future<TaskBoard> getBoard(TaskQuery query) {
    return _remoteDataSource.getBoard(query);
  }

  @override
  Future<void> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) async {
    await _remoteDataSource.createTask(
      draft: draft,
      assignees: assignees,
      holidayPolicy: holidayPolicy,
      assetCodes: assetCodes,
    );
  }

  @override
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
    String? parentTaskCode,
  }) async {
    await _remoteDataSource.updateTask(
      code: seriesCode.trim(),
      title: title,
      description: description,
      holidayPolicy: holidayPolicy,
      schedule: schedule,
      assignees: assignees,
      assetCodes: assetCodes,
      parentTaskCode: parentTaskCode,
    );
  }

  @override
  Future<void> deleteTask(String seriesCode) {
    return _remoteDataSource.deleteTask(seriesCode.trim());
  }

  @override
  Future<void> removeAssignee({
    required String seriesCode,
    required String staffCode,
  }) {
    return _remoteDataSource.removeAssignee(
      code: seriesCode.trim(),
      staffCode: staffCode.trim(),
    );
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

  @override
  Future<String> uploadAttachment({
    required String filePath,
    required String fileName,
    required String contentType,
  }) async {
    // 1. Open the school-wide task upload session on events-todo-service (§8).
    final session = await _remoteDataSource.createUploadSession();

    final file = File(filePath);
    final lengthBytes = await file.length();
    final ownerCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final mediaType =
        contentType.toLowerCase().startsWith('image/') ? 'IMAGE' : 'DOCUMENT';

    // 2. Presign against document-microservice (§9.2).
    final presign = await _imageUploadService.createAssetPresign(
      sessionCode: session.sessionCode,
      documentApiBasePath: session.documentApiBasePath,
      fileName: fileName,
      contentType: contentType,
      contentLengthBytes: lengthBytes,
      mediaType: mediaType,
      ownerType: 'SCHOOL',
      ownerCode: ownerCode,
    );

    // 3. Upload the raw bytes straight to storage (§9.3).
    await _imageUploadService.uploadFileToPresignedUrl(
      file: file,
      presignedPutUrl: presign.presignedPutUrl,
      requiredHeaders: presign.requiredHeaders,
      fallbackContentType: contentType,
    );

    // 4. Mark the asset complete (§9.4).
    await _imageUploadService.completeAssetUpload(
      sessionCode: session.sessionCode,
      assetCode: presign.assetCode,
      documentApiBasePath: session.documentApiBasePath,
    );

    // 5. Poll until the asset is READY before it can be attached (§9.5).
    await _imageUploadService.waitUntilAssetsReady(
      sessionCode: session.sessionCode,
      expectedAssetCodes: [presign.assetCode],
    );

    return presign.assetCode;
  }
}
