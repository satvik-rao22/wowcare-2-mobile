import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

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

class CommunicationSending extends CommunicationLoaded {
  const CommunicationSending({
    required super.threads,
    required super.activeThreadId,
  });
}
