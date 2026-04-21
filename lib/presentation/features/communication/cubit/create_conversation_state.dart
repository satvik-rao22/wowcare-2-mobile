import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';

abstract class CreateConversationState extends Equatable {
  const CreateConversationState();

  @override
  List<Object?> get props => [];
}

class CreateConversationInitial extends CreateConversationState {}

class CreateConversationLoading extends CreateConversationState {}

class CreateConversationSuccess extends CreateConversationState {
  final Conversation conversation;

  const CreateConversationSuccess(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class CreateConversationError extends CreateConversationState {
  final String message;

  const CreateConversationError(this.message);

  @override
  List<Object?> get props => [message];
}
