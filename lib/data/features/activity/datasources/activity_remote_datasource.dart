import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/activity_feed_models.dart';
import '../models/activity_settings_models.dart';
import '../models/activity_type_details_model.dart';

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

  /// Daily classroom feed: `GET /api/v1/activities/feed/daily`.
  Future<ActivityFeedPageModel> getDailyActivityFeed({
    required String classroomCode,
    required String date,
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
}


