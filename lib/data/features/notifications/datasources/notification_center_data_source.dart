import '../../../../domain/features/notifications/entities/notification_category.dart';
import '../models/app_notification_model.dart';

/// Seam over the notification-center backend.
///
/// The presentation/domain layers depend on this abstraction, not the concrete
/// data source — so the in-memory [MockNotificationCenterDataSource] used today
/// can be replaced by a REST-backed implementation (calling the eventual
/// `/api/v1/notifications` endpoints via `ApiClient`) without touching anything
/// above the repository.
abstract class NotificationCenterDataSource {
  Future<List<AppNotificationModel>> fetchNotifications();
  Future<List<AppNotificationModel>> markAsRead(String id);
  Future<List<AppNotificationModel>> markAllAsRead();
}

/// In-memory mock data source with realistic seed data, mirroring the design.
///
/// Read-state mutations are kept in [_items] so the UI behaves like a real
/// backend within a session (mark-one / mark-all flip the unread dots). A short
/// artificial delay is added so loading/refresh states are exercised.
class MockNotificationCenterDataSource implements NotificationCenterDataSource {
  MockNotificationCenterDataSource() {
    _items = _seed();
  }

  late List<AppNotificationModel> _items;

  static const Duration _latency = Duration(milliseconds: 600);

  @override
  Future<List<AppNotificationModel>> fetchNotifications() async {
    await Future<void>.delayed(_latency);
    return _sortedCopy();
  }

  @override
  Future<List<AppNotificationModel>> markAsRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _items = _items
        .map((n) => n.id == id ? _copyRead(n, true) : n)
        .toList();
    return _sortedCopy();
  }

  @override
  Future<List<AppNotificationModel>> markAllAsRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _items = _items.map((n) => _copyRead(n, true)).toList();
    return _sortedCopy();
  }

  List<AppNotificationModel> _sortedCopy() {
    final copy = List<AppNotificationModel>.from(_items);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  AppNotificationModel _copyRead(AppNotificationModel n, bool isRead) {
    return AppNotificationModel(
      id: n.id,
      title: n.title,
      body: n.body,
      subjectName: n.subjectName,
      category: n.category,
      createdAt: n.createdAt,
      isRead: isRead,
      data: n.data,
    );
  }

  List<AppNotificationModel> _seed() {
    final now = DateTime.now();
    AppNotificationModel item({
      required String id,
      required String title,
      required String subjectName,
      required NotificationCategory category,
      required Duration ago,
      bool isRead = false,
      Map<String, String> data = const <String, String>{},
    }) {
      return AppNotificationModel(
        id: id,
        title: title,
        subjectName: subjectName,
        category: category,
        createdAt: now.subtract(ago),
        isRead: isRead,
        data: data,
      );
    }

    return <AppNotificationModel>[
      // ── Task deep-link probes (MOCK ONLY) ───────────────────────────────
      // There is no notification-center endpoint yet, so these stand in for
      // real TASK_* items. They carry the same `data` map the FCM push sends,
      // which is exactly what NotificationRouteResolver reads — so tapping
      // them exercises the real in-app routing path.
      //
      // TODO(notifications): drop this block once a REST-backed data source
      // replaces this mock.
      //
      // Swap `taskCode` for one that exists in your active school (open any
      // task from the calendar and copy the code) or the detail screen will
      // correctly report "Task not found".
      item(
        id: 'task-assigned',
        title: 'You have been assigned a new task: Restock the first-aid kit',
        subjectName: 'Restock the first-aid kit',
        category: NotificationCategory.staff,
        ago: const Duration(minutes: 5),
        data: const {
          'action': 'TASK_ASSIGNED',
          'type': 'TASK',
          'taskCode': 'TSK_REPLACE_ME',
          'taskTitle': 'Restock the first-aid kit',
        },
      ),
      item(
        id: 'task-deleted',
        title: 'The task Restock the first-aid kit has been deleted',
        subjectName: 'Restock the first-aid kit',
        category: NotificationCategory.staff,
        ago: const Duration(minutes: 8),
        data: const {
          'action': 'TASK_DELETED',
          'type': 'TASK',
          'taskCode': 'TSK_REPLACE_ME',
          'taskTitle': 'Restock the first-aid kit',
        },
      ),
      item(
        id: 'n1',
        title: 'Classroom movement for Parker Long is overdue',
        subjectName: 'Parker Long',
        category: NotificationCategory.availability,
        ago: const Duration(hours: 21),
      ),
      item(
        id: 'n2',
        title: 'Schedule is not added for the staff Mukul Phogat',
        subjectName: 'Mukul Phogat',
        category: NotificationCategory.staff,
        ago: const Duration(hours: 21, minutes: 10),
      ),
      item(
        id: 'n3',
        title: 'Parent/Guardian is not added for the student Keri Adams',
        subjectName: 'Keri Adams',
        category: NotificationCategory.student,
        ago: const Duration(hours: 21, minutes: 20),
      ),
      item(
        id: 'n4',
        title: 'Schedule is not added for the student Anabella Case',
        subjectName: 'Anabella Case',
        category: NotificationCategory.student,
        ago: const Duration(hours: 21, minutes: 30),
      ),
      item(
        id: 'n5',
        title: 'Schedule is not added for the student Parker Long',
        subjectName: 'Parker Long',
        category: NotificationCategory.student,
        ago: const Duration(hours: 22),
      ),
      item(
        id: 'n6',
        title: 'Availability for staff Diana Prince is overdue',
        subjectName: 'Diana Prince',
        category: NotificationCategory.availability,
        ago: const Duration(days: 1, hours: 2),
        isRead: true,
      ),
      item(
        id: 'n7',
        title: 'Schedule is not added for the staff Bruce Wayne',
        subjectName: 'Bruce Wayne',
        category: NotificationCategory.staff,
        ago: const Duration(days: 1, hours: 5),
        isRead: true,
      ),
      item(
        id: 'n8',
        title: 'Parent/Guardian is not added for the student Clark Kent',
        subjectName: 'Clark Kent',
        category: NotificationCategory.student,
        ago: const Duration(days: 2),
        isRead: true,
      ),
    ];
  }
}
