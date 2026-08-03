import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/notifications/models/notification_preference_model.dart';

abstract class NotificationPreferencesRemoteDataSource {
  /// `GET /api/v1/notification/preferences`
  Future<List<NotificationPreferenceModel>> getPreferences({
    required String userCode,
    required String schoolCode,
    required String role,
    String? organizationCode,
  });

  /// `PATCH /api/v1/notification/preferences?userCode=…`
  Future<void> updatePreferences({
    required String userCode,
    required UpdateNotificationPreferencesRequest request,
  });
}

class NotificationPreferencesRemoteDataSourceImpl
    implements NotificationPreferencesRemoteDataSource {
  NotificationPreferencesRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<List<NotificationPreferenceModel>> getPreferences({
    required String userCode,
    required String schoolCode,
    required String role,
    String? organizationCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.notificationPreferences),
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'schoolCode': schoolCode,
        'role': role,
        if (organizationCode != null && organizationCode.isNotEmpty)
          'organizationCode': organizationCode,
      },
    );
    final data = response.data?['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(NotificationPreferenceModel.fromJson)
          .toList();
    }
    return const <NotificationPreferenceModel>[];
  }

  @override
  Future<void> updatePreferences({
    required String userCode,
    required UpdateNotificationPreferencesRequest request,
  }) async {
    await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.notificationPreferences),
      queryParameters: <String, dynamic>{'userCode': userCode},
      data: request.toJson(),
    );
  }
}
