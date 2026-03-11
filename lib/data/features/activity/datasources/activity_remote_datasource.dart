import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/activity_settings_models.dart';

abstract class ActivityRemoteDataSource {
  /// Fetches activity settings for a classroom via
  /// `GET /api/v1/classrooms/{classroomCode}/activity-settings`.
  Future<List<ActivitySettingModel>> getClassroomActivitySettings({
    required String classroomCode,
  });

  /// Creates a new activity via `POST /api/v1/activities`.
  Future<String> createActivity({
    required ActivityCreateRequestModel request,
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
}


