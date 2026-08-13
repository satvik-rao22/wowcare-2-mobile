import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:wowcare/core/util/school_switch_events.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_unread_aggregates_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_unread_count_for_type_usecase.dart';
import 'unread_badge_state.dart';

/// Manages aggregate unread counts for navigation badges (drawer + bottom nav).
///
/// Uses [WatchUnreadCountForTypeUseCase] which reads directly from Firestore
/// without the Isar merge pipeline — so it never duplicates or races with
/// [ConversationListCubit]'s stream.
///
/// This is a single app-session singleton (see di.dart) that survives school
/// and persona switches — those don't remount the `GlobalScaffold` that
/// originally called [startWatching] (branch screens are kept alive in an
/// `IndexedStack`), so this listens to [SchoolSwitchEvents.epoch] itself
/// (mirrors the web AppTopbar's `useEffect` re-running when
/// org/school/user change) and re-subscribes under the new scope — each
/// underlying Firestore stream re-resolves org/school/user fresh at
/// subscribe time (see `ConversationEntityRepositoryImpl.watchUnreadCountForType`),
/// so cancel-and-resubscribe is sufficient; no separate scope-key plumbing
/// needed here beyond knowing WHEN to do it.
class UnreadBadgeCubit extends Cubit<UnreadBadgeState> {
  UnreadBadgeCubit({
    required WatchUnreadCountForTypeUseCase watchUnreadCountForTypeUseCase,
    required GetUnreadAggregatesUseCase getUnreadAggregatesUseCase,
  }) : _watchUnreadCountForTypeUseCase = watchUnreadCountForTypeUseCase,
       _getUnreadAggregatesUseCase = getUnreadAggregatesUseCase,
       super(const UnreadBadgeState.initial()) {
    SchoolSwitchEvents.epoch.addListener(_handleSchoolSwitch);
  }

  final WatchUnreadCountForTypeUseCase _watchUnreadCountForTypeUseCase;
  final GetUnreadAggregatesUseCase _getUnreadAggregatesUseCase;

  int _lastHandledEpoch = SchoolSwitchEvents.epoch.value;

  final Map<String, StreamSubscription<int>> _subscriptions = {};
  final Map<String, int> _counts = {};

  /// Conversation-type keys whose live Firestore stream has delivered at least
  /// once. Firestore's per-user inbox `unreadCount` is the source of truth (it
  /// reflects reactions too), whereas the REST unread-summary counts only unread
  /// MESSAGES. Once Firestore is live for a type we must not let a REST refetch
  /// clobber that type's count back down — otherwise reaction-driven unread
  /// disappears. This matches the web AppTopbar, which is Firestore-authoritative.
  final Set<String> _firestoreDelivered = {};

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    SchoolSwitchEvents.epoch.removeListener(_handleSchoolSwitch);
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Start one lightweight Firestore stream per conversation type.
  ///
  /// Also fetches counts from REST immediately so badges are visible before
  /// the Firestore connection is established — matching the web bootstrap.
  void startWatching() {
    unawaited(_bootstrapRest());
    for (final type in ConversationType.values) {
      _subscribeToType(type);
    }
  }

  /// Re-subscribes everything under the new org/school/persona scope after a
  /// school switch (drawer/FCM-driven) or persona switch (both fire
  /// [SchoolSwitchEvents.notifySwitched] — see custom_drawer.dart,
  /// active_school_switcher.dart, user_profile_screen.dart). Without this,
  /// badges kept showing the PREVIOUS scope's counts indefinitely whenever no
  /// `GlobalScaffold` happened to freshly mount after the switch.
  void _handleSchoolSwitch() {
    if (isClosed) return;
    if (SchoolSwitchEvents.epoch.value == _lastHandledEpoch) return;
    _lastHandledEpoch = SchoolSwitchEvents.epoch.value;

    // Stale counts/guards from the previous scope must not survive into the
    // new one — in particular, `_firestoreDelivered` would otherwise keep
    // treating a type as "already live" from the OLD school and permanently
    // suppress the NEW school's REST-seeded count for it.
    _counts.clear();
    _firestoreDelivered.clear();
    emit(const UnreadBadgeState.initial());
    startWatching();
  }

  /// REST bootstrap with a few retries. The one-shot fetch can run before the session token /
  /// org-school context is ready (returning nothing), leaving the badge blank until Firestore —
  /// which is itself racing custom-token sign-in. Retrying a couple of times makes counts appear.
  Future<void> _bootstrapRest() async {
    const delaysSeconds = [0, 2, 5];
    for (final d in delaysSeconds) {
      if (d > 0) await Future.delayed(Duration(seconds: d));
      if (isClosed) return;
      if (await _fetchFromApi()) return;
    }
  }

  /// Fallback: load counts once from REST API.
  Future<void> loadUnreadCounts() async {
    if (state.isLoading || state.isRefreshing) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetchFromApi();
  }

  // ─── Private ─────────────────────────────────────────────────────────────────

  void _subscribeToType(ConversationType type) {
    final key = type.toApiString();
    _subscriptions[key]?.cancel();

    _subscriptions[key] = _watchUnreadCountForTypeUseCase(type).listen((count) {
      if (isClosed) return;
      // A spurious 0 on the FIRST emit (custom-token sign-in still propagating, or an
      // empty/mismatched inbox path) must not clobber a positive REST-seeded count — that was
      // leaving the badge blank on mobile. Ignore a not-yet-live 0 that would hide the REST
      // count; a real (>0) emit, or a later 0 once Firestore is already live (a genuine read),
      // still applies.
      final alreadyLive = _firestoreDelivered.contains(key);
      if (count == 0 && !alreadyLive && (_counts[key] ?? 0) > 0) {
        debugPrint(
          '[UnreadDebug][badge:$key] ignoring spurious first-emit 0 '
          '(current=${_counts[key]})',
        );
        return;
      }
      debugPrint(
        '[UnreadDebug][badge:$key] Firestore aggregate emit: $count '
        '(was ${_counts[key]}, alreadyLive=$alreadyLive)',
      );
      _firestoreDelivered.add(
        key,
      ); // Firestore is now authoritative for this type
      _counts[key] = count;
      _emit();
    }, onError: (_) => unawaited(_bootstrapRest()));
  }

  void _emit() {
    if (!isClosed) {
      emit(
        UnreadBadgeState(
          countsByType: Map.unmodifiable(_counts),
          isLoading: false,
          isRefreshing: false,
        ),
      );
    }
  }

  Future<bool> _fetchFromApi() async {
    final result = await _getUnreadAggregatesUseCase();
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoading: false,
            isRefreshing: false,
            errorMessage: failure.message ?? 'Failed to load unread counts.',
          ),
        );
        return false;
      },
      (counts) {
        debugPrint('[UnreadDebug][badge] REST aggregates: $counts');
        // Seed only real conversation-type keys that Firestore hasn't delivered
        // yet. Skipping Firestore-delivered types keeps the reaction-inclusive
        // live count; filtering to known types drops the REST "TOTAL" aggregate
        // so it can't double-count in totalUnread.
        for (final type in ConversationType.values) {
          final key = type.toApiString();
          if (_firestoreDelivered.contains(key)) {
            debugPrint(
              '[UnreadDebug][badge:$key] REST value ignored (Firestore already live)',
            );
            continue;
          }
          final value = counts[key];
          if (value != null) _counts[key] = value;
        }
        _emit();
        return true;
      },
    );
  }
}
