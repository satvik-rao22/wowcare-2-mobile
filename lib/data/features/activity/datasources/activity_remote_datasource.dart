import 'package:dio/dio.dart';
import 'dart:async';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/activity_asset_presign_model.dart';
import '../models/activity_feed_models.dart';
import '../models/activity_settings_models.dart';
import '../models/activity_type_details_model.dart';
import '../models/activity_upload_session_models.dart';

abstract class ActivityRemoteDataSource {
  /// `GET /api/v2/activities/{cardGroupCode}` — returns inner `data` map.
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
  /// `POST /document-ms/api/v1/upload-sessions/{sessionCode}/assets/presign`
  Future<ActivityAssetPresignModel> createActivityAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  });

  /// Daily classroom feed: `GET /api/v2/activities/feed/daily`.
  Future<ActivityFeedPageModel> getDailyActivityFeed({
    required String classroomCode,
    required String date,
    String? studentCode,
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  });

  /// Date range classroom feed: `GET /api/v1/activities/feed/range`.
  Future<ActivityFeedPageModel> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  });
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  ActivityRemoteDataSourceImpl(this._client);

  final Dio _client;

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
        if (bindingMode.isNotEmpty) 'bindingMode': bindingMode,
      });
    }
    return out;
  }

  @override
  Future<Map<String, dynamic>> getActivityByCode({
    required String cardGroupCode,
  }) async {
    final base = ApiPaths.url('/api/v2/activities');
    final raw = cardGroupCode.trim();
    final segment = raw.contains('/') ? Uri.encodeComponent(raw) : raw;
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
    final attachmentBindingMode = normalizedAttachments
        .map((a) => (a['bindingMode'] ?? '').toString().trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final effectiveBindingMode = effectiveStudentCodes.length <= 1
        ? 'PER_STUDENT'
        : (attachmentBindingMode.isNotEmpty ? attachmentBindingMode : 'SHARED');

    final payload = <String, dynamic>{
      if (effectiveStudentCodes.isNotEmpty) 'studentCodes': effectiveStudentCodes,
      if (normalizedApplyToCodes.isNotEmpty)
        'applyToStudentCodes': normalizedApplyToCodes,
      'staffCode': staffCode,
      'activityDate': activityDate,
      'description': description,
      'parameterValues': parameterValues,
      'bindingMode': effectiveBindingMode,
      'attachments': normalizedAttachments,
    };
    final response = await _client.patch<dynamic>(endpoint, data: payload);
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
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  }) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    var basePath = documentApiBasePath.trim();
    if (basePath.isEmpty) {
      basePath = '/document-ms/api/v1';
    }
    if (!basePath.startsWith('/')) {
      basePath = '/$basePath';
    }
    basePath = basePath.replaceAll(RegExp(r'/+$'), '');
    final endpoint =
        '$origin$basePath/upload-sessions/$sessionCode/assets/presign';

    final payload = <String, dynamic>{
      'fileName': fileName,
      'contentType': contentType,
      'contentLengthBytes': contentLengthBytes,
      'mediaType': mediaType,
      'ownerType': ownerType,
      'ownerCode': ownerCode,
    };

    final response = await _client.post<dynamic>(
      endpoint,
      data: payload,
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
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  }) async {
    final base = ApiPaths.urlWithBase(
      ApiPaths.activitiesFeedDaily,
      ApiConstants.activityBaseUrl,
    );
    final qp = <String, String>{
      'classroomCode': classroomCode.trim(),
      'date': date.trim(),
      'page': '$page',
      'size': '$size',
      'sort': 'activityDate,desc',
    };
    final sc = studentCode?.trim();
    if (sc != null && sc.isNotEmpty) {
      qp['studentCode'] = sc;
    }
    final at = activityTypeCode?.trim();
    if (at != null && at.isNotEmpty) {
      qp['activityTypeCode'] = at;
    }

    final uri = Uri.parse(base).replace(queryParameters: qp);
    final response = await _client.getUri<dynamic>(uri);
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
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  }) async {
    final base = ApiPaths.urlWithBase(
      ApiPaths.activitiesFeedRange,
      ApiConstants.activityBaseUrl,
    );

    final qp = <String, String>{
      'classroomCode': classroomCode.trim(),
      'startDate': startDate.trim(),
      'endDate': endDate.trim(),
      'page': '$page',
      'size': '$size',
      'sort': 'activityDate,desc',
    };

    final sc = studentCode?.trim();
    if (sc != null && sc.isNotEmpty) {
      qp['studentCode'] = sc;
    }

    final at = activityTypeCode?.trim();
    if (at != null && at.isNotEmpty) {
      qp['activityTypeCode'] = at;
    }

    final uri = Uri.parse(base).replace(queryParameters: qp);
    final response = await _client.getUri<dynamic>(uri);
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected range activity feed API response format');
    }

    return ActivityFeedPageModel.fromJson(body);
  }
}


