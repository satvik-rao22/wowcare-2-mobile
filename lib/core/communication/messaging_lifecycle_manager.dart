import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:wowcare/core/communication/messaging_logger.dart';
import 'package:wowcare/core/network/network_info.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/drain_sync_queue_usecase.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';

/// Orchestrates existing messaging behaviour around app lifecycle,
/// connectivity, and logout — it owns no business state and introduces no
/// new business logic. Every method here does nothing but call an already
/// public method on an already existing Cubit/UseCase/Repository, at a
/// better-defined moment than today (where these moments are currently
/// either unhandled or ad hoc).
///
/// `ConversationListCubit` / `ConversationThreadCubit` are constructed per
/// screen (not GetIt singletons), so this manager can't hold them directly —
/// screens call [attachConversationList]/[attachThread] in `initState` and
/// the matching `detach*` in `dispose`, mirroring the existing
/// `WidgetsBindingObserver` add/remove pattern already used in
/// `conversation_thread_screen.dart`. `UnreadBadgeCubit` *is* a GetIt
/// singleton, so it can be attached once at bootstrap.
///
/// This class does not modify, subclass, or wrap any Cubit's public API —
/// it only calls methods that already exist.
class MessagingLifecycleManager with WidgetsBindingObserver {
  MessagingLifecycleManager({
    required NetworkInfo networkInfo,
    required DrainSyncQueueUseCase drainSyncQueueUseCase,
    required ConversationEntityRepository conversationRepository,
    UnreadBadgeCubit? unreadBadgeCubit,
  }) : conversationLifecycle = ConversationLifecycle(),
       threadLifecycle = ThreadLifecycle(),
       firestoreLifecycle = FirestoreLifecycle(),
       cacheLifecycle = CacheLifecycle(
         conversationRepository: conversationRepository,
       ),
       notificationLifecycle = NotificationLifecycle(),
       _unreadBadgeCubit = unreadBadgeCubit,
       syncLifecycle = SyncLifecycle(
         networkInfo: networkInfo,
         drainSyncQueueUseCase: drainSyncQueueUseCase,
       ) {
    syncLifecycle._onConnectivityRestored = _onConnectivityRestored;
  }

  final ConversationLifecycle conversationLifecycle;
  final ThreadLifecycle threadLifecycle;
  final FirestoreLifecycle firestoreLifecycle;
  final CacheLifecycle cacheLifecycle;
  final SyncLifecycle syncLifecycle;
  final NotificationLifecycle notificationLifecycle;

  /// A GetIt-singleton Cubit (unlike `ConversationListCubit`/
  /// `ConversationThreadCubit`, which are constructed per screen) — safe to
  /// hold directly rather than via attach/detach. Nullable only so tests
  /// don't have to construct a real `UnreadBadgeCubit`.
  final UnreadBadgeCubit? _unreadBadgeCubit;

  bool _initialized = false;

  /// Registers this manager as an app-lifecycle observer and starts the
  /// connectivity watch. Idempotent — safe to call more than once (e.g. from
  /// eager DI construction).
  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    syncLifecycle._start();
  }

  void dispose() {
    if (!_initialized) return;
    _initialized = false;
    WidgetsBinding.instance.removeObserver(this);
    syncLifecycle._stop();
  }

  // ─── App lifecycle ────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.inactive:
        MessagingLogger.log(event: 'APP_INACTIVE');
        break;
      case AppLifecycleState.paused:
        _onPaused();
        break;
      case AppLifecycleState.hidden:
        MessagingLogger.log(event: 'APP_HIDDEN');
        break;
      case AppLifecycleState.detached:
        _onDetached();
        break;
    }
  }

  void _onResumed() {
    firestoreLifecycle._recordResumed();
    conversationLifecycle._onAppResumed();
    threadLifecycle._onAppResumed();
    _refreshUnreadCounts();
    MessagingLogger.log(
      event: MessagingEvent.appResumed,
      metadata: {
        'backgroundedForMs':
            firestoreLifecycle.lastBackgroundDuration?.inMilliseconds,
      },
    );
  }

  void _onPaused() {
    firestoreLifecycle._recordPaused();
    MessagingLogger.log(event: MessagingEvent.appPaused);
  }

  void _onDetached() {
    // Cleanup temporary resources only — no owned subscriptions to cancel
    // here since this manager never created any; the attached Cubits' own
    // `close()` (already correct, per the architecture audit) handles that.
    MessagingLogger.log(event: MessagingEvent.appTerminated);
  }

  void _onConnectivityRestored() {
    conversationLifecycle._onConnectivityRestored();
    threadLifecycle._onConnectivityRestored();
    _refreshUnreadCounts();
  }

  void _refreshUnreadCounts() {
    final cubit = _unreadBadgeCubit;
    if (cubit == null || cubit.isClosed) return;
    unawaited(cubit.loadUnreadCounts());
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  /// Call from the existing logout flow (see `AuthCubit.logoutSession`),
  /// alongside the other post-logout cleanup calls it already makes for
  /// `ParentChildCubit`/`RoleCubit`. Wrap in try/catch at the call site,
  /// matching that file's existing pattern — a messaging cleanup failure
  /// must never block logout.
  Future<void> onLogout() async {
    MessagingLogger.log(event: MessagingEvent.logout);
    conversationLifecycle.detachConversationList();
    threadLifecycle.detachThread();
    await cacheLifecycle.clearMessagingCache();
  }
}

// ─── ConversationLifecycle ───────────────────────────────────────────────────

/// Orchestrates the currently-visible [ConversationListCubit], if any.
class ConversationLifecycle {
  ConversationListCubit? _cubit;

  void attachConversationList(ConversationListCubit cubit) {
    _cubit = cubit;
  }

