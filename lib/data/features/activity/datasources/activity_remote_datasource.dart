import 'package:dio/dio.dart';
import 'dart:async';

import '../../../../core/network/session_expired_interceptor.dart'
    show kNoAutoReplayExtraKey;
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/activity_asset_presign_model.dart';
import '../models/activity_feed_models.dart';
import '../models/activity_settings_models.dart';
import '../models/activity_type_details_model.dart';
import '../models/activity_upload_session_models.dart';

abstract class ActivityRemoteDataSource {
  /// `GET /api/v2/activities/{cardGroupCode}` — returns inner `data` map.
  ///
  /// `GET /api/v2/activities/{cardGroupCode}`
  Future<Map<String, dynamic>> getActivityByCode({
    required String cardGroupCode,
  });

  /// `PATCH /api/v2/activities/{cardGroupCode}`
  Future<String> updateActivity({
    required String cardGroupCode,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    required List<Map<String, dynamic>> parameterValues,
    required List<Map<String, dynamic>> attachments,
  });

  /// `DELETE /api/v2/activities/{cardGroupCode}`.
  Future<String> deleteActivity({required String code});

  /// `POST /api/v2/admin/activities/{cardGroupCode}/approve`.
  Future<String> approveActivity({required String cardGroupCode});

  /// `POST /api/v2/admin/activities/{cardGroupCode}/reject`.
  Future<String> rejectActivity({required String cardGroupCode});

  /// `POST /api/v2/guardian/activities/{cardGroupCode}/acknowledge`.
  Future<String> acknowledgeActivity({required String cardGroupCode});

  /// `PATCH /api/v2/guardian/activities/{cardGroupCode}/parent-signature`.
  Future<String> guardianParentSignature({
    required String cardGroupCode,
    required String parameterCode,
    required String guardianCode,
    String? signatureValue,
  });

  /// Fetches activity settings for a classroom via
  /// `GET /api/v1/classrooms/{classroomCode}/activity-settings`.
  Future<List<ActivitySettingModel>> getClassroomActivitySettings({
    required String classroomCode,
  });

  /// Fetches activity type details via
  /// `GET /api/v1/activity-types/{code}`.
  Future<ActivityTypeDetailsModel> getActivityTypeDetails({
    required String code,
  });

  /// Fetches all active activity types for a school via
  /// `GET /api/v1/activity-types?schoolCode={schoolCode}`.
  Future<List<Map<String, dynamic>>> getActiveActivityTypesForSchool({
    required String schoolCode,
  });

  /// Creates grouped activity cards via `POST /api/v2/activities`.
  Future<String> createActivity({
    required ActivityCreateRequestModel request,
  });

  /// `GET /api/v1/activities/{classroomCode}/nap-start-students`
  Future<List<String>> getNapStartStudents({
    required String classroomCode,
  });

  /// Creates shared activity cards via `POST /api/v2/activities`.
  ///
  /// Returns `data` list (each entry is a shared card payload).
  Future<List<Map<String, dynamic>>> createSharedActivities({
    required Map<String, dynamic> payload,
  });

  /// Creates upload sessions for activity attachments.
  /// `POST /api/v2/activities/upload-sessions`
  Future<ActivityUploadSessionModel> createActivityUploadSessions({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
  });

