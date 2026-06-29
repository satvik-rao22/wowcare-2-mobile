import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

class ConversationThreadState extends Equatable {
  const ConversationThreadState({
    required this.conversationCode,
    required this.messages,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    required this.isSending,
    required this.hasOlderMessages,
    this.conversation,
    this.sendError,
    this.errorMessage,
  });

  const ConversationThreadState.initial({required String conversationCode})
      : conversationCode = conversationCode,
        messages = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        isSending = false,
        hasOlderMessages = true,
        conversation = null,
        sendError = null,
        errorMessage = null;

  const ConversationThreadState.loaded({
    required String conversationCode,
    required List<MessageEntity> messages,
    required bool isFromCache,
    bool hasOlderMessages = false,
    ConversationEntity? conversation,
  })  : conversationCode = conversationCode,
        messages = messages,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        isSending = false,
        hasOlderMessages = hasOlderMessages,
        conversation = conversation,
        sendError = null,
        errorMessage = null;

  final String conversationCode;
  final List<MessageEntity> messages;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final bool isSending;
  final bool hasOlderMessages;

  /// Full conversation metadata (participants, type, private mode, etc.).
  /// May be null until the first successful load.
  final ConversationEntity? conversation;

  /// Non-null when the most recent send attempt failed.
  final String? sendError;

  /// Non-null when loading or refresh failed.
  final String? errorMessage;

  bool get hasMessages => messages.isNotEmpty;

  bool get hasPendingMessages =>
      messages.any((m) => m.isPending || m.status.name == 'sending');

  ConversationThreadState copyWith({
    List<MessageEntity>? messages,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    bool? isSending,
    bool? hasOlderMessages,
    ConversationEntity? conversation,
    String? sendError,
    String? errorMessage,
    bool clearSendError = false,
    bool clearError = false,
  }) {
    return ConversationThreadState(
      conversationCode: conversationCode,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      isSending: isSending ?? this.isSending,
      hasOlderMessages: hasOlderMessages ?? this.hasOlderMessages,
      conversation: conversation ?? this.conversation,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        conversationCode,
        messages,
        isLoading,
        isRefreshing,
        isFromCache,
        isSending,
        hasOlderMessages,
        conversation,
        sendError,
        errorMessage,
      ];
}