  void detachConversationList() {
    _cubit = null;
  }

  void _onAppResumed() {
    final cubit = _cubit;
    if (cubit == null || cubit.isClosed) return;
    unawaited(cubit.refresh());
  }

  void _onConnectivityRestored() {
    final cubit = _cubit;
    if (cubit == null || cubit.isClosed) return;
    unawaited(cubit.refresh());
  }
}

// ─── ThreadLifecycle ──────────────────────────────────────────────────────────

/// Orchestrates the currently-open [ConversationThreadCubit], if any.
class ThreadLifecycle {
  ConversationThreadCubit? _cubit;
  DateTime? _openedAt;

  void attachThread(ConversationThreadCubit cubit) {
    _cubit = cubit;
    _openedAt = DateTime.now();
    MessagingLogger.log(event: MessagingEvent.threadOpened, metadata: const {});
  }

  void detachThread() {
    final openedAt = _openedAt;
    if (openedAt != null) {
      MessagingLogger.log(
        event: MessagingEvent.threadClosed,
        duration: DateTime.now().difference(openedAt).inMilliseconds,
      );
    }
    _cubit = null;
    _openedAt = null;
  }

  void _onAppResumed() {
    final cubit = _cubit;
    if (cubit == null || cubit.isClosed) return;
    unawaited(cubit.refreshMessages());
    unawaited(cubit.markConversationRead());
  }

  void _onConnectivityRestored() {
    final cubit = _cubit;
    if (cubit == null || cubit.isClosed) return;
    unawaited(cubit.refreshMessages());
  }
}

// ─── FirestoreLifecycle ───────────────────────────────────────────────────────

/// Records background/foreground transitions for observability. There is no
/// existing pause/resume API on the realtime data sources or the Cubits that
/// consume them (confirmed by the architecture audit), so this does not
/// forcibly tear down any live Firestore subscription — that would require
/// changing an existing Cubit's public surface, which is out of scope. It
/// exists so the *duration* of a background period is known, and so
/// `ConversationLifecycle`/`ThreadLifecycle` can reconcile state via their
/// existing, safe `refresh()`/`refreshMessages()` calls on resume.
class FirestoreLifecycle {
  DateTime? _pausedAt;
  Duration? lastBackgroundDuration;

  void _recordPaused() {
    _pausedAt = DateTime.now();
  }

  void _recordResumed() {
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      lastBackgroundDuration = DateTime.now().difference(pausedAt);
    }
    _pausedAt = null;
  }
}

// ─── CacheLifecycle ───────────────────────────────────────────────────────────

/// Wraps the existing, already-defined cache-clearing repository methods —
/// [ConversationEntityRepository.clearConversationsCache], which had no
/// caller before this manager (confirmed by the architecture audit's logout
/// finding). No new persistence logic is introduced. Per-conversation
/// message cache clearing (`MessageEntityRepository.clearMessagesCache`)
/// is intentionally not wired here — it takes a conversation code and there
/// is no existing "list all cached conversation codes" call site to source
/// one from at logout without inventing new cross-repository logic.
class CacheLifecycle {
  CacheLifecycle({required ConversationEntityRepository conversationRepository})
    : _conversationRepository = conversationRepository;

  final ConversationEntityRepository _conversationRepository;

  Future<void> clearMessagingCache() async {
    await _conversationRepository.clearConversationsCache();
  }
}

// ─── SyncLifecycle ────────────────────────────────────────────────────────────

/// Wires the existing, previously-unwired [DrainSyncQueueUseCase] to the
/// existing [NetworkInfo.onConnectivityChanged] stream. Neither dependency's
/// own logic is modified — this only decides *when* to call them.
class SyncLifecycle {
  SyncLifecycle({
    required NetworkInfo networkInfo,
    required DrainSyncQueueUseCase drainSyncQueueUseCase,
  }) : _networkInfo = networkInfo,
       _drainSyncQueueUseCase = drainSyncQueueUseCase;

  final NetworkInfo _networkInfo;
  final DrainSyncQueueUseCase _drainSyncQueueUseCase;
  StreamSubscription<bool>? _subscription;
  bool? _lastKnownConnected;
  VoidCallback? _onConnectivityRestored;

  void _start() {
    _subscription?.cancel();
    _subscription = _networkInfo.onConnectivityChanged.listen(_onChanged);
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onChanged(bool connected) async {
    final wasConnected = _lastKnownConnected;
    _lastKnownConnected = connected;

    if (!connected) {
      MessagingLogger.log(event: MessagingEvent.connectivityLost);
      return;
    }

    // Only treat this as a "restored" transition, not every connected event
    // (the stream can fire on network-type changes, e.g. wifi -> cellular,
    // while already connected).
    if (wasConnected == false) {
      MessagingLogger.log(event: MessagingEvent.connectivityRestored);
      final drained = await _drainSyncQueueUseCase();
      MessagingLogger.log(
        event: MessagingEvent.syncQueueDrained,
        metadata: {'succeeded': drained},
      );
      _onConnectivityRestored?.call();
    }
  }
}

// ─── NotificationLifecycle ────────────────────────────────────────────────────

/// Observability-only hook for push notification events. No existing
/// notification routing is touched — this is a place to log delivery/tap
/// events for the messaging feature specifically if/when that instrumentation
/// is added; it makes no routing decisions itself.
class NotificationLifecycle {
  void logDelivered({required String conversationType}) {
    MessagingLogger.log(
      event: 'PUSH_DELIVERED',
      metadata: {'conversationType': conversationType},
    );
  }

  void logTapped({required String conversationType}) {
    MessagingLogger.log(
      event: 'PUSH_TAPPED',
      metadata: {'conversationType': conversationType},
    );
  }
}
