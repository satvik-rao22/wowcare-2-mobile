part of 'notification_center_cubit.dart';

/// View-model state for the notification center.
///
/// [items] is the full, unfiltered list from the repository (source of truth).
/// [categoryFilter] and [onlyUnread] are pure view filters applied by
/// [visibleItems]; the cubit never throws data away when filtering, so toggling
/// a filter is instant and reversible without a refetch.
class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
    required this.isMutating,
    required this.categoryFilter,
    required this.onlyUnread,
    required this.errorMessage,
  });

  const NotificationCenterState.initial()
      : items = const [],
        isLoading = true,
        isRefreshing = false,
        isMutating = false,
        categoryFilter = null,
        onlyUnread = false,
        errorMessage = null;

  final List<AppNotification> items;
  final bool isLoading;
  final bool isRefreshing;

  /// True while a mark-read / mark-all-read request is in flight.
  final bool isMutating;

  /// `null` means "All". Otherwise restrict to a single category.
  final NotificationCategory? categoryFilter;
  final bool onlyUnread;
  final String? errorMessage;

  /// The list after applying the category + unread view filters.
  List<AppNotification> get visibleItems {
    return items.where((n) {
      if (categoryFilter != null && n.category != categoryFilter) return false;
      if (onlyUnread && n.isRead) return false;
      return true;
    }).toList();
  }

  int get unreadCount => items.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  NotificationCenterState copyWith({
    List<AppNotification>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isMutating,
    NotificationCategory? categoryFilter,
    bool clearCategoryFilter = false,
    bool? onlyUnread,
    String? errorMessage,
  }) {
    return NotificationCenterState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMutating: isMutating ?? this.isMutating,
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      onlyUnread: onlyUnread ?? this.onlyUnread,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        isLoading,
        isRefreshing,
        isMutating,
        categoryFilter,
        onlyUnread,
        errorMessage,
      ];
}
