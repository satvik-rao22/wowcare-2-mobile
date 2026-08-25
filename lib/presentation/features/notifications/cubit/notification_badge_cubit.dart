import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/notifications/realtime/notification_realtime_data_source.dart';

part 'notification_badge_state.dart';

/// Holds the unread notification count for the app-bar bell badge, mirroring the
/// messaging [UnreadBadgeCubit]. The COUNT is always derived directly from the
/// live Firestore collection `userNotifications/{userCode}/notifications` —
/// never from REST (see [NotificationRealtimeDataSource]'s own doc).
///
/// Unlike messaging's badge, this listener doesn't need re-scoping on a
/// school/persona switch ([SchoolSwitchEvents]): it's keyed by userCode only,
/// and the live snapshot already reflects the account's actual notifications
/// regardless of which persona is currently active — the old REST count was
/// the one that needed a re-read there (server-scoped via `x-role`/
/// `x-school-code` headers), and that's gone now.
///
/// A shared app-session singleton: provided at the app root and started once per
/// [GlobalScaffold] mount via [startWatching].
class NotificationBadgeCubit extends Cubit<NotificationBadgeState> {
  NotificationBadgeCubit({
    required NotificationRealtimeDataSource realtime,
    required StorageService storage,
  }) : _realtime = realtime,
       _storage = storage,
       super(const NotificationBadgeState.initial());

  final NotificationRealtimeDataSource _realtime;
  final StorageService _storage;

  StreamSubscription<int>? _firestoreSub;
  String _watchedUserCode = '';

  /// No REST re-fetch to trigger any more — Firestore is the only source and
  /// updates live on its own. Kept as a no-op-unless-not-yet-watching entry
  /// point so existing callers (FCM push handlers, background-tap) that used
  /// to force a REST re-read still have something safe to call; it just
  /// ensures the live subscription is attached.
  Future<void> refresh() => startWatching();

  /// Same as [refresh] — kept for existing call sites. There's no longer a
  /// "re-read once more shortly after" retry to do: the live listener already
  /// self-corrects on the backend's own timeline, with no single read to be
  /// stale against.
  Future<void> refreshWithRetry() => startWatching();

  /// Attaches the live Firestore listener so the badge updates as
  /// notifications arrive / are read. Idempotent per user: safe to call on
  /// every [GlobalScaffold] mount (login, navigation, school switch). The
  /// notifications collection is keyed by userCode only (not school), so the
  /// subscription is reused across school switches.
  Future<void> startWatching() async {
    final userCode = (await _storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    if (userCode.isEmpty) {
      AppLogger.d('[NotifBadge] startWatching skipped — no userCode yet');
      return;
    }
    if (_watchedUserCode == userCode && _firestoreSub != null) return;

    AppLogger.d('[NotifBadge] startWatching user=$userCode');
    _watchedUserCode = userCode;
    await _firestoreSub?.cancel();
    _firestoreSub = _realtime.watchUnreadCount(userCode: userCode).listen((
      count,
    ) {
      if (isClosed) return;
      AppLogger.d('[NotifBadge] Firestore unread=$count');
      emit(state.copyWith(unreadCount: count));
    }, onError: (_) {});
  }

  /// Applies a read-state change the caller already knows is correct (the
  /// mark-read/mark-all-read request just succeeded), so the bell updates in
  /// the same frame instead of waiting on the Firestore round-trip. The next
  /// live snapshot (once the backend's write lands) reconciles on top of
  /// this automatically.
  void _applyLocalReadDelta(int newUnreadCount) {
    if (isClosed) return;
    emit(state.copyWith(unreadCount: newUnreadCount));
  }

  /// Call right after a single notification is successfully marked read.
  void markOneReadLocally() {
    final next = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
    _applyLocalReadDelta(next);
  }

  /// Call right after "mark all as read" succeeds.
  void markAllReadLocally() => _applyLocalReadDelta(0);

  /// Optimistically clears the badge and tears down the live listener (logout).
  void clear() {
    _firestoreSub?.cancel();
    _firestoreSub = null;
    _watchedUserCode = '';
    if (isClosed) return;
    emit(const NotificationBadgeState.initial());
  }

  @override
  Future<void> close() {
    _firestoreSub?.cancel();
    return super.close();
  }
}
