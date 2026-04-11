import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/activity_asset_presign_model.dart';
import '../models/activity_feed_models.dart';
import '../models/activity_settings_models.dart';
import '../models/activity_type_details_model.dart';
import '../models/activity_upload_session_models.dart';

abstract class ActivityRemoteDataSource {
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

  /// Creates a new activity via `POST /api/v1/activities`.
  Future<String> createActivity({
    required ActivityCreateRequestModel request,
  });

  /// Creates upload sessions for activity attachments.
  /// `POST /api/v1/activities/upload-sessions`
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

  /// Daily classroom feed: `GET /api/v1/activities/feed/daily`.
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
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.activities,
      ApiConstants.activityBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

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


