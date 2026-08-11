import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/notifications/models/notification_preference_group_model.dart';

abstract class NotificationPreferenceGroupsRemoteDataSource {
  /// `GET /api/v1/notification/preferences/groups`
  Future<List<NotificationPreferenceGroupModel>> getGroups({
    required String userCode,
  });

  /// `PATCH /api/v1/notification/preferences/groups`
  Future<void> updateGroups({
    required String userCode,
    required UpdateNotificationPreferenceGroupsRequest request,
  });
}

class NotificationPreferenceGroupsRemoteDataSourceImpl
    implements NotificationPreferenceGroupsRemoteDataSource {
  NotificationPreferenceGroupsRemoteDataSourceImpl(this._client);

  final Dio _client;

  // Org/school/role/auth headers are attached globally by AuthInterceptor —
  // only the user-scoping header needs to be added here.
  Map<String, dynamic> _headers(String userCode) => <String, dynamic>{
        'X-User-Code': userCode,
      };

  @override
  Future<List<NotificationPreferenceGroupModel>> getGroups({
    required String userCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.notificationPreferenceGroups),
      options: Options(headers: _headers(userCode)),
    );
    final data = response.data?['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(NotificationPreferenceGroupModel.fromJson)
          .toList();
    }
    return const <NotificationPreferenceGroupModel>[];
  }

  @override
  Future<void> updateGroups({
    required String userCode,
    required UpdateNotificationPreferenceGroupsRequest request,
  }) async {
    await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.notificationPreferenceGroups),
      options: Options(headers: _headers(userCode)),
      data: request.toJson(),
    );
  }
}