  /// Presigns one media asset in a previously created upload session.
  /// `POST /document-ms/api/v1/upload-sessions/{sessionCode}/assets/presign/batch`
  Future<ActivityAssetPresignModel> createActivityAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    required String checksumSha256,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  });

  /// Daily classroom feed:
  /// `POST /api/v2/activities/feed/daily/search`.
  Future<ActivityFeedPageModel> getDailyActivityFeed({
    required String classroomCode,
    required String date,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  });

  /// Date range classroom feed:
  /// `POST /api/v2/activities/feed/range/search`.
  Future<ActivityFeedPageModel> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  });

  /// Count of pending incident approvals:
  /// `GET /api/v2/activities/admin/activities/pending-incident-count`.
  Future<int> getPendingIncidentCount();
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  ActivityRemoteDataSourceImpl(this._client);

  final Dio _client;

  /// Opts a request OUT of the shared 401-refresh auto-replay. Applied to the
  /// non-idempotent activity mutations (create/shared-create/update, upload
  /// session, asset presign) so a token-refresh replay cannot silently create a
  /// duplicate activity or duplicate media. See [kNoAutoReplayExtraKey].
  Options get _noReplayOptions =>
      Options(extra: const {kNoAutoReplayExtraKey: true});

  bool _isAssetNotReadyConflict(Object error) {
    if (error is! DioException) return false;
    if (error.response?.statusCode != 409) return false;
    final data = error.response?.data;
    if (data is! Map<String, dynamic>) return false;
    final message = (data['message'] ?? '').toString().toLowerCase();
    return message.contains('must reach ready before linking');
  }

  List<String> _normalizedCodes(Iterable<String> codes) {
    final out = <String>[];
    for (final c in codes) {
      final v = c.trim();
      if (v.isEmpty || out.contains(v)) continue;
      out.add(v);
    }
    return out;
  }

  List<Map<String, dynamic>> _normalizedPatchAttachments(
    List<Map<String, dynamic>> attachments,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final row in attachments) {
      final assetCode = (row['assetCode'] ?? '').toString().trim();
      if (assetCode.isEmpty) continue;
      final studentCode = (row['studentCode'] ?? '').toString().trim();
      final bindingMode = (row['bindingMode'] ?? '').toString().trim();
      final isShared = bindingMode.toUpperCase() == 'SHARED';
      out.add({
        'assetCode': assetCode,
        // For SHARED attachments backend expects no studentCode.
        if (studentCode.isNotEmpty &&
            !isShared &&
            studentCode.toUpperCase().startsWith('STD_'))
          'studentCode': studentCode,
      });
    }
    return out;
  }

  @override
  Future<Map<String, dynamic>> getActivityByCode({
    required String cardGroupCode,
  }) async {
    final raw = cardGroupCode.trim();
    final segment = raw.contains('/') ? Uri.encodeComponent(raw) : raw;
    final base = ApiPaths.url('/api/v2/activities');
    final endpoint = '$base/$segment';
    final response = await _client.get<dynamic>(endpoint);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected get-activity API response format');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected get-activity API data format');
    }
    return data;
  }

  @override
  Future<String> updateActivity({
    required String cardGroupCode,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    required List<Map<String, dynamic>> parameterValues,
    required List<Map<String, dynamic>> attachments,
  }) async {
    final base = ApiPaths.url('/api/v2/activities');
    final raw = cardGroupCode.trim();
    final segment = raw.contains('/') ? Uri.encodeComponent(raw) : raw;
    final endpoint = '$base/$segment';
    final normalizedStudentCodes = _normalizedCodes(studentCodes);
    final normalizedApplyToCodes = _normalizedCodes(applyToStudentCodes);
    final effectiveStudentCodes = normalizedApplyToCodes.isNotEmpty
        ? normalizedApplyToCodes
        : normalizedStudentCodes;
    final normalizedAttachments = _normalizedPatchAttachments(attachments);

    final payload = <String, dynamic>{
      if (effectiveStudentCodes.isNotEmpty) 'studentCodes': effectiveStudentCodes,
      if (normalizedApplyToCodes.isNotEmpty)
        'applyToStudentCodes': normalizedApplyToCodes,
      'staffCode': staffCode,
      'activityDate': activityDate,
      'description': description,
      'parameterValues': parameterValues,
      'attachments': normalizedAttachments,
    };
    const maxReadyRetries = 2;
    Response<dynamic> response;
    var attempt = 0;
    while (true) {
      try {
        response = await _client.patch<dynamic>(
          endpoint,
          data: payload,
          options: _noReplayOptions,
        );
        break;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        final message = responseData is Map<String, dynamic>
            ? (responseData['message'] ?? '').toString().trim()
            : '';
        final isAssetNotReadyConflict = statusCode == 409 &&
            message.toLowerCase().contains('must reach ready before linking');
        if (!isAssetNotReadyConflict || attempt >= maxReadyRetries) {
          rethrow;
        }
        attempt += 1;
        // Asset readiness can lag briefly after upload completion.
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      }
    }
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected update-activity API response format');
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Activity updated successfully';
  }

  @override
  Future<String> deleteActivity({required String code}) async {
    final base = ApiPaths.url('/api/v2/activities');
    final raw = code.trim();
    final segment = raw.contains('/') ? Uri.encodeComponent(raw) : raw;
    final endpoint = '$base/$segment';
    final response = await _client.delete<dynamic>(endpoint);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected delete-activity API response format');
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Activity deleted successfully';
  }

  @override
  Future<String> approveActivity({required String cardGroupCode}) async {
    final endpoint = ApiPaths.url(ApiPaths.adminApproveActivity(cardGroupCode));
    final response = await _client.post<dynamic>(endpoint);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected approve-activity API response format');
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Activity approved successfully';
  }

  @override
  Future<String> rejectActivity({required String cardGroupCode}) async {
    final endpoint = ApiPaths.url(ApiPaths.adminRejectActivity(cardGroupCode));
    final response = await _client.post<dynamic>(endpoint);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected reject-activity API response format');
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Activity rejected successfully';
  }

  @override
  Future<String> acknowledgeActivity({required String cardGroupCode}) async {
    final endpoint = ApiPaths.url(
      ApiPaths.guardianAcknowledgeActivity(cardGroupCode),
    );
    final response = await _client.post<dynamic>(endpoint);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian-acknowledge API response format');
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Activity acknowledged successfully';
  }

  @override
  Future<String> guardianParentSignature({
    required String cardGroupCode,
    required String parameterCode,
    required String guardianCode,
    String? signatureValue,
  }) async {
    final trimmedCode = guardianCode.trim();
    final effective = (signatureValue != null && signatureValue.trim().isNotEmpty)
        ? signatureValue.trim()
        : trimmedCode;
    final endpoint = ApiPaths.url(
      ApiPaths.guardianParentSignatureActivity(cardGroupCode),
    );
    final response = await _client.patch<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'parameterCode': parameterCode.trim(),
        'value': effective,
        'valueText': effective,
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian-parent-signature API response format');
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Activity signed successfully';
  }

  @override
  Future<List<ActivitySettingModel>> getClassroomActivitySettings({
    required String classroomCode,
  }) async {
    final base = ApiPaths.urlWithBase(
      ApiPaths.classroomActivitySettingsRoot,
      ApiConstants.activityBaseUrl,
    );
    final endpoint = '$base/$classroomCode/activity-settings';

    final response = await _client.get<dynamic>(endpoint);
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected activity-settings API response format');
    }

    final List<dynamic> data = body['data'] as List<dynamic>? ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(ActivitySettingModel.fromJson)
        .toList();
  }

  @override
  Future<ActivityTypeDetailsModel> getActivityTypeDetails({
    required String code,
  }) async {
    final base = ApiPaths.urlWithBase(
      ApiPaths.activityTypesRoot,
      ApiConstants.activityBaseUrl,
    );
    final endpoint = '$base/$code';

    final response = await _client.get<dynamic>(endpoint);
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected activity-type API response format');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected activity-type API data format');
    }

    return ActivityTypeDetailsModel.fromJson(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveActivityTypesForSchool({
    required String schoolCode,
  }) async {
    final base = ApiPaths.urlWithBase(
      ApiPaths.activityTypesRoot,
      ApiConstants.activityBaseUrl,
    );
    final uri = Uri.parse(base).replace(
      queryParameters: {'schoolCode': schoolCode.trim()},
    );
    final response = await _client.getUri<dynamic>(uri);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected activity-types API response format');
    }
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<String> createActivity({
    required ActivityCreateRequestModel request,
  }) async {
    final endpoint = ApiPaths.url('/api/v2/activities');
    late Response<dynamic> response;
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        response = await _client.post<dynamic>(
          endpoint,
          data: request.toJson(),
          options: _noReplayOptions,
        );
        break;
      } catch (e) {
        if (!_isAssetNotReadyConflict(e) || attempt >= 4) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      }
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected create-activity API response format');
    }

    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return 'Activity created successfully';
  }

  @override
  Future<List<String>> getNapStartStudents({
    required String classroomCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.activityNapStartStudents(classroomCode),
      ApiConstants.activityBaseUrl,
    );
    final response = await _client.get<dynamic>(endpoint);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected nap-start-students API response format');
    }
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> createSharedActivities({
    required Map<String, dynamic> payload,
  }) async {
    final endpoint = ApiPaths.url('/api/v2/activities');
    late Response<dynamic> response;
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        response = await _client.post<dynamic>(
          endpoint,
          data: payload,
          options: _noReplayOptions,
        );
        break;
      } catch (e) {
        if (!_isAssetNotReadyConflict(e) || attempt >= 4) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      }
    }
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected create shared-activities API response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Create shared activities failed',
      );
    }

    final data = body['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<ActivityUploadSessionModel> createActivityUploadSessions({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.activitiesUploadSessions,
      ApiConstants.activityBaseUrl,
    );

    final payload = <String, dynamic>{
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'classroomCode': classroomCode,
      'activityTypeCode': activityTypeCode,
      'bindingMode': bindingMode,
      'studentCodes': studentCodes,
    };

    final response = await _client.post<dynamic>(
      endpoint,
      data: payload,
      options: _noReplayOptions,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected upload-sessions API response format');
    }

    final success = body['success'];
    if (success == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Upload session creation failed',
      );
    }

    return ActivityUploadSessionModel.fromUploadSessionResponse(body);
  }

  @override
  Future<ActivityAssetPresignModel> createActivityAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    required String checksumSha256,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  }) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    var basePath = documentApiBasePath.trim();
    if (basePath.isEmpty) {
      basePath = ApiConstants.isGatewayEnv ? '/api/v1/document' : '/document-ms/api/v1';
    }
    if (!basePath.startsWith('/')) {
      basePath = '/$basePath';
    }
    // UAT: documentMsBaseUrl is the bare gateway host, so the document MS
    // namespace (`/api/v1/document`) must live in the path itself.
    if (ApiConstants.isGatewayEnv && !basePath.startsWith('/api/v1/document')) {
      basePath = '/api/v1/document';
    }
    basePath = basePath.replaceAll(RegExp(r'/+$'), '');
    final endpoint =
        '$origin$basePath/upload-sessions/$sessionCode/assets/presign/batch';

    final payload = <String, dynamic>{
      'assets': <Map<String, dynamic>>[
        <String, dynamic>{
          'fileName': fileName,
          'contentType': contentType,
          'contentLengthBytes': contentLengthBytes,
          'checksumSha256': checksumSha256,
          'mediaType': mediaType,
          'ownerType': ownerType,
          'ownerCode': ownerCode,
        },
      ],
    };

    final response = await _client.post<dynamic>(
      endpoint,
      data: payload,
      options: _noReplayOptions,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected assets presign API response format');
    }
    final success = body['success'];
    if (success == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(message.isNotEmpty ? message : 'Assets presign failed');
    }
    return ActivityAssetPresignModel.fromResponse(body);
  }

  @override
  Future<ActivityFeedPageModel> getDailyActivityFeed({
    required String classroomCode,
    required String date,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  }) async {
    final ats = (activityTypeCodes ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final statuses = (approvalStatuses ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final selectedClassroomCodes = _normalizedCodes(<String>[
      ...?classroomCodes,
      classroomCode,
    ]);
    final sc = studentCode?.trim();
    final selectedStudentCodes = _normalizedCodes(<String>[
      ...?studentCodes,
      if (sc != null) sc,
    ]);

    final base = ApiPaths.urlWithBase(
      guardianPersona
          ? ApiPaths.guardianActivitiesFeedDailySearch
          : ApiPaths.activitiesFeedDailySearch,
      ApiConstants.activityBaseUrl,
    );
    final qp = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': <String>['activityDate,desc'],
    };
    final payload = <String, dynamic>{
      'date': date.trim(),
      'studentCodes': selectedStudentCodes,
      'activityTypeCodes': ats,
      'approvalStatuses': statuses,
    };
    if (!guardianPersona) {
      payload['classroomCodes'] = selectedClassroomCodes;
    }

    final response = await _client.post<dynamic>(
      base,
      queryParameters: qp,
      data: payload,
    );
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected daily activity feed API response format');
    }

    return ActivityFeedPageModel.fromJson(body);
  }

  @override
  Future<ActivityFeedPageModel> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  }) async {
    final ats = (activityTypeCodes ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final statuses = (approvalStatuses ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final selectedClassroomCodes = _normalizedCodes(<String>[
      ...?classroomCodes,
      classroomCode,
    ]);
    final sc = studentCode?.trim();
    final selectedStudentCodes = _normalizedCodes(<String>[
      ...?studentCodes,
      if (sc != null) sc,
    ]);

    final base = ApiPaths.urlWithBase(
      guardianPersona
          ? ApiPaths.guardianActivitiesFeedRangeSearch
          : ApiPaths.activitiesFeedRangeSearch,
      ApiConstants.activityBaseUrl,
    );
    final qp = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': <String>['activityDate,desc'],
    };
    final payload = <String, dynamic>{
      'startDate': startDate.trim(),
      'endDate': endDate.trim(),
      'studentCodes': selectedStudentCodes,
      'activityTypeCodes': ats,
      'approvalStatuses': statuses,
    };
    if (!guardianPersona) {
      payload['classroomCodes'] = selectedClassroomCodes;
    }

    final response = await _client.post<dynamic>(
      base,
      queryParameters: qp,
      data: payload,
    );
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected range activity feed API response format');
    }

    return ActivityFeedPageModel.fromJson(body);
  }

  @override
  Future<int> getPendingIncidentCount() async {
    final url = ApiPaths.urlWithBase(
      ApiPaths.pendingIncidentCount,
      ApiConstants.activityBaseUrl,
    );
    final response = await _client.get<dynamic>(url);
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected pending incident count API response format');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data field in pending incident count response');
    }

    final count = data['count'];
    return count is int ? count : 0;
  }
}


