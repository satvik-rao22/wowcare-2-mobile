import '../../../../core/network/api_client.dart';
import '../../../../core/util/api_paths.dart';
import '../models/app_notification_model.dart';

abstract class NotificationLogsRemoteDataSource {
  Future<List<AppNotificationModel>> fetchLogs({
    required String userCode,
    String? schoolCode,
    int page = 0,
    int size = 50,
  });

  Future<void> markRead(String code);
  Future<void> markAllRead(String userCode);
  Future<void> trackClick(String code);
}

class NotificationLogsRemoteDataSourceImpl
    implements NotificationLogsRemoteDataSource {
  NotificationLogsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<AppNotificationModel>> fetchLogs({
    required String userCode,
    String? schoolCode,
    int page = 0,
    int size = 50,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.notificationLogs);
    final query = <String, dynamic>{
      'userCode': userCode,
      'page': page,
      'size': size,
      'sort': 'sentAt,desc',
      if (schoolCode != null && schoolCode.trim().isNotEmpty)
        'schoolCode': schoolCode.trim(),
    };

    final response = await _apiClient.client.get(endpoint, queryParameters: query);
    final data = response.data;
    if (data is! Map || data['success'] != true) {
      throw Exception(
        data is Map ? data['message']?.toString() : 'Failed to load notifications',
      );
    }

    final pageData = data['data'];
    if (pageData is! Map) return const [];

    final content = pageData['content'];
    if (content is! List) return const [];

    return content
        .whereType<Map>()
        .map((e) => AppNotificationModel.fromDeliveryLogJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  @override
  Future<void> markRead(String code) async {
    final endpoint = ApiPaths.url(ApiPaths.notificationLogRead(code));
    final response = await _apiClient.client.post(endpoint);
    _ensureSuccess(response.data);
  }

  @override
  Future<void> markAllRead(String userCode) async {
    final endpoint = ApiPaths.url(ApiPaths.notificationLogsReadAll);
    final response = await _apiClient.client.post(
      endpoint,
      queryParameters: {'userCode': userCode},
    );
    _ensureSuccess(response.data);
  }

  @override
  Future<void> trackClick(String code) async {
    final endpoint = ApiPaths.url(ApiPaths.notificationLogClick(code));
    final response = await _apiClient.client.post(endpoint);
    _ensureSuccess(response.data);
  }

  void _ensureSuccess(dynamic data) {
    if (data is Map && data['success'] == false) {
      throw Exception(data['message']?.toString() ?? 'Notification request failed');
    }
  }
}
