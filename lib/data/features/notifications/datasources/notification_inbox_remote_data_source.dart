import '../../../../core/network/api_client.dart';
import '../../../../core/util/api_paths.dart';
import '../models/app_notification_model.dart';

/// One page of inbox notifications plus whether more pages exist.
typedef NotificationInboxPage = ({
  List<AppNotificationModel> items,
  bool hasMore,
});

/// Unread / unclicked totals from `GET /notification/inbox/unread-counts`.
typedef NotificationUnreadCounts = ({int unread, int unclicked});

/// Thin HTTP wrapper over the `/api/v1/notification/inbox` endpoints (the
/// in-app bell list, read/click tracking, mark-all, and unread counts).
/// Replaces the old `/notification/logs` data source.
abstract class NotificationInboxRemoteDataSource {
  Future<NotificationInboxPage> fetchInbox({
    required String userCode,
    String? schoolCode,
    String? role,
    String? module,
    bool onlyShowUnread = false,
    int page = 0,
    int size = 10,
  });

  Future<void> markRead(String code);
  Future<void> trackClick(String code);

  Future<void> markAllRead({
    required String userCode,
    String? schoolCode,
    String? role,
  });

  Future<NotificationUnreadCounts> fetchUnreadCounts({
    required String userCode,
    String? schoolCode,
    String? role,
  });
}

class NotificationInboxRemoteDataSourceImpl
    implements NotificationInboxRemoteDataSource {
  NotificationInboxRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<NotificationInboxPage> fetchInbox({
    required String userCode,
    String? schoolCode,
    String? role,
    String? module,
    bool onlyShowUnread = false,
    int page = 0,
    int size = 10,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.notificationInbox);
    final query = <String, dynamic>{
      'userCode': userCode,
      // Spring `Pageable` sent as flat query params (page/size/sort).
      'page': page,
      'size': size,
      'sort': 'createdAt,desc',
      if (schoolCode != null && schoolCode.trim().isNotEmpty)
        'schoolCode': schoolCode.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      // Server-side filters. `module` matches the top-level module field;
      // `onlyShowUnread` is omitted when false (defaults to all).
      if (module != null && module.trim().isNotEmpty) 'module': module.trim(),
      if (onlyShowUnread) 'onlyShowUnread': true,
    };

    final response = await _apiClient.client.get(
      endpoint,
      queryParameters: query,
    );
    final data = response.data;
    if (data is! Map || data['success'] != true) {
      throw Exception(
        data is Map
            ? data['message']?.toString()
            : 'Failed to load notifications',
      );
    }

    final pageData = data['data'];
    if (pageData is! Map) {
      return (items: const <AppNotificationModel>[], hasMore: false);
    }

    final content = pageData['content'];
    if (content is! List) {
      return (items: const <AppNotificationModel>[], hasMore: false);
    }

    final items = content
        .whereType<Map>()
        .map(
          (e) =>
              AppNotificationModel.fromInboxJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    // Prefer the Spring page's `last` flag; fall back to whether a full page
    // came back (a short page means we've reached the end).
    final bool hasMore = pageData['last'] is bool
        ? !(pageData['last'] as bool)
        : items.length >= size;

    return (items: items, hasMore: hasMore);
  }

  @override
  Future<void> markRead(String code) async {
    final response = await _apiClient.client.post(
      ApiPaths.url(ApiPaths.notificationInboxRead(code)),
    );
    _ensureSuccess(response.data);
  }

  @override
  Future<void> trackClick(String code) async {
    final response = await _apiClient.client.post(
      ApiPaths.url(ApiPaths.notificationInboxClick(code)),
    );
    _ensureSuccess(response.data);
  }

  @override
  Future<void> markAllRead({
    required String userCode,
    String? schoolCode,
    String? role,
  }) async {
    final response = await _apiClient.client.post(
      ApiPaths.url(ApiPaths.notificationInboxReadAll),
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        if (schoolCode != null && schoolCode.trim().isNotEmpty)
          'schoolCode': schoolCode.trim(),
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      },
    );
    _ensureSuccess(response.data);
  }

  @override
  Future<NotificationUnreadCounts> fetchUnreadCounts({
    required String userCode,
    String? schoolCode,
    String? role,
  }) async {
    final response = await _apiClient.client.get(
      ApiPaths.url(ApiPaths.notificationInboxUnreadCounts),
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        if (schoolCode != null && schoolCode.trim().isNotEmpty)
          'schoolCode': schoolCode.trim(),
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      },
    );
    final data = response.data;
    if (data is! Map || data['success'] != true) {
      throw Exception(
        data is Map
            ? data['message']?.toString()
            : 'Failed to load unread counts',
      );
    }
    final counts = data['data'];
    if (counts is! Map) return (unread: 0, unclicked: 0);
    return (
      unread: _asInt(counts['unreadCount']),
      unclicked: _asInt(counts['unclickedCount']),
    );
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('${value ?? ''}') ?? 0;

  void _ensureSuccess(dynamic data) {
    if (data is Map && data['success'] == false) {
      throw Exception(
        data['message']?.toString() ?? 'Notification request failed',
      );
    }
  }
}
