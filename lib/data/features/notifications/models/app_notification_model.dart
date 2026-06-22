import '../../../../domain/features/notifications/entities/app_notification.dart';
import '../../../../domain/features/notifications/entities/notification_category.dart';

/// Data-layer representation of an [AppNotification].
///
/// [fromJson] is written against the anticipated backend contract so that when
/// a real notification-center endpoint replaces the mock data source, only the
/// data source changes — this model already knows how to parse the response.
class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.title,
    required super.category,
    required super.createdAt,
    required super.isRead,
    super.body,
    super.subjectName,
    super.data,
  });

  /// Maps `GET /api/v1/notification/logs` delivery-log rows.
  ///
  /// The visible text and the deep-link payload are nested under
  /// `providerResponse`:
  /// ```
  /// providerResponse.notification.{title, body}
  /// providerResponse.data.{action, module, studentCode, classroomCode, ...}
  /// ```
  factory AppNotificationModel.fromDeliveryLogJson(Map<String, dynamic> json) {
    final provider = json['providerResponse'];
    final providerMap = provider is Map ? provider : const <dynamic, dynamic>{};
    final notif = providerMap['notification'];
    final notifMap = notif is Map ? notif : const <dynamic, dynamic>{};
    final payload = providerMap['data'];

    // Deep-link payload → string map; this drives tap redirection through the
    // same NotificationRouteResolver the FCM-tap path uses.
    final data = <String, String>{};
    if (payload is Map) {
      payload.forEach((key, value) {
        if (value != null) data['$key'] = value.toString();
      });
    }
    // Carry org/school so a multi-school tap can switch school before routing.
    for (final key in const ['organizationCode', 'schoolCode', 'role']) {
      final v = json[key];
      if (v != null && '$v'.trim().isNotEmpty) {
        data.putIfAbsent(key, () => '$v');
      }
    }

    final metadata = json['metadata'];
    final meta = <String, String>{};
    if (metadata is Map) {
      metadata.forEach((key, value) {
        meta['$key'] = value?.toString() ?? '';
      });
    }

    final title = _firstNonEmpty([
      notifMap['title']?.toString(),
      meta['title'],
    ]);

    final body = _firstNonEmpty([
      notifMap['body']?.toString(),
      meta['body'],
      json['errorMessage']?.toString(),
    ]);

    final subjectName = _firstNonEmpty([
      data['studentName'],
      data['staffName'],
      data['subjectName'],
      data['personName'],
      data['name'],
    ]);

    final categoryRaw = _firstNonEmpty([
      data['module'],
      data['category'],
      meta['module'],
    ]);

    final sentAt = json['sentAt'] ?? json['deliveredAt'] ?? json['createdAt'];
    final readAt = json['readAt'];

    return AppNotificationModel(
      id: (json['code'] ?? json['id'] ?? '').toString(),
      title: title.isEmpty ? 'Notification' : title,
      body: body.isEmpty ? null : body,
      subjectName: subjectName.isEmpty ? null : subjectName,
      category: NotificationCategory.fromApi(categoryRaw),
      createdAt: DateTime.tryParse(sentAt?.toString() ?? '') ?? DateTime.now(),
      isRead: readAt != null && readAt.toString().isNotEmpty,
      data: data,
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = <String, String>{};
    if (rawData is Map) {
      rawData.forEach((key, value) {
        data['$key'] = value?.toString() ?? '';
      });
    }

    return AppNotificationModel(
      id: (json['id'] ?? json['notificationCode'] ?? '').toString(),
      title: (json['title'] ?? json['message'] ?? '').toString(),
      body: (json['body'] ?? json['description'])?.toString(),
      subjectName:
          (json['subjectName'] ?? json['personName'] ?? json['name'])
              ?.toString(),
      category: NotificationCategory.fromApi(
        (json['category'] ?? json['type'])?.toString(),
      ),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? json['createdOn'] ?? '')
                  .toString()) ??
              DateTime.now(),
      isRead: _asBool(json['isRead'] ?? json['read']),
      data: data,
    );
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final normalized = (value ?? '').toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final s = (v ?? '').trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}
