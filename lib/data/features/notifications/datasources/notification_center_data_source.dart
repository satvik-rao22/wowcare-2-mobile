import '../../../../domain/features/notifications/entities/notification_category.dart';
import '../models/app_notification_model.dart';

/// Seam over the notification-center backend.
///
/// The presentation/domain layers depend on this abstraction, not the concrete
/// data source — so the in-memory [MockNotificationCenterDataSource] used today
/// can be replaced by a REST-backed implementation (calling the eventual
/// `/api/v1/notifications` endpoints via `ApiClient`) without touching anything
/// above the repository.
/// One page of notification-center items plus whether more pages exist.
typedef NotificationCenterPage = ({
  List<AppNotificationModel> items,
  bool hasMore,
});

abstract class NotificationCenterDataSource {
  /// Fetches one page (newest first). [page] is zero-based. [module] filters by
  /// the notification's top-level module (null = all); [onlyUnread] restricts to
  /// unread. Both are applied server-side.
  Future<NotificationCenterPage> fetchNotifications({
    int page,
    int size,
    String? module,
    bool onlyUnread,
  });

  /// Marks a single notification read on the backend.
  Future<void> markAsRead(String id);

  /// Marks every notification read on the backend.
  Future<void> markAllAsRead();

  /// Authoritative unread / unclicked totals across all pages (bell badge +
  /// mark-all gating), independent of what's currently loaded.
  Future<({int unread, int unclicked})> getUnreadCounts();
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
  Future<NotificationCenterPage> fetchNotifications({
    int page = 0,
    int size = 10,
    String? module,
    bool onlyUnread = false,
  }) async {
    await Future<void>.delayed(_latency);
    var sorted = _sortedCopy();
    if (module != null && module.trim().isNotEmpty) {
      final m = module.trim().toUpperCase();
      sorted = sorted
          .where((n) => (n.data['module'] ?? '').toUpperCase() == m)
          .toList();
    }
    if (onlyUnread) {
      sorted = sorted.where((n) => !n.isRead).toList();
    }
    final start = page * size;
    if (start >= sorted.length) {
      return (items: const <AppNotificationModel>[], hasMore: false);
    }
    final end = (start + size).clamp(0, sorted.length);
    return (items: sorted.sublist(start, end), hasMore: end < sorted.length);
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _items =
        _items.map((n) => n.id == id ? _copyRead(n, true) : n).toList();
  }

  @override
  Future<void> markAllAsRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _items = _items.map((n) => _copyRead(n, true)).toList();
  }

  @override
  Future<({int unread, int unclicked})> getUnreadCounts() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final unread = _items.where((n) => !n.isRead).length;
    return (unread: unread, unclicked: unread);
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
    }) {
      return AppNotificationModel(
        id: id,
        title: title,
        subjectName: subjectName,
        category: category,
        createdAt: now.subtract(ago),
        isRead: isRead,
      );
    }

    return <AppNotificationModel>[
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
