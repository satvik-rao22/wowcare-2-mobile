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
}
