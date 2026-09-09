import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:wowcare/domain/features/communication/services/messaging_session.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_conversations_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'conversation_list_state.dart';

/// Manages the conversation list for a single [ConversationType].
///
/// Primary data source: Firestore realtime stream via [WatchConversationsUseCase].
/// Fallback path:       Isar cache → REST API (used on Firestore error).
///
/// Instantiate one cubit per type (STAFF_DIRECT, ROOM_CHAT, ADMIN_CHAT).
class ConversationListCubit extends Cubit<ConversationListState> {
  ConversationListCubit({
    required ConversationType conversationType,
    required WatchConversationsUseCase watchConversationsUseCase,
    required GetConversationsEntityUseCase getConversationsUseCase,
    required GetCachedConversationsEntityUseCase getCachedConversationsUseCase,
    required ConversationEntityRepository conversationRepository,
    required MessagingSession session,
    required CreateOrOpenConversationUseCase createOrOpenConversationUseCase,
    required GetTagNameCodeMapForSchoolUseCase getTagNameCodeMapUseCase,
  }) : _conversationType = conversationType,
       _watchConversationsUseCase = watchConversationsUseCase,
       _getConversationsUseCase = getConversationsUseCase,
       _getCachedConversationsUseCase = getCachedConversationsUseCase,
       _conversationRepo = conversationRepository,
       _session = session,
       _createOrOpenConversationUseCase = createOrOpenConversationUseCase,
       _getTagNameCodeMapUseCase = getTagNameCodeMapUseCase,
       super(ConversationListState.initial(conversationType: conversationType));

  final ConversationType _conversationType;
  final WatchConversationsUseCase _watchConversationsUseCase;
  final GetConversationsEntityUseCase _getConversationsUseCase;
  final GetCachedConversationsEntityUseCase _getCachedConversationsUseCase;
  final ConversationEntityRepository _conversationRepo;
  final MessagingSession _session;
  final CreateOrOpenConversationUseCase _createOrOpenConversationUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapUseCase;

  StreamSubscription<List<ConversationEntity>>? _firestoreSubscription;
  StreamSubscription<String>? _markedReadSubscription;
  bool _firestoreActive = false;

  /// Unread count per conversation code, updated from EVERY Firestore
  /// snapshot regardless of whether filters are active. The Firestore
  /// listener below stops applying its snapshot to `state` while a filter/
  /// search is active (state.hasActiveFilters) — content-wise that's correct
  /// (Firestore's stream has no concept of those filters), but unread counts
  /// still need to stay live. Without a separate map, REST-driven refreshes
  /// while filtered (see `refresh()`/`_fallbackToApi()`) had nothing fresh to
  /// overlay and kept showing whatever counts were frozen at the moment the
  /// filter was first applied, never correcting even on pull-to-refresh.
  final Map<String, int> _latestFirestoreUnread = {};

  /// Dedup guard so a conversation's last message only triggers one
  /// markConversationDelivered call per change — keyed by conversation
  /// code, valued by the `lastMessageAt` we already processed.
  final Map<String, DateTime> _deliveredMarkedAt = {};

  static const int _pageSize = 20;

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _firestoreSubscription?.cancel();
    _markedReadSubscription?.cancel();
    return super.close();
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Start the Firestore realtime stream. Emits Isar cache first for a fast
  /// first frame, then keeps the list live via Firestore snapshots.
  ///
  /// Also subscribes to [MessagingEventService] so it can zero a conversation's
  /// badge immediately when the user opens that thread — before Firestore
  /// confirms the read receipt (~1-3 s later).
  /// Identity/session values, exposed so views read them through their owning
  /// cubit instead of reaching storage directly (Mandate 5). These are thin
  /// passthroughs over the injected [MessagingSession] — same read, same value.
  Future<String?> readActiveSchoolRole() =>
      _session.activeSchoolRole();

  Future<String?> readCurrentUserCode() =>
      _session.userCode();

