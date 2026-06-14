import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
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
  })  : _conversationType = conversationType,
        _watchConversationsUseCase = watchConversationsUseCase,
        _getConversationsUseCase = getConversationsUseCase,
        _getCachedConversationsUseCase = getCachedConversationsUseCase,
        super(ConversationListState.initial(conversationType: conversationType));

  final ConversationType _conversationType;
  final WatchConversationsUseCase _watchConversationsUseCase;
  final GetConversationsEntityUseCase _getConversationsUseCase;
  final GetCachedConversationsEntityUseCase _getCachedConversationsUseCase;

  StreamSubscription<List<ConversationEntity>>? _firestoreSubscription;
  StreamSubscription<String>? _markedReadSubscription;
  bool _firestoreActive = false;

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
    // 1. Emit Isar cache immediately for a fast first frame.
    final cacheResult = await _getCachedConversationsUseCase(
      type: _conversationType,
    );
    cacheResult.fold(
      (_) {},
      (cached) {
        if (cached.isNotEmpty && !isClosed) {
          emit(ConversationListState.loaded(
            conversationType: _conversationType,
            conversations: _sortedByLatest(cached),
            isFromCache: true,
          ));
        }
      },
    );

    // 2. Subscribe to Firestore.
    _firestoreSubscription?.cancel();
    _firestoreSubscription = _watchConversationsUseCase(
      type: _conversationType,
    ).listen(
      (conversations) {
        if (isClosed) return;
        _firestoreActive = true;
        emit(ConversationListState.loaded(
          conversationType: _conversationType,
          conversations: _sortedByLatest(conversations),
          isFromCache: false,
        ));
      },
      onError: (_) {
        if (!_firestoreActive) unawaited(_fallbackToApi());
      },
    );

    // 3. Subscribe to mark-read events so the badge zeroes instantly.
    _markedReadSubscription?.cancel();
    _markedReadSubscription = MessagingEventService
        .instance.onConversationMarkedRead
        .listen((code) => _zeroBadgeLocally(code));
  }

  /// Pull-to-refresh: forces a REST API fetch regardless of Firestore state.
  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearError: true));

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: 'ACTIVE',
      page: 0,
      size: _pageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        errorMessage: failure.message ?? 'Failed to refresh conversations.',
      )),
      (conversations) => emit(ConversationListState.loaded(
        conversationType: _conversationType,
        conversations: _sortedByLatest(conversations),
        isFromCache: false,
        page: 0,
        hasMore: conversations.length >= _pageSize,
      )),
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
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message ?? 'Failed to load conversations.',
      )),
      (conversations) => emit(ConversationListState.loaded(
        conversationType: _conversationType,
        conversations: _sortedByLatest(conversations),
        isFromCache: false,
        page: 0,
        hasMore: conversations.length >= _pageSize,
      )),
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
