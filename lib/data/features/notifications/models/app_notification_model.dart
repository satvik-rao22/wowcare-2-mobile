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

  /// Maps a `GET /api/v1/notification/inbox` item (the current backend
  /// contract). The schema is flat — `title`/`body` are top-level and the
  /// deep-link payload lives in `actionData`, with `metadata` carrying extra
  /// context (module, subject name, …).
  ///
  /// ```
  /// { code, title, body, definitionCode, status, readAt, createdAt,
  ///   organizationCode, schoolCode, role,
  ///   actionData: { action, module, studentCode, ... },
  ///   metadata:   { module, studentName, ... } }
  /// ```
  factory AppNotificationModel.fromInboxJson(Map<String, dynamic> json) {
    // Deep-link payload → string map; drives tap redirection through the same
    // NotificationRouteResolver the FCM-tap path uses.
    final data = <String, String>{};
    void mergeInto(dynamic src) {
      if (src is Map) {
        src.forEach((key, value) {
          if (value != null) data['$key'] = value.toString();
        });
      }
    }

    // Collect the deep-link codes (classroomCode, studentCode, staffCode, …).
    // They live in the nested `metadata.payload` and are duplicated flat in
    // `actionData`, which is authoritative — so merge payload first, actionData
    // last (it wins on collisions).
    final metadata = json['metadata'];
    final metaMap = metadata is Map ? metadata : const <dynamic, dynamic>{};
    mergeInto(metaMap['payload']);
    mergeInto(json['actionData']);

    // Module/category for the chip + `type`: prefer the top-level `module`
    // field, then `metadata.categoryCode` (e.g. CLASSROOM), then the nested
    // payload module. The nested one alone is unreliable (missing for some
    // events like CLASSROOM_RATIO_BREACHED), so it's only the last resort.
    final moduleValue = _firstNonEmpty([
      json['module']?.toString(),
      metaMap['categoryCode']?.toString(),
      data['module'],
    ]);
    if (moduleValue.isNotEmpty) data['module'] = moduleValue;

    // Ensure a routable `action` even when actionData omits it (e.g.
    // CLASSROOM_RATIO_BREACHED carries no `action`). Fall back to the event
    // type, else the definitionCode with its `_DEF` suffix stripped
    // (STUDENT_SIGN_IN_DEF → STUDENT_SIGN_IN). Tap redirection keys off this.
    if ((data['action'] ?? '').trim().isEmpty) {
      final eventType = metaMap['eventTypeCode']?.toString().trim();
      final def = (json['definitionCode'] ?? '').toString().trim();
      final fromDef = def.toUpperCase().endsWith('_DEF')
          ? def.substring(0, def.length - 4)
          : def;
      final action =
          (eventType != null && eventType.isNotEmpty) ? eventType : fromDef;
      if (action.isNotEmpty) data['action'] = action;
    }

    // Carry org/school/role so a multi-school tap can switch school before
    // routing (mirrors the FCM `data` map).
    for (final key in const ['organizationCode', 'schoolCode', 'role']) {
      final v = json[key];
      if (v != null && '$v'.trim().isNotEmpty) {
        data.putIfAbsent(key, () => '$v');
      }
    }

    // Expose the inbox item's own timestamp as a LAST-RESORT date for
    // date-targeted deep links. Older ACTIVITY notifications predate the
    // backend's `activityMarkedDate` field and carry no date whatsoever, so a
    // tap had nothing to open the feed on and fell back to "today" — landing on
    // the wrong day with no card to highlight. The item is created when the
    // event is recorded, so `createdAt` is a close proxy. `putIfAbsent` keeps a
    // real payload date authoritative whenever one exists.
    final createdAtRaw = (json['createdAt'] ?? '').toString().trim();
    if (createdAtRaw.isNotEmpty) {
      data.putIfAbsent('notificationCreatedAt', () => createdAtRaw);
    }

    final subjectName = _firstNonEmpty([
      data['studentName'],
      data['staffName'],
      data['subjectName'],
      data['personName'],
      data['name'],
    ]);

    // Category: prefer an explicit module/category in the payload, else derive
    // it from the definitionCode (e.g. STAFF_PHYSICAL_DUE_DEF → STAFF).
    final categoryRaw = _firstNonEmpty([
      data['module'],
      data['category'],
      json['definitionCode']?.toString(),
    ]);

    final status = (json['status'] ?? '').toString().trim().toUpperCase();
    final readAt = json['readAt'];
    final isRead = (status.isNotEmpty && status != 'UNREAD') ||
        (readAt != null && readAt.toString().trim().isNotEmpty);

    final title = (json['title'] ?? '').toString().trim();
    final body = (json['body'] ?? '').toString().trim();

    return AppNotificationModel(
      id: (json['code'] ?? '').toString(),
      title: title.isEmpty ? 'Notification' : title,
      body: body.isEmpty ? null : body,
      subjectName: subjectName.isEmpty ? null : subjectName,
      category: NotificationCategory.fromApi(categoryRaw),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      isRead: isRead,
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
