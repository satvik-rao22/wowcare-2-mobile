import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/presentation/features/notifications/view_model/notification_badge_cubit.dart';

import '../../../../core/utils/core_utils.dart';
import '../../../../domain/features/notifications/entities/app_notification.dart';
import '../../../../domain/features/notifications/usecases/get_notification_unread_counts_usecase.dart';
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
    required GetNotificationUnreadCountsUseCase getUnreadCountsUseCase,
  }) : _getNotifications = getNotificationsUseCase,
       _markRead = markNotificationReadUseCase,
       _markAllRead = markAllNotificationsReadUseCase,
       _getUnreadCounts = getUnreadCountsUseCase,
       super(const NotificationCenterState.initial());

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final GetNotificationUnreadCountsUseCase _getUnreadCounts;

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
      final result = await _getNotifications(
        page: 0,
        size: _pageSize,
        module: state.moduleFilter,
        onlyUnread: state.onlyUnread,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          items: result.items,
          page: 0,
          hasMore: result.hasMore,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
        ),
      );
      await _refreshUnreadCount();
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Best-effort refresh of the authoritative unread total (bell badge +
  /// mark-all gate). Failures are swallowed — the loaded-item count is the
  /// fallback, so a count hiccup never blocks the list.
  Future<void> _refreshUnreadCount() async {
    try {
      final counts = await _getUnreadCounts();
      if (isClosed) return;
      emit(state.copyWith(serverUnreadCount: counts.unread));
    } catch (_) {
      // Non-fatal: keep the loaded-item fallback.
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
      final result = await _getNotifications(
        page: nextPage,
        size: _pageSize,
        module: state.moduleFilter,
        onlyUnread: state.onlyUnread,
      );
      if (isClosed) return;
      // De-dupe defensively in case a page boundary overlaps.
      final existingIds = state.items.map((n) => n.id).toSet();
      final merged = <AppNotification>[
        ...state.items,
        ...result.items.where((n) => !existingIds.contains(n.id)),
      ];
      emit(
        state.copyWith(
          items: merged,
          page: nextPage,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Sets the module (category) filter and refetches from the server.
  /// `null`/empty selects "All". No-op when unchanged.
  Future<void> setModuleFilter(String? module) async {
    final next = (module == null || module.trim().isEmpty)
        ? null
        : module.trim();
    if (next == state.moduleFilter) return;
    emit(
      state.copyWith(
        moduleFilter: next,
        clearModuleFilter: next == null,
        isLoading: true,
        errorMessage: null,
      ),
    );
    await _fetchFirstPage();
  }

  /// Toggles the unread-only filter and refetches from the server.
  Future<void> setOnlyUnread(bool value) async {
    if (value == state.onlyUnread) return;
    emit(
      state.copyWith(onlyUnread: value, isLoading: true, errorMessage: null),
    );
    await _fetchFirstPage();
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
      // Keep the authoritative unread total in step with the item we just read.
      final c = state.serverUnreadCount;
      emit(
        state.copyWith(
          isMutating: false,
          serverUnreadCount: c == null ? null : (c > 0 ? c - 1 : 0),
        ),
      );
      // Keep the app-bar bell badge in step with the read action.
      try {
        serviceLocator<NotificationBadgeCubit>().markOneReadLocally();
      } catch (_) {}
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      // Roll back the optimistic update on failure.
      emit(
        state.copyWith(
          items: previous,
          isMutating: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
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
      emit(state.copyWith(isMutating: false, serverUnreadCount: 0));
      // Keep the app-bar bell badge in step with mark-all-read.
      try {
        serviceLocator<NotificationBadgeCubit>().markAllReadLocally();
      } catch (_) {}
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(
        state.copyWith(
          items: previous,
          isMutating: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }
}
