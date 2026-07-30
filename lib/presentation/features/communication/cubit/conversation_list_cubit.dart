import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_conversations_usecase.dart';
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
    required StorageService storageService,
  }) : _conversationType = conversationType,
       _watchConversationsUseCase = watchConversationsUseCase,
       _getConversationsUseCase = getConversationsUseCase,
       _getCachedConversationsUseCase = getCachedConversationsUseCase,
       _conversationRepo = conversationRepository,
       _storageService = storageService,
       super(ConversationListState.initial(conversationType: conversationType));

  final ConversationType _conversationType;
  final WatchConversationsUseCase _watchConversationsUseCase;
  final GetConversationsEntityUseCase _getConversationsUseCase;
  final GetCachedConversationsEntityUseCase _getCachedConversationsUseCase;
  final ConversationEntityRepository _conversationRepo;
  final StorageService _storageService;

  StreamSubscription<List<ConversationEntity>>? _firestoreSubscription;
  StreamSubscription<String>? _markedReadSubscription;
  bool _firestoreActive = false;

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
  Future<void> startWatching() async {
    emit(state.copyWith(isLoading: true));

    final String debugUserCode =
        (await _storageService.getString(StorageKeys.userCode)) ?? '';
    final String debugOrgCode =
        (await _storageService.getString(StorageKeys.organizationCode)) ?? '';
    final String debugSchoolCode =
        (await _storageService.getString(StorageKeys.schoolCode)) ?? '';

    // 1. Emit Isar cache immediately for a fast first frame.
    final cacheResult = await _getCachedConversationsUseCase(
      type: _conversationType,
    );
    cacheResult.fold((_) {}, (cached) {
      if (cached.isNotEmpty && !isClosed) {
        final int debugPrevCount = state.conversations.length;
        emit(
          ConversationListState.loaded(
            conversationType: _conversationType,
            conversations: _sortedByLatest(cached),
            isFromCache: true,
          ),
        );
      }
    });

    // 2. Subscribe to Firestore.
    _firestoreSubscription?.cancel();
    _firestoreSubscription = _watchConversationsUseCase(type: _conversationType)
        .listen(
          (conversations) {
            if (isClosed) return;
            _firestoreActive = true;
            final int debugPrevCount = state.conversations.length;
            emit(
              ConversationListState.loaded(
                conversationType: _conversationType,
                conversations: _sortedByLatest(conversations),
                isFromCache: false,
              ),
            );
            unawaited(_markDeliveredForIncomingMessages(conversations));
          },
          onError: (error) {
            if (!_firestoreActive) unawaited(_fallbackToApi());
          },
        );

    // 3. Subscribe to mark-read events so the badge zeroes instantly.
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
    final currentUserCode = (await _storageService.getString(
      StorageKeys.userCode,
    ))?.trim();
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
        (await _storageService.getString(StorageKeys.organizationCode) ?? '')
            .trim();
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

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

  /// Apply filters to the STAFF_DIRECT conversation list.
  /// Only available for [ConversationType.staffDirect].
  Future<void> applyFilters({
    String? designation,
    String? staffStatus,
    String? classroom,
  }) async {
    if (_conversationType != ConversationType.staffDirect) return;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearDesignation: designation == null,
        clearStaffStatus: staffStatus == null,
        clearClassroom: classroom == null,
        activeDesignation: designation,
        activeStaffStatus: staffStatus,
        activeClassroom: classroom,
        page: 0,
        conversations: const [],
      ),
    );

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: 'ACTIVE',
      page: 0,
      size: _pageSize,
      designation: designation,
      staffStatus: staffStatus,
      classroom: classroom,
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
          conversations: _sortedByLatest(conversations),
          isFromCache: false,
          page: 0,
          hasMore: conversations.length >= _pageSize,
        ),
      ),
    );
  }

  /// Clear all active filters and reload conversations.
  /// Only available for [ConversationType.staffDirect].
  Future<void> clearFilters() async {
    if (_conversationType != ConversationType.staffDirect) return;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearDesignation: true,
        clearStaffStatus: true,
        clearClassroom: true,
        page: 0,
        conversations: const [],
      ),
    );

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: 'ACTIVE',
      page: 0,
      size: _pageSize,
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
          conversations: _sortedByLatest(conversations),
          isFromCache: false,
          page: 0,
          hasMore: conversations.length >= _pageSize,
        ),
      ),
    );
  }

  /// Pull-to-refresh: forces a REST API fetch regardless of Firestore state.
  /// Preserves active filters if any are set.
  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearError: true));

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: 'ACTIVE',
      page: 0,
      size: _pageSize,
      designation: state.activeDesignation,
      staffStatus: state.activeStaffStatus,
      classroom: state.activeClassroom,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: failure.message ?? 'Failed to refresh conversations.',
        ),
      ),
      (conversations) => emit(
        ConversationListState.loaded(
          conversationType: _conversationType,
          conversations: _sortedByLatest(conversations),
          isFromCache: false,
          page: 0,
          hasMore: conversations.length >= _pageSize,
        ),
      ),
    );
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
    );
  }

  Future<void> _fallbackToApi() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: 'ACTIVE',
      page: 0,
      size: _pageSize,
      designation: state.activeDesignation,
      staffStatus: state.activeStaffStatus,
      classroom: state.activeClassroom,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to load conversations.',
        ),
      ),
      (conversations) => emit(
        ConversationListState.loaded(
          conversationType: _conversationType,
          conversations: _sortedByLatest(conversations),
          isFromCache: false,
          page: 0,
          hasMore: conversations.length >= _pageSize,
        ),
      ),
    );
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
