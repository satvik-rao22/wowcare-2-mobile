import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

class ConversationListState extends Equatable {
  const ConversationListState({
    required this.conversationType,
    required this.conversations,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    required this.hasMore,
    required this.page,
    this.errorMessage,
  });

  const ConversationListState.initial({required ConversationType conversationType})
      : conversationType = conversationType,
        conversations = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        hasMore = true,
        page = 0,
        errorMessage = null;

  const ConversationListState.loaded({
    required ConversationType conversationType,
    required List<ConversationEntity> conversations,
    required bool isFromCache,
    int page = 0,
    bool hasMore = false,
  })  : conversationType = conversationType,
        conversations = conversations,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        hasMore = hasMore,
        page = page,
        errorMessage = null;

  final ConversationType conversationType;
  final List<ConversationEntity> conversations;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final bool hasMore;
  final int page;
  final String? errorMessage;

  bool get hasConversations => conversations.isNotEmpty;

  ConversationListState copyWith({
    List<ConversationEntity>? conversations,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConversationListState(
      conversationType: conversationType,
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        conversationType,
        conversations,
        isLoading,
        isRefreshing,
        isFromCache,
        hasMore,
        page,
        errorMessage,
      ];
}
