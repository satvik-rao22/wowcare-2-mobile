part of 'notification_center_cubit.dart';

/// View-model state for the notification center.
///
/// [items] is the current page-set from the repository. [moduleFilter] and
/// [onlyUnread] are applied **server-side** (they map to the `module` /
/// `onlyShowUnread` query params), so changing either triggers a refetch rather
/// than a local filter.
class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
    required this.isMutating,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    required this.moduleFilter,
    required this.onlyUnread,
    required this.errorMessage,
    this.serverUnreadCount,
  });

  const NotificationCenterState.initial()
      : items = const [],
        isLoading = true,
        isRefreshing = false,
        isMutating = false,
        isLoadingMore = false,
        hasMore = false,
        page = 0,
        moduleFilter = null,
        onlyUnread = false,
        errorMessage = null,
        serverUnreadCount = null;

  final List<AppNotification> items;
  final bool isLoading;
  final bool isRefreshing;

  /// True while a mark-read / mark-all-read request is in flight.
  final bool isMutating;

  /// True while the next page is being fetched (infinite scroll).
  final bool isLoadingMore;

  /// Whether the backend has more pages after [page].
  final bool hasMore;

  /// Zero-based index of the last loaded page.
  final int page;

  /// Active module (category) filter — the raw backend module string
  /// (e.g. `ATTENDANCE`). `null` means "All". Sent as the `module` query param.
  final String? moduleFilter;

  /// Restrict to unread. Sent as the `onlyShowUnread` query param.
  final bool onlyUnread;
  final String? errorMessage;

  /// Authoritative unread total from `GET /notification/inbox/unread-counts`
  /// (across all pages). Null until the count has been fetched, in which case
  /// the loaded-item count is used as a fallback.
  final int? serverUnreadCount;

  /// The list to render. Filtering is server-side, so this is just [items].
  List<AppNotification> get visibleItems => items;

  /// Distinct modules present in the loaded items — a fallback source for the
  /// filter dropdown until the modules list endpoint is wired.
  List<String> get availableModules {
    final set = <String>{};
    for (final n in items) {
      final m = (n.data['module'] ?? '').trim();
      if (m.isNotEmpty) set.add(m);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Unread among the currently-loaded items.
  int get loadedUnreadCount => items.where((n) => !n.isRead).length;

  /// Authoritative unread total: the server count when known (spans all pages),
  /// otherwise the loaded-item count.
  int get unreadCount => serverUnreadCount ?? loadedUnreadCount;

  bool get hasUnread => unreadCount > 0;

  NotificationCenterState copyWith({
    List<AppNotification>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isMutating,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? moduleFilter,
    bool clearModuleFilter = false,
    bool? onlyUnread,
    String? errorMessage,
    int? serverUnreadCount,
  }) {
    return NotificationCenterState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMutating: isMutating ?? this.isMutating,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      moduleFilter:
          clearModuleFilter ? null : (moduleFilter ?? this.moduleFilter),
      onlyUnread: onlyUnread ?? this.onlyUnread,
      errorMessage: errorMessage,
      serverUnreadCount: serverUnreadCount ?? this.serverUnreadCount,
    );
  }

  @override
  List<Object?> get props => [
        items,
        isLoading,
        isRefreshing,
        isMutating,
        isLoadingMore,
        hasMore,
        page,
        moduleFilter,
        onlyUnread,
        errorMessage,
        serverUnreadCount,
      ];
}
