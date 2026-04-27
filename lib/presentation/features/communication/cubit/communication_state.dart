import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

import '../../../../domain/features/communication/entities/conversation.dart';

abstract class CommunicationState extends Equatable {
  const CommunicationState();

  @override
  List<Object?> get props => [];
}

class CommunicationInitial extends CommunicationState {}

class CommunicationLoading extends CommunicationState {}

class CommunicationLoaded extends CommunicationState {
  final Map<String, List<Message>> threads;
  final String activeThreadId;

  const CommunicationLoaded({
    required this.threads,
    required this.activeThreadId,
  });

  List<Message> get messages => threads[activeThreadId] ?? [];

  @override
  List<Object?> get props => [threads, activeThreadId];

  CommunicationLoaded copyWith({
    Map<String, List<Message>>? threads,
    String? activeThreadId,
  }) {
    return CommunicationLoaded(
      threads: threads ?? this.threads,
      activeThreadId: activeThreadId ?? this.activeThreadId,
    );
  }
}

class CommunicationError extends CommunicationState {
  final String message;

  const CommunicationError(this.message);

  @override
  List<Object?> get props => [message];
}

class CommunicationConversationsLoading extends CommunicationState {}

class CommunicationConversationsLoaded extends CommunicationState {
  final Map<String?, List<Conversation>> conversationsByType;

  const CommunicationConversationsLoaded(this.conversationsByType);

  List<Conversation> get conversations => conversationsByType[null] ?? [];
  List<Conversation> getConversations(String? type) =>
      conversationsByType[type] ?? [];

  @override
  List<Object?> get props => [conversationsByType];

  CommunicationConversationsLoaded copyWith({
    Map<String?, List<Conversation>>? conversationsByType,
  }) {
    return CommunicationConversationsLoaded(
      conversationsByType ?? this.conversationsByType,
    );
  }
}

class CommunicationSending extends CommunicationLoaded {
  const CommunicationSending({
    required super.threads,
    required super.activeThreadId,
  });
}