  Future<String?> readActiveSchoolCode() =>
      _session.schoolCode();

  /// Use-case/repository access exposed so views go through their owning cubit
  /// rather than resolving these directly (Mandate 5). Each forwards to the
  /// injected dependency and returns its result unchanged — no behaviour change.
  Future<Map<String, String>> loadSchoolTagNameCodeMap(String schoolCode) =>
      _getTagNameCodeMapUseCase(schoolCode: schoolCode);

  Future<Either<Failure, ConversationEntity>> createOrOpenConversation({
    required ConversationType type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
    String title = '',
    String description = '',
    String avatarUrl = '',
  }) => _createOrOpenConversationUseCase(
    type: type,
    studentCode: studentCode,
    classroomCode: classroomCode,
    participantCodes: participantCodes,
    title: title,
    description: description,
    avatarUrl: avatarUrl,
  );

  Future<Either<Failure, ConversationEntity?>> findAdminChatConversation(
    String studentCode,
  ) => _conversationRepo.findAdminChatConversation(studentCode: studentCode);

  Future<Either<Failure, ConversationEntity?>> findRoomChatConversation(
    String studentCode,
  ) => _conversationRepo.findRoomChatConversation(studentCode: studentCode);

  Future<void> startWatching() async {
    emit(state.copyWith(isLoading: true));

    // 1. Emit Isar cache immediately for a fast first frame.
    final cacheResult = await _getCachedConversationsUseCase(
      type: _conversationType,
    );
    cacheResult.fold((_) {}, (cached) {
      if (cached.isNotEmpty && !isClosed) {
        emit(
          ConversationListState.loaded(
            conversationType: _conversationType,
            conversations: _sortedByLatest(cached),
            isFromCache: true,
          ),
        );
      }
    });

    // 2. Kick off a REST load in parallel with the Firestore subscribe below,
    // rather than waiting for Firestore to fail first. `onError` below is
    // NOT a reliable trigger for this: a `permission-denied` (e.g. Firebase
    // custom-token sign-in still in flight, or having silently failed with
    // nothing to retry it — see FirebaseAuthService.signIn()'s fire-and-forget
    // call sites in AuthCubit) gets retried internally inside
    // FirebaseConversationRealtimeDataSource's retry/backoff logic and NEVER
    // reaches this listener's `onError` at all, so `_fallbackToApi()` below
    // was provably unreachable for that failure mode — the inbox just sat on
    // whatever was in Isar cache (empty on a fresh install) forever. Running
    // both concurrently guarantees a working inbox regardless of Firestore's
    // connection/auth state; whichever lands first is shown, and the other
    // reconciles on top.
    unawaited(_fallbackToApi());

    // 3. Subscribe to Firestore.
    _firestoreSubscription?.cancel();
    _firestoreSubscription = _watchConversationsUseCase(type: _conversationType).listen(
      (conversations) {
        if (isClosed) return;
        _firestoreActive = true;
        // Kept fresh unconditionally — see _latestFirestoreUnread's own doc.
        for (final c in conversations) {
          _latestFirestoreUnread[c.code] = c.unreadCount;
        }
        // The Firestore inbox stream is always the FULL, unfiltered list
        // for this type — it has no concept of the classroomCodes/
        // tagCodes/designations filters applied via applyFilters(). While
        // a filter is active, let the REST-driven filtered result stand
        // rather than silently overwriting it with the unfiltered live
        // snapshot; live updates resume once filters are cleared.
        if (state.hasActiveFilters) return;
        debugPrint(
          '[UnreadDebug][${_conversationType.toApiString()}] Firestore snapshot: '
          '${conversations.map((c) => '${c.code}=${c.unreadCount}').join(', ')}',
        );
        emit(
          ConversationListState.loaded(
            conversationType: _conversationType,
            conversations: _sortedByLatest(
              _reconcileLastMessageSenderNames(conversations),
            ),
            isFromCache: false,
          ),
        );
        unawaited(_markDeliveredForIncomingMessages(conversations));
      },
      onError: (error) {
        if (!_firestoreActive) unawaited(_fallbackToApi());
      },
    );

    // 4. Subscribe to mark-read events so the badge zeroes instantly.
    _markedReadSubscription?.cancel();
    _markedReadSubscription = MessagingEventService
        .instance
        .onConversationMarkedRead
        .listen((code) => _zeroBadgeLocally(code));
  }

