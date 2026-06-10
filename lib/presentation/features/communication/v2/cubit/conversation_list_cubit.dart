import 'package:bloc/bloc.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import 'conversation_list_state.dart';

/// Manages the conversation list for a single [ConversationType].
///
/// Instantiate one cubit per type (STAFF_DIRECT, ROOM_CHAT, ADMIN_CHAT).
/// The offline-first pattern mirrors [NewsletterListCubit]:
///   1. Emit cached Isar data immediately for a fast first frame.
///   2. Refresh from API in the background.
///   3. Merge and emit the authoritative result.
class ConversationListCubit extends Cubit<ConversationListState> {
  ConversationListCubit({
    required ConversationType conversationType,
    required GetConversationsEntityUseCase getConversationsUseCase,
    required GetCachedConversationsEntityUseCase getCachedConversationsUseCase,
  })  : _conversationType = conversationType,
        _getConversationsUseCase = getConversationsUseCase,
        _getCachedConversationsUseCase = getCachedConversationsUseCase,
        super(ConversationListState.initial(conversationType: conversationType));

  final ConversationType _conversationType;
  final GetConversationsEntityUseCase _getConversationsUseCase;
  final GetCachedConversationsEntityUseCase _getCachedConversationsUseCase;

  // Tracks the latest refresh call so stale responses are discarded.
  int _refreshRequestId = 0;

  static const int _pageSize = 20;

  /// Load cache then refresh from API. Safe to call on first screen entry.
  Future<void> loadInitial() async {
    final cacheResult = await _getCachedConversationsUseCase(
      type: _conversationType,
    );

    cacheResult.fold(
      (_) {},
      (cached) {
        if (cached.isNotEmpty && !isClosed) {
          emit(
            ConversationListState.loaded(
              conversationType: _conversationType,
              conversations: _sortedByLatest(cached),
              isFromCache: true,
            ),
          );
        }
      },
    );

    await refresh();
  }

  /// Pull-to-refresh: fetch page 0 from API and replace the list.
  Future<void> refresh() async {
    final int requestId = ++_refreshRequestId;

    emit(
      state.copyWith(
        isLoading: state.conversations.isEmpty,
        isRefreshing: true,
        clearError: true,
      ),
    );

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: 'ACTIVE',
      page: 0,
      size: _pageSize,
    );

    if (isClosed || requestId != _refreshRequestId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
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

  /// Append the next page. No-op while already loading or no more pages.
  Future<void> loadNextPage() async {
    if (state.isRefreshing || state.isLoading || !state.hasMore) return;
    if (!state.hasConversations) return;

    final int requestId = _refreshRequestId;
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getConversationsUseCase(
      type: _conversationType,
      status: 'ACTIVE',
      page: state.page + 1,
      size: _pageSize,
    );

    if (isClosed || requestId != _refreshRequestId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to load more conversations.',
        ),
      ),
      (next) => emit(
        state.copyWith(
          conversations: _sortedByLatest([...state.conversations, ...next]),
          isLoading: false,
          isFromCache: false,
          page: state.page + 1,
          hasMore: next.length >= _pageSize,
          clearError: true,
        ),
      ),
    );
  }

  List<ConversationEntity> _sortedByLatest(List<ConversationEntity> conversations) {
    final sorted = List<ConversationEntity>.from(conversations);
    sorted.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.updatedAt;
      final bTime = b.lastMessageAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }
}
