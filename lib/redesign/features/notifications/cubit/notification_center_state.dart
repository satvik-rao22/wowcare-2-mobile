part of 'notification_center_cubit.dart';

/// The four things the inbox can be.
///
/// An inbox with nothing in it is [ready] with an empty list rather than a
/// state of its own, because "nothing has ever arrived" and "nothing under
/// that filter" are the same fetch with different answers, and the screen
/// says which by looking at the filter.
enum NotificationCenterStatus {
  loading,
  ready,

  /// The refetch failed but the rows already on screen are still worth
  /// reading. The banner says they are not live.
  cached,

  /// The fetch failed with nothing to fall back on.
  failed,
}

@immutable
class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    required this.persona,
    this.status = NotificationCenterStatus.loading,
    this.items = const <NotificationItem>[],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isWorking = false,
    this.filter = NotificationFilter.all,
    this.onlyUnread = false,
    this.unreadCount = 0,
    this.asOf,
    this.hasArrived = false,
  });

  /// Who is reading. It decides which chips are offered, and the server has
  /// already decided what the feed carries.
  final Persona persona;

  final NotificationCenterStatus status;
  final List<NotificationItem> items;

  /// The zero-based index of the last page loaded.
  final int page;

  final bool hasMore;
  final bool isLoadingMore;

  /// A mark-read or mark-all is in flight.
  final bool isWorking;

  final NotificationFilter filter;
  final bool onlyUnread;

  /// Unread across every page, not just the rows loaded. This is the number
  /// the bell carries.
  final int unreadCount;

  /// The school's clock when the page was answered. Null until the first
  /// answer, and every relative time is measured against it.
  final DateTime? asOf;

  /// A push landed while this screen was open.
  final bool hasArrived;

  bool get isLoading => status == NotificationCenterStatus.loading;
  bool get isFailed => status == NotificationCenterStatus.failed;
  bool get isCached => status == NotificationCenterStatus.cached;

  bool get hasUnread => unreadCount > 0;

  /// Nothing to draw. Whether that is an empty inbox or an empty answer is
  /// [isNarrowed]'s question.
  bool get isEmpty => items.isEmpty;

  /// The list has been narrowed by a chip or by the unread switch.
  bool get isNarrowed => !filter.isAll || onlyUnread;

  /// The chips this persona is offered (12e).
  List<NotificationFilter> get chips => NotificationFilter.forPersona(persona);

  /// The clock every row is aged against: the school's, once it has answered.
  DateTime get clock => asOf ?? DateTime.now();

  /// The rows under their day bands, in the order the inbox returned them.
  List<NotificationGroup> get groups {
    final now = clock;
    final groups = <NotificationGroup>[];
    for (final item in items) {
      final day = NotificationsFormats.dayOf(item.createdAt, now);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.items.add(item);
      } else {
        groups.add(
          NotificationGroup(day: day, items: <NotificationItem>[item]),
        );
      }
    }
    return groups;
  }

  NotificationCenterState copyWith({
    NotificationCenterStatus? status,
    List<NotificationItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isWorking,
    NotificationFilter? filter,
    bool? onlyUnread,
    int? unreadCount,
    DateTime? asOf,
    bool? hasArrived,
  }) => NotificationCenterState(
    persona: persona,
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isWorking: isWorking ?? this.isWorking,
    filter: filter ?? this.filter,
    onlyUnread: onlyUnread ?? this.onlyUnread,
    unreadCount: unreadCount ?? this.unreadCount,
    asOf: asOf ?? this.asOf,
    hasArrived: hasArrived ?? this.hasArrived,
  );

  @override
  List<Object?> get props => [
    persona,
    status,
    items,
    page,
    hasMore,
    isLoadingMore,
    isWorking,
    filter,
    onlyUnread,
    unreadCount,
    asOf,
    hasArrived,
  ];
}
