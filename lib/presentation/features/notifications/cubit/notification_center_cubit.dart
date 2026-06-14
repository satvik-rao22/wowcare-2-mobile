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

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await _fetch();
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true, errorMessage: null));
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final items = await _getNotifications();
      if (isClosed) return;
      emit(state.copyWith(
        items: items,
        isLoading: false,
        isRefreshing: false,
      ));
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      ));
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

    emit(state.copyWith(isMutating: true, errorMessage: null));
    try {
      final items = await _markRead(id);
      if (isClosed) return;
      emit(state.copyWith(items: items, isMutating: false));
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(state.copyWith(isMutating: false, errorMessage: e.toString()));
    }
  }

  Future<void> markAllAsRead() async {
    if (!state.hasUnread) return;
    emit(state.copyWith(isMutating: true, errorMessage: null));
    try {
      final items = await _markAllRead();
      if (isClosed) return;
      emit(state.copyWith(items: items, isMutating: false));
    } catch (e) {
      if (isClosed) return;
      CoreUtils.logApiError(e.toString());
      emit(state.copyWith(isMutating: false, errorMessage: e.toString()));
    }
  }
}
