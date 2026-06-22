import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/util/core_utils.dart';
import '../../../../domain/features/notifications/entities/app_notification.dart';
import '../../../../domain/features/notifications/entities/notification_category.dart';
import '../../../../domain/features/notifications/usecases/get_notifications_usecase.dart';
import '../../../../domain/features/notifications/usecases/mark_all_notifications_read_usecase.dart';
import '../../../../domain/features/notifications/usecases/mark_notification_read_usecase.dart';

part 'notification_center_state.dart';

/// ViewModel for the notification-center screen (the app-bar bell inbox).
///
/// Owns loading, the category + unread view filters, and read-state mutations.
/// It depends only on use cases (never on a data source or the router), keeping
/// it unit-testable and the View free of business logic.
class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
  })  : _getNotifications = getNotificationsUseCase,
        _markRead = markNotificationReadUseCase,
        _markAllRead = markAllNotificationsReadUseCase,
        super(const NotificationCenterState.initial());

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;

  /// Items per page (infinite scroll).
  static const int _pageSize = 10;

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await _fetchFirstPage();
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true, errorMessage: null));
    await _fetchFirstPage();
  }

  Future<void> _fetchFirstPage() async {
    try {
      final result = await _getNotifications(page: 0, size: _pageSize);
      if (isClosed) return;
      emit(state.copyWith(
        items: result.items,
        page: 0,
        hasMore: result.hasMore,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Loads the next page and appends it. No-op while already loading or when
  /// the backend has no more pages.
  Future<void> loadNextPage() async {
    if (state.isLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    final nextPage = state.page + 1;
    try {
      final result =
          await _getNotifications(page: nextPage, size: _pageSize);
      if (isClosed) return;
      // De-dupe defensively in case a page boundary overlaps.
      final existingIds = state.items.map((n) => n.id).toSet();
      final merged = <AppNotification>[
        ...state.items,
        ...result.items.where((n) => !existingIds.contains(n.id)),
      ];
      emit(state.copyWith(
        items: merged,
        page: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.toString()));
    }
  }

  /// `null` selects the "All" pseudo-category.
  void setCategoryFilter(NotificationCategory? category) {
    if (category == null) {
      emit(state.copyWith(clearCategoryFilter: true));
    } else {
      emit(state.copyWith(categoryFilter: category));
    }
  }

  void setOnlyUnread(bool value) {
    emit(state.copyWith(onlyUnread: value));
  }

  Future<void> markAsRead(String id) async {
    // No-op if the item is missing or already read, to avoid a needless request.
    final index = state.items.indexWhere((n) => n.id == id);
    if (index < 0 || state.items[index].isRead) return;

    // Optimistically flip read state locally so the loaded pages aren't lost to
    // a refetch (server-side pagination would otherwise truncate the list).
    final previous = state.items;
    final updated = [
      for (final n in previous) n.id == id ? n.copyWith(isRead: true) : n,
    ];
    emit(state.copyWith(items: updated, isMutating: true, errorMessage: null));
    try {
      await _markRead(id);
      if (isClosed) return;
      emit(state.copyWith(isMutating: false));
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      // Roll back the optimistic update on failure.
      emit(state.copyWith(
        items: previous,
        isMutating: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> markAllAsRead() async {
    if (!state.hasUnread) return;
    final previous = state.items;
    final updated = [for (final n in previous) n.copyWith(isRead: true)];
    emit(state.copyWith(items: updated, isMutating: true, errorMessage: null));
    try {
      await _markAllRead();
      if (isClosed) return;
      emit(state.copyWith(isMutating: false));
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(state.copyWith(
        items: previous,
        isMutating: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
