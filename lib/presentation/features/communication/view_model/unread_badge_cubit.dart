import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_total_unread_count_usecase.dart';
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
    required WatchTotalUnreadCountUseCase watchTotalUnreadCountUseCase,
  }) : _watchUnreadCountForTypeUseCase = watchUnreadCountForTypeUseCase,
       _watchTotalUnreadCountUseCase = watchTotalUnreadCountUseCase,
       super(const UnreadBadgeState.initial()) {
    SchoolSwitchEvents.epoch.addListener(_handleSchoolSwitch);
  }

  final WatchUnreadCountForTypeUseCase _watchUnreadCountForTypeUseCase;
  final WatchTotalUnreadCountUseCase _watchTotalUnreadCountUseCase;

  int _lastHandledEpoch = SchoolSwitchEvents.epoch.value;

  final Map<String, StreamSubscription<int>> _subscriptions = {};
  final Map<String, int> _counts = {};

  /// One listener over the WHOLE `user_inbox/{userCode}/conversations`
  /// collection — no per-type filter — summed client-side by Firestore
  /// itself's own doc count, matching the web's `FirestoreInboxService
  /// .listenToUserInbox` pattern. Drives the top app bar badge (see
  /// [CustomAppBar]) directly, independent of the per-type breakdown below.
  StreamSubscription<int>? _totalSubscription;
  int? _firestoreTotal;

  /// Conversation-type keys whose live Firestore stream has delivered at
  /// least once. Distinguishes a genuine "just read" 0 from a spurious
  /// first-emit 0 (custom-token sign-in still propagating, or an
  /// empty/mismatched inbox path on initial connect) — see
  /// [_subscribeToType]'s use of this.
  final Set<String> _firestoreDelivered = {};

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    SchoolSwitchEvents.epoch.removeListener(_handleSchoolSwitch);
    unawaited(_totalSubscription?.cancel());
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Start one lightweight Firestore stream per conversation type.
  ///
  /// Firestore is the ONLY source for these counts — no REST fallback/
  /// bootstrap. The badge shows nothing for the brief moment before the
  /// first snapshot arrives, rather than risk ever showing a value that
  /// didn't come from Firestore.
  void startWatching() {
    for (final type in ConversationType.values) {
      _subscribeToType(type);
    }
    _subscribeToTotal();
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
    // treating a type as "already live" from the OLD school and suppress a
    // fresh first-emit-0 guard for the NEW school's stream.
    _counts.clear();
    _firestoreDelivered.clear();
    _firestoreTotal = null;
    emit(const UnreadBadgeState.initial());
    startWatching();
  }

  // ─── Private ─────────────────────────────────────────────────────────────────

  void _subscribeToType(ConversationType type) {
    final key = type.toApiString();
    _subscriptions[key]?.cancel();

    _subscriptions[key] = _watchUnreadCountForTypeUseCase(type).listen((count) {
      if (isClosed) return;
      // A spurious 0 on the FIRST emit (custom-token sign-in still propagating, or an
      // empty/mismatched inbox path) must not clobber whatever count is already showing.
      // A real (>0) emit, or a later 0 once Firestore is already live (a genuine read),
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
    }, onError: (_) => _retrySubscribeToType(type));
  }

  /// No REST fallback on a stream error — Firestore is the only source for
  /// these counts (see class doc). Retry the SAME Firestore stream instead.
  void _retrySubscribeToType(ConversationType type) {
    Future.delayed(const Duration(seconds: 3), () {
      if (!isClosed) _subscribeToType(type);
    });
  }

  /// One unfiltered listener over the whole `user_inbox` collection,
  /// summed by Firestore-doc count rather than combined from the per-type
  /// streams above — see [_firestoreTotal]'s own doc for why this is
  /// separate.
  void _subscribeToTotal() {
    _totalSubscription?.cancel();
    _totalSubscription = _watchTotalUnreadCountUseCase().listen((total) {
      if (isClosed) return;
      debugPrint('[UnreadDebug][badge:TOTAL] Firestore inbox sum: $total');
      _firestoreTotal = total;
      _emit();
    });
  }

  void _emit() {
    if (!isClosed) {
      emit(
        UnreadBadgeState(
          countsByType: Map.unmodifiable(_counts),
          isLoading: false,
          isRefreshing: false,
          firestoreTotal: _firestoreTotal,
        ),
      );
    }
  }
}
