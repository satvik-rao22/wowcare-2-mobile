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
  factory AppNotificationModel.fromDeliveryLogJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    final meta = <String, String>{};
    if (metadata is Map) {
      metadata.forEach((key, value) {
        meta['$key'] = value?.toString() ?? '';
      });
    }

    final title = _firstNonEmpty([
      meta['title'],
      meta['message'],
      meta['notificationTitle'],
      json['errorMessage']?.toString(),
    ]);

    final body = _firstNonEmpty([
      meta['body'],
      meta['description'],
      meta['notificationBody'],
    ]);

    final subjectName = _firstNonEmpty([
      meta['subjectName'],
      meta['personName'],
      meta['studentName'],
      meta['staffName'],
      meta['name'],
    ]);

    final categoryRaw = _firstNonEmpty([
      meta['category'],
      meta['type'],
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
      data: meta,
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
