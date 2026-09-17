import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/data/features/notifications/realtime/notification_realtime_data_source.dart';
import 'package:wowcare/domain/features/notifications/usecases/get_notification_unread_counts_usecase.dart';

part 'notification_badge_state.dart';

/// Holds the unread notification count for the app-bar bell badge.
///
/// REST (`GET /notification/inbox/unread-counts`, via
/// [GetNotificationUnreadCountsUseCase]) is the actual number source — the
/// Firestore collection `userNotifications/{userCode}/notifications` is only
/// used as a live "something changed, re-check" trigger (it doesn't need to
/// hold accurate per-notification data itself, and currently the backend
/// doesn't write anything into it — see [NotificationRealtimeDataSource]'s
/// own doc for the collection path). This was always the intended design
/// (see the comment in [GlobalScaffold]'s `initState` where this cubit is
/// started: "startWatching() does an immediate REST refresh AND attaches a
/// live Firestore listener that refreshes the REST count") — the REST half
/// had regressed out of this cubit at some point while that comment stayed.
///
/// Unlike messaging's badge, this listener doesn't need re-scoping on a
/// school/persona switch ([SchoolSwitchEvents]): it's keyed by userCode only,
/// and the REST endpoint's own `role`/`schoolCode` params are re-resolved
/// fresh on every fetch via [GetNotificationUnreadCountsUseCase].
///
/// A shared app-session singleton: provided at the app root and started once per
/// [GlobalScaffold] mount via [startWatching].
class NotificationBadgeCubit extends Cubit<NotificationBadgeState> {
  NotificationBadgeCubit({
    required NotificationRealtimeDataSource realtime,
    required GetNotificationUnreadCountsUseCase getUnreadCounts,
    required StorageService storage,
  }) : _realtime = realtime,
       _getUnreadCounts = getUnreadCounts,
       _storage = storage,
       super(const NotificationBadgeState.initial());

  final NotificationRealtimeDataSource _realtime;
  final GetNotificationUnreadCountsUseCase _getUnreadCounts;
  final StorageService _storage;

  StreamSubscription<int>? _firestoreSub;
  String _watchedUserCode = '';
  Timer? _debounce;
  Timer? _retry;

  /// Re-fetches the authoritative REST count. Safe to call as often as
  /// needed (e.g. after marking read, or when a push notification arrives).
  Future<void> refresh() => _refreshFromRest();

  /// Like [refresh], but for triggers that mean "a notification just
  /// arrived/changed on the server" (FCM push, background-tap). The backend's
  /// own read-model can lag a beat behind the push/Firestore write it's
  /// reacting to, so a single REST read right now can come back stale with no
  /// second chance to correct itself. Do the immediate read for the common
  /// case where it's already caught up, then re-read once more shortly after
  /// so a stale first read self-corrects instead of sticking until some
  /// unrelated screen happens to refresh the badge.
  Future<void> refreshWithRetry() async {
    await _refreshFromRest();
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 2), () {
      if (!isClosed) _refreshFromRest();
    });
  }

  Future<void> _refreshFromRest() async {
    try {
      final counts = await _getUnreadCounts();
      if (isClosed) return;
      AppLogger.d(
        '[NotifBadge] REST unread=${counts.unread} unclicked=${counts.unclicked}',
      );
      emit(
        state.copyWith(
          unreadCount: counts.unread,
          unclickedCount: counts.unclicked,
        ),
      );
    } catch (e) {
      AppLogger.d('[NotifBadge] REST unread-counts fetch failed: $e');
    }
  }

  /// Does an immediate REST refresh, then attaches the live Firestore
  /// listener so a change to `userNotifications/{userCode}/notifications`
  /// (once the backend writes to it) re-triggers a REST refresh rather than
  /// being trusted for its own doc count. Idempotent per user: safe to call
  /// on every [GlobalScaffold] mount (login, navigation, school switch). The
  /// notifications collection is keyed by userCode only (not school), so the
  /// subscription is reused across school switches.
  Future<void> startWatching() async {
    final userCode = (await _storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    if (userCode.isEmpty) {
      AppLogger.d('[NotifBadge] startWatching skipped — no userCode yet');
      return;
    }

    unawaited(_refreshFromRest());

    if (_watchedUserCode == userCode && _firestoreSub != null) return;

    AppLogger.d('[NotifBadge] startWatching user=$userCode');
    _watchedUserCode = userCode;
    await _firestoreSub?.cancel();
    _firestoreSub = _realtime.watchUnreadCount(userCode: userCode).listen((
      count,
    ) {
      AppLogger.d(
        '[NotifBadge] Firestore change signal (docCount=$count) — '
        're-checking REST',
      );
      _scheduleRefresh();
    }, onError: (_) {});
  }

  /// Coalesces bursts of Firestore changes into a single REST refresh.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!isClosed) _refreshFromRest();
    });
  }

  /// Applies a read-state change the caller already knows is correct (the
  /// mark-read/mark-all-read request just succeeded), so the bell updates in
  /// the same frame instead of waiting on a REST round-trip. A REST refresh
  /// right now would risk reading the backend's read-model before it has
  /// caught up with the write it's reacting to, stomping this correct value
  /// with a stale one — so push out any pending Firestore-triggered
  /// reconciliation rather than doing one immediately.
  void _applyLocalReadDelta(int newUnreadCount) {
    if (isClosed) return;
    emit(state.copyWith(unreadCount: newUnreadCount));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (!isClosed) _refreshFromRest();
    });
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
    _debounce?.cancel();
    _retry?.cancel();
    _firestoreSub?.cancel();
    _firestoreSub = null;
    _watchedUserCode = '';
    if (isClosed) return;
    emit(const NotificationBadgeState.initial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _retry?.cancel();
    _firestoreSub?.cancel();
    return super.close();
  }
}
