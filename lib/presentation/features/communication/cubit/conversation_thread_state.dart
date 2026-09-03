import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_connection_status.dart';

class ConversationThreadState extends Equatable {
  const ConversationThreadState({
    required this.conversationCode,
    required this.messages,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    required this.isSending,
    required this.hasOlderMessages,
    this.connectionStatus = MessagingConnectionStatus.connecting,
    this.conversation,
    this.sendError,
    this.errorMessage,
    this.successMessage,
  });

  const ConversationThreadState.initial({
    required String conversationCode,
    ConversationEntity? conversation,
  })  : conversationCode = conversationCode,
        messages = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        isSending = false,
        hasOlderMessages = true,
        connectionStatus = MessagingConnectionStatus.connecting,
        conversation = conversation,
        sendError = null,
        errorMessage = null,
        successMessage = null;

  const ConversationThreadState.loaded({
    required String conversationCode,
    required List<MessageEntity> messages,
    required bool isFromCache,
    bool hasOlderMessages = false,
    ConversationEntity? conversation,
    MessagingConnectionStatus connectionStatus =
        MessagingConnectionStatus.connecting,
  })  : conversationCode = conversationCode,
        messages = messages,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        isSending = false,
        hasOlderMessages = hasOlderMessages,
        connectionStatus = connectionStatus,
        conversation = conversation,
        sendError = null,
        errorMessage = null,
        successMessage = null;

  final String conversationCode;
  final List<MessageEntity> messages;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final bool isSending;
  final bool hasOlderMessages;

  /// Health of the realtime (Firestore) message subscription, so the UI can
  /// show a subtle banner when live updates are degraded.
  final MessagingConnectionStatus connectionStatus;

  /// Full conversation metadata (participants, type, private mode, etc.).
  /// May be null until the first successful load.
  final ConversationEntity? conversation;

  /// Non-null when the most recent send attempt failed.
  final String? sendError;

  /// Non-null when loading or refresh failed.
  final String? errorMessage;

  /// Non-null when an operation (e.g., reaction add/remove) succeeded.
  final String? successMessage;

  bool get hasMessages => messages.isNotEmpty;

  bool get hasPendingMessages =>
      messages.any((m) => m.isPending || m.status.name == 'sending');

  ConversationThreadState copyWith({
    String? conversationCode,
    List<MessageEntity>? messages,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    bool? isSending,
    bool? hasOlderMessages,
    MessagingConnectionStatus? connectionStatus,
    ConversationEntity? conversation,
    String? sendError,
    String? errorMessage,
    String? successMessage,
    bool clearSendError = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ConversationThreadState(
      conversationCode: conversationCode ?? this.conversationCode,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      isSending: isSending ?? this.isSending,
      hasOlderMessages: hasOlderMessages ?? this.hasOlderMessages,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      conversation: conversation ?? this.conversation,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
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
        connectionStatus,
        conversation,
        sendError,
        errorMessage,
        successMessage,
      ];
}
