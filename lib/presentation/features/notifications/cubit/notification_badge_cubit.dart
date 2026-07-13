import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/notifications/usecases/get_notification_unread_counts_usecase.dart';

part 'notification_badge_state.dart';

/// Holds the unread notification count for the app-bar bell badge, mirroring the
/// messaging [UnreadBadgeCubit]. A shared app-session singleton: it's provided
/// at the app root and reloaded whenever a [GlobalScaffold] mounts (login,
/// navigation, school-switch) and after the notification center is visited.
class NotificationBadgeCubit extends Cubit<NotificationBadgeState> {
  NotificationBadgeCubit({
    required GetNotificationUnreadCountsUseCase getUnreadCounts,
  })  : _getUnreadCounts = getUnreadCounts,
        super(const NotificationBadgeState.initial());

  final GetNotificationUnreadCountsUseCase _getUnreadCounts;

  /// Fetches the authoritative unread / unclicked totals from
  /// `GET /api/v1/notification/inbox/unread-counts`. Failures are swallowed so a
  /// transient error (or a not-yet-logged-in state) never flashes the badge off.
  Future<void> load() async {
    try {
      final counts = await _getUnreadCounts();
      if (isClosed) return;
      emit(
        state.copyWith(
          unreadCount: counts.unread,
          unclickedCount: counts.unclicked,
        ),
      );
    } catch (_) {
      // Keep the previous counts on failure.
    }
  }

  Future<void> refresh() => load();

  /// Optimistically clears the badge (e.g. after the user opens the center and
  /// marks everything read); the next [load] reconciles with the server.
  void clear() {
    if (isClosed) return;
    emit(const NotificationBadgeState.initial());
  }
}