  /// Whenever a conversation's last message was sent by someone else, mark
  /// it delivered for the current user — even if that thread isn't open —
  /// so the sender's ticks advance without waiting for this user to open
  /// the chat. Deduped per conversation by `lastMessageAt`.
  Future<void> _markDeliveredForIncomingMessages(
    List<ConversationEntity> conversations,
  ) async {
    final currentUserCode = (await _session.userCode())?.trim();
    if (currentUserCode == null || currentUserCode.isEmpty) return;

    for (final conversation in conversations) {
      final sender = conversation.lastMessageBy;
      final at = conversation.lastMessageAt;
      if (sender == null || sender == currentUserCode || at == null) continue;
      if (_deliveredMarkedAt[conversation.code] == at) continue;
      _deliveredMarkedAt[conversation.code] = at;
      unawaited(_conversationRepo.markConversationDelivered(conversation.code));
    }
  }

  /// Search the staff directory by name fragment.
  ///
  /// Results are stored in [ConversationListState.staffSearchResults] so the
  /// screen can render a "Staff Directory" section below existing conversations.
  /// Clears results when [query] is empty.
  ///
  /// Error handling: Preserves previous results and exposes error message for retry.
  Future<void> searchStaffDirectory(String query) async {
    if (isClosed) return;

    if (query.trim().isEmpty) {
      emit(
        state.copyWith(
          staffSearchResults: const [],
          isSearchingStaff: false,
          lastStaffSearchQuery: null,
          clearStaffSearchError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isSearchingStaff: true, clearStaffSearchError: true));

    final orgCode =
        (await _session.organizationCode() ?? '')
            .trim();
    final schoolCode =
        (await _session.schoolCode() ?? '').trim();

    if (isClosed) return;

    final result = await _conversationRepo.searchStaffForMessaging(
      query: query.trim(),
      organizationCode: orgCode,
      schoolCode: schoolCode,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isSearchingStaff: false,
            staffSearchErrorMessage:
                failure.message ?? 'Failed to search staff',
            lastStaffSearchQuery: query.trim(),
          ),
        );
      },
      (staff) {
        emit(
          state.copyWith(
            staffSearchResults: staff,
            isSearchingStaff: false,
            lastStaffSearchQuery: query.trim(),
            clearStaffSearchError: true,
          ),
        );
      },
    );
  }

  /// Retry the last failed staff directory search.
  /// Only callable when a search error exists.
  Future<void> retryStaffSearch() async {
    final lastQuery = state.lastStaffSearchQuery;
    if (lastQuery == null || lastQuery.isEmpty) return;

    await searchStaffDirectory(lastQuery);
  }

  /// Create a STAFF_DIRECT conversation with a staff member from search results.
  ///
  /// Called when user taps a staff member in the directory search.
  /// If conversation already exists, it opens that one instead.
  /// After creation, refreshes conversation list so new conversation appears.
  Future<ConversationEntity?> createOrGetStaffDirectConversation(
    String staffUserCode,
    String staffName,
    String? staffAvatarCode,
  ) async {
    if (isClosed || _conversationType != ConversationType.staffDirect)
      return null;

    try {
      // Check if conversation already exists
      final existingResult = await _conversationRepo
          .findStaffDirectConversation(staffUserCode);

      var existing = existingResult.fold((_) => null, (conv) => conv);

      if (existing != null) {
        return existing;
      }

      // Create new conversation
      final result = await _conversationRepo.createConversation(
        type: ConversationType.staffDirect,
        studentCode: '', // Not used for STAFF_DIRECT
        participantCodes: [staffUserCode],
        title: staffName,
        avatarUrl: staffAvatarCode ?? '',
      );

      if (isClosed) return null;

      // Refresh conversation list to show new conversation
      result.fold(
        (failure) {
          emit(
            state.copyWith(
              staffSearchErrorMessage:
                  failure.message ?? 'Failed to create conversation',
              clearStaffSearchError: false,
            ),
          );
        },
        (newConversation) {
          // Clear search results and error after successful creation
          emit(
            state.copyWith(
              staffSearchResults: const [],
              staffSearchErrorMessage: null,
              clearStaffSearchError: true,
            ),
          );

          // Refresh conversation list to fetch new conversation
          unawaited(refresh());
        },
      );

      return result.fold((_) => null, (conv) => conv);
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            staffSearchErrorMessage:
                'Failed to create conversation: ${e.toString()}',
          ),
        );
      }
      return null;
    }
  }

  /// Every staff employment status the backend recognizes. Used as the
  /// STAFF_DIRECT default so the list shows staff of every status instead
  /// of implicitly excluding upcoming/inactive ones.
  static const List<String> _allStaffStatuses = [
    'UPCOMING',
    'ACTIVE',
    'INACTIVE',
  ];

  /// Resolves the conversation-level `status` query param. STAFF_DIRECT no
  /// longer sends it at all — `staffStatuses` (see [_networkStaffStatuses])
  /// now fully controls which staff-counterpart statuses come back,
  /// confirmed against the backend to return the correct combined result
  /// set for all three statuses at once (sending `status` alongside an
  /// overlapping `staffStatuses` value was separately confirmed to return
  /// EMPTY, which is why this used to pick a single value out of
  /// staffStatuses instead). Other conversation types keep the original
  /// hardcoded 'ACTIVE'.
  String? _resolveConversationStatus() {
    if (_conversationType == ConversationType.staffDirect) return null;
    return 'ACTIVE';
  }

  /// STAFF_DIRECT only: defaults to [_allStaffStatuses] whenever no explicit
  /// staff-status filter is active, so the list shows staff of every
  /// employment status by default. An explicit filter selection (via
  /// [applyFilters]) is sent through as-is, narrowing to just that subset.
  /// Other conversation types have no staff-status concept and always get
  /// an empty (omitted) param — studentStatuses is what they use instead.
  List<String> _networkStaffStatuses(List<String> staffStatuses) {
    if (_conversationType != ConversationType.staffDirect) return const [];
    return staffStatuses.isEmpty ? _allStaffStatuses : staffStatuses;
  }

  /// Apply filters to the conversation list — available for any type.
  /// [classroomCodes]/[tagCodes] apply to student-scoped types (ROOM_CHAT,
  /// ADMIN_CHAT); [designations]/[staffStatuses] apply to STAFF_DIRECT.
  /// Mirrors the backend's getConversationsByType query contract exactly
  /// (see GetConversationsEntityUseCase), so unlike the old classroom-owner
  /// client-side matching this actually narrows the server-side result set.
  Future<void> applyFilters({
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
  }) async {
    final resolvedClassrooms = classroomCodes ?? const [];
    final resolvedTags = tagCodes ?? const [];
    final resolvedDesignations = designations ?? const [];
    final resolvedStudentStatuses = studentStatuses ?? const [];
    final resolvedStaffStatuses = staffStatuses ?? const [];

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        activeClassroomCodes: resolvedClassrooms,
        activeTagCodes: resolvedTags,
        activeDesignations: resolvedDesignations,
        activeStudentStatuses: resolvedStudentStatuses,
        activeStaffStatuses: resolvedStaffStatuses,
        activeSearch: search,
        clearActiveSearch: search == null,
        page: 0,
        conversations: const [],
      ),
    );

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: _resolveConversationStatus(),
      page: 0,
      size: _pageSize,
      classroomCodes: resolvedClassrooms,
      tagCodes: resolvedTags,
      designations: resolvedDesignations,
      studentStatuses: resolvedStudentStatuses,
      staffStatuses: _networkStaffStatuses(resolvedStaffStatuses),
      search: search,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to apply filters.',
        ),
      ),
      (conversations) => emit(
        ConversationListState.loaded(
          conversationType: _conversationType,
          conversations: _sortedByLatest(
            _reconcileLastMessageSenderNames(conversations),
          ),
          isFromCache: false,
          page: 0,
          hasMore: conversations.length >= _pageSize,
          activeClassroomCodes: resolvedClassrooms,
          activeTagCodes: resolvedTags,
          activeDesignations: resolvedDesignations,
          activeStudentStatuses: resolvedStudentStatuses,
          activeStaffStatuses: resolvedStaffStatuses,
          activeSearch: search,
        ),
      ),
    );
  }

  /// Clear all active filters and reload conversations.
  Future<void> clearFilters() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        activeClassroomCodes: const [],
        activeTagCodes: const [],
        activeDesignations: const [],
        activeStudentStatuses: const [],
        activeStaffStatuses: const [],
        clearActiveSearch: true,
        page: 0,
        conversations: const [],
      ),
    );

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: _resolveConversationStatus(),
      page: 0,
      size: _pageSize,
      staffStatuses: _networkStaffStatuses(const []),
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to clear filters.',
        ),
      ),
      (conversations) => emit(
        ConversationListState.loaded(
          conversationType: _conversationType,
          conversations: _sortedByLatest(
            _reconcileLastMessageSenderNames(conversations),
          ),
          isFromCache: false,
          page: 0,
          hasMore: conversations.length >= _pageSize,
        ),
      ),
    );
  }

  /// Pull-to-refresh: forces a REST API fetch for conversation content
  /// (title/participants/last message/etc.) regardless of Firestore state,
  /// but never for unread counts — Firestore is the sole source of truth
  /// for those (see [includeRestUnreadCounts]: false below). Each returned
  /// conversation's `unreadCount` is instead overlaid from the current
  /// state, which is kept live by the primary Firestore stream
  /// ([_watchConversationsUseCase]) that's already running for the
  /// lifetime of this cubit. Preserves active filters if any are set.
  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearError: true));

    // Firestore is the primary source (see class doc) and, once live with no
    // filters applied, is ALREADY streaming the full, correctly-ordered list
    // independently of this pull-to-refresh gesture. Replacing state with a
    // separately-paginated/ordered REST snapshot on top of that made the list
    // visibly flip-flop between the two sources' orderings — a conversation
    // could appear to reorder or momentarily duplicate at the seam as
    // whichever response landed last won, then the next Firestore snapshot
    // (arriving on its own timeline, unrelated to this refresh) immediately
    // won again. REST is only actually needed here when it's the sole source
    // in play — either Firestore hasn't gone live yet, or filters are active
    // (Firestore's own listener steps aside for filters; see the `if
    // (state.hasActiveFilters) return;` guard below).
    if (_firestoreActive && !state.hasActiveFilters) {
      if (!isClosed) emit(state.copyWith(isRefreshing: false));
      return;
    }

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: _resolveConversationStatus(),
      page: 0,
      size: _pageSize,
      classroomCodes: state.activeClassroomCodes,
      tagCodes: state.activeTagCodes,
      designations: state.activeDesignations,
      studentStatuses: state.activeStudentStatuses,
      staffStatuses: _networkStaffStatuses(state.activeStaffStatuses),
      search: state.activeSearch,
      includeRestUnreadCounts: false,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: failure.message ?? 'Failed to refresh conversations.',
        ),
      ),
      (conversations) {
        // Overlay from _latestFirestoreUnread (kept live on every Firestore
        // snapshot regardless of filter state — see its own doc) rather than
        // state.conversations, which stops being updated for counts the
        // whole time a filter/search is active and would otherwise keep
        // showing the same stale numbers no matter how many times this
        // refresh runs. A conversation missing from the map (e.g. brand new)
        // defaults to 0 until the live Firestore stream delivers its real
        // count moments later.
        final withFirestoreUnread = conversations
            .map(
              (c) =>
                  c.copyWith(unreadCount: _latestFirestoreUnread[c.code] ?? 0),
            )
            .toList();
        debugPrint(
          '[UnreadDebug][${_conversationType.toApiString()}] refresh() result '
          '(unread from Firestore-backed state, not REST): '
          '${withFirestoreUnread.map((c) => '${c.code}=${c.unreadCount}').join(', ')}',
        );
        emit(
          ConversationListState.loaded(
            conversationType: _conversationType,
            conversations: _sortedByLatest(
              _reconcileLastMessageSenderNames(withFirestoreUnread),
            ),
            isFromCache: false,
            page: 0,
            hasMore: conversations.length >= _pageSize,
            activeClassroomCodes: state.activeClassroomCodes,
            activeTagCodes: state.activeTagCodes,
            activeDesignations: state.activeDesignations,
            activeStudentStatuses: state.activeStudentStatuses,
            activeStaffStatuses: state.activeStaffStatuses,
            activeSearch: state.activeSearch,
          ),
        );
      },
    );

    // The bell badge on the top app bar (UnreadBadgeCubit) is a separate,
    // app-wide singleton with its own Firestore stream — Firestore is the
    // sole source of truth for unread counts, so pull-to-refresh must not
    // nudge a REST refetch into it (that REST value would apply to any
    // conversation type Firestore hasn't delivered yet this session).
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  /// Immediately set unreadCount = 0 for [conversationCode] in local state.
  /// Called when [MessagingEventService] emits a mark-read event, before
  /// Firestore confirms the update.
  void _zeroBadgeLocally(String conversationCode) {
    if (isClosed) return;
    final updated = state.conversations.map((c) {
      if (c.code != conversationCode || c.unreadCount == 0) return c;
      return _withUnreadCount(c, 0);
    }).toList();
    emit(state.copyWith(conversations: updated));
  }

  /// Returns a copy of [entity] with [unreadCount] replaced.
  ConversationEntity _withUnreadCount(ConversationEntity e, int count) {
    return ConversationEntity(
      id: e.id,
      code: e.code,
      type: e.type,
      title: e.title,
      description: e.description,
      avatarUrl: e.avatarUrl,
      status: e.status,
      organizationCode: e.organizationCode,
      schoolCode: e.schoolCode,
      createdAt: e.createdAt,
      createdBy: e.createdBy,
      updatedAt: e.updatedAt,
      updatedBy: e.updatedBy,
      participantCount: e.participantCount,
      unreadCount: count,
      lastMessagePreview: e.lastMessagePreview,
      lastMessageAt: e.lastMessageAt,
      lastMessageBy: e.lastMessageBy,
      lastMessageSenderName: e.lastMessageSenderName,
      participants: e.participants,
      studentCode: e.studentCode,
      classroomCode: e.classroomCode,
      privateModeStates: e.privateModeStates,
      // Without these, every call site silently reset room-wide private
      // mode to OFF (privateModeActive defaults to false, activatedBy/At to
      // null on the constructor) — including a guardian's OWN send, since
      // `markConversationRead` fires for that too and routes through here.
      // Any screen subscribed to this cubit's stream to sync a local
      // private-mode toggle (`PrivateModeToggleCubit.syncFromRemote`, see
      // parent_messaging_thread.dart) would then flip that toggle off a
      // moment after sending, even though nobody touched it.
      privateModeActive: e.privateModeActive,
      privateModeActivatedBy: e.privateModeActivatedBy,
      privateModeActivatedAt: e.privateModeActivatedAt,
    );
  }

  Future<void> _fallbackToApi() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: _resolveConversationStatus(),
      page: 0,
      size: _pageSize,
      classroomCodes: state.activeClassroomCodes,
      tagCodes: state.activeTagCodes,
      designations: state.activeDesignations,
      studentStatuses: state.activeStudentStatuses,
      staffStatuses: _networkStaffStatuses(state.activeStaffStatuses),
      search: state.activeSearch,
      includeRestUnreadCounts: false,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to load conversations.',
        ),
      ),
      (conversations) {
        // This runs unconditionally alongside the Firestore subscribe below
        // (see startWatching's own comment on why), so it can land BEFORE
        // Firestore's first snapshot — unread counts must still never come
        // from this REST response (per the app-wide rule: unread counts are
        // Firestore-only). Overlay from _latestFirestoreUnread (see its own
        // doc — kept live regardless of filter state, unlike
        // state.conversations); a code missing from it (not seen yet)
        // defaults to 0 until the live Firestore stream, already starting
        // concurrently, delivers its real count moments later. Mirrors
        // refresh()'s identical merge.
        final withFirestoreUnread = conversations
            .map(
              (c) =>
                  c.copyWith(unreadCount: _latestFirestoreUnread[c.code] ?? 0),
            )
            .toList();
        emit(
          ConversationListState.loaded(
            conversationType: _conversationType,
            conversations: _sortedByLatest(
              _reconcileLastMessageSenderNames(withFirestoreUnread),
            ),
            isFromCache: false,
            page: 0,
            hasMore: conversations.length >= _pageSize,
            activeClassroomCodes: state.activeClassroomCodes,
            activeTagCodes: state.activeTagCodes,
            activeDesignations: state.activeDesignations,
            activeStudentStatuses: state.activeStudentStatuses,
            activeStaffStatuses: state.activeStaffStatuses,
            activeSearch: state.activeSearch,
          ),
        );
      },
    );
  }

  /// Once a conversation's true last-message sender name has been shown,
  /// never let a SUBSEQUENT update blank it out for the SAME message —
  /// only ever replace it with a genuinely new value. This cubit has two
  /// independent, uncoordinated sources feeding `emit()` (a parallel REST
  /// fetch and an ongoing Firestore watch — see [startWatching]'s own
  /// comment on why both run concurrently); whichever lands last simply
  /// overwrites the state. The Firestore inbox doc can genuinely lack this
  /// field even when REST has it — without this guard, if Firestore's
  /// snapshot happens to land right after a correct REST result and then
  /// goes quiet (no further activity in that thread), the incomplete data
  /// becomes permanent: correct for a moment, then silently blanked.
  /// Matched on `lastMessageAt` so an old sender's name is never
  /// misattributed to an actually-newer message that legitimately has none.
  List<ConversationEntity> _reconcileLastMessageSenderNames(
    List<ConversationEntity> incoming,
  ) {
    if (incoming.isEmpty || state.conversations.isEmpty) return incoming;
    final previousByCode = {for (final c in state.conversations) c.code: c};
    return incoming.map((c) {
      if (c.lastMessageSenderName?.trim().isNotEmpty ?? false) return c;
      final previous = previousByCode[c.code];
      if (previous == null || previous.lastMessageAt != c.lastMessageAt) {
        return c;
      }
      final priorName = previous.lastMessageSenderName;
      if (priorName == null || priorName.trim().isEmpty) return c;
      return c.copyWith(lastMessageSenderName: priorName);
    }).toList();
  }

  List<ConversationEntity> _sortedByLatest(
    List<ConversationEntity> conversations,
  ) {
    final sorted = List<ConversationEntity>.from(conversations);
    sorted.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.updatedAt;
      final bTime = b.lastMessageAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }
}
