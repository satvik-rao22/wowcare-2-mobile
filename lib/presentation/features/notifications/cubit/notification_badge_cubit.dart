import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/notifications/realtime/notification_realtime_data_source.dart';
import 'package:wowcare/domain/features/notifications/usecases/get_notification_unread_counts_usecase.dart';

part 'notification_badge_state.dart';

/// Holds the unread notification count for the app-bar bell badge, mirroring the
/// messaging [UnreadBadgeCubit]. The COUNT is always read from REST
/// (`/notification/inbox/unread-counts`) — per the notifications spec it is never
/// derived from Firestore. Live updates come from a Firestore listener on
/// `userNotifications/{userCode}/notifications` that only triggers a REST
/// refresh; the count itself stays authoritative from REST.
///
/// A shared app-session singleton: provided at the app root and started once per
/// [GlobalScaffold] mount via [startWatching].
class NotificationBadgeCubit extends Cubit<NotificationBadgeState> {
  NotificationBadgeCubit({
    required GetNotificationUnreadCountsUseCase getUnreadCounts,
    required NotificationRealtimeDataSource realtime,
    required StorageService storage,
  })  : _getUnreadCounts = getUnreadCounts,
        _realtime = realtime,
        _storage = storage,
        super(const NotificationBadgeState.initial());

  final GetNotificationUnreadCountsUseCase _getUnreadCounts;
  final NotificationRealtimeDataSource _realtime;
  final StorageService _storage;

  StreamSubscription<void>? _firestoreSub;
  String _watchedUserCode = '';
  Timer? _debounce;

  /// Fetches the authoritative unread / unclicked totals from
  /// `GET /api/v1/notification/inbox/unread-counts`. Failures are swallowed so a
  /// transient error (or a not-yet-logged-in state) never flashes the badge off.
  Future<void> load() async {
    try {
      final counts = await _getUnreadCounts();
      if (isClosed) return;
      AppLogger.d(
        '[NotifBadge] REST count → unread=${counts.unread} '
        'unclicked=${counts.unclicked}',
      );
      emit(
        state.copyWith(
          unreadCount: counts.unread,
          unclickedCount: counts.unclicked,
        ),
      );
    } catch (e) {
      AppLogger.d('[NotifBadge] REST count fetch failed: $e');
      // Keep the previous counts on failure.
    }
  }

  Future<void> refresh() => load();

  /// Does an immediate REST load and attaches the live Firestore listener so the
  /// badge updates as notifications arrive / are read. Idempotent per user: safe
  /// to call on every [GlobalScaffold] mount (login, navigation, school switch).
  /// The notifications collection is keyed by userCode only (not school), so the
  /// subscription is reused across school switches.
  Future<void> startWatching() async {
    // Refresh the count immediately so the badge is correct before the first
    // snapshot lands (pure latency optimisation).
    await load();

    final userCode =
        (await _storage.getString(StorageKeys.userCode) ?? '').trim();
    if (userCode.isEmpty) {
      AppLogger.d('[NotifBadge] startWatching skipped — no userCode yet');
      return;
    }
    if (_watchedUserCode == userCode && _firestoreSub != null) return;

    AppLogger.d('[NotifBadge] startWatching user=$userCode');
    _watchedUserCode = userCode;
    await _firestoreSub?.cancel();
    _firestoreSub = _realtime
        .watchNotificationChanges(userCode: userCode)
        .listen((_) => _scheduleRefresh(), onError: (_) {});
  }

  /// Coalesces bursts of Firestore changes into a single REST refresh.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (isClosed) return;
      load();
    });
  }

  /// Optimistically clears the badge and tears down the live listener (logout).
  void clear() {
    _debounce?.cancel();
    _firestoreSub?.cancel();
    _firestoreSub = null;
    _watchedUserCode = '';
    if (isClosed) return;
    emit(const NotificationBadgeState.initial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _firestoreSub?.cancel();
    return super.close();
  }
}
