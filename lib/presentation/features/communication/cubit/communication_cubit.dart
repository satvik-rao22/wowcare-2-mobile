import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/usecases/get_messages_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_usecase.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;

  CommunicationCubit({
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
  }) : super(CommunicationInitial());

  Future<void> loadMessages(String threadId) async {
    final Map<String, List<Message>> currentThreads =
        state is CommunicationLoaded ? (state as CommunicationLoaded).threads : {};

    if (!currentThreads.containsKey(threadId)) {
      emit(CommunicationLoading());
    }

    final result = await getMessagesUseCase(threadId);
    result.fold(
      (failure) => emit(CommunicationError(failure.message ?? 'Unknown error')),
      (messages) {
        final newThreads = Map<String, List<Message>>.from(currentThreads);
        newThreads[threadId] = messages;
        emit(CommunicationLoaded(threads: newThreads, activeThreadId: threadId));
      },
    );
  }

  Future<void> sendMessage(
    String threadId,
    String text, {
    List<ChatAttachment> attachments = const [],
    String? quotedMessageId,
    String? senderName,
    List<String> receivers = const [],
  }) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;

    final tempMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isSentByMe: true,
      time: DateTime.now(),
      attachments: attachments,
      quotedMessageId: quotedMessageId,
      senderName: senderName,
      receivers: receivers,
    );

    // Optimistic update for the specific thread
    final updatedThreads = Map<String, List<Message>>.from(currentState.threads);
    updatedThreads[threadId] = List<Message>.from(updatedThreads[threadId] ?? [])
      ..add(tempMessage);

    emit(CommunicationSending(
      threads: updatedThreads,
      activeThreadId: threadId,
    ));

    final result = await sendMessageUseCase(threadId, tempMessage);

    result.fold(
      (failure) {
        // Rollback on failure
        final rollbackThreads = Map<String, List<Message>>.from(currentState.threads);
        emit(CommunicationError(failure.message ?? 'Unknown error'));
        emit(CommunicationLoaded(
          threads: rollbackThreads,
          activeThreadId: threadId,
        ));
      },
      (sentMessage) {
        // Update state with confirmed message
        final confirmedThreads = Map<String, List<Message>>.from(updatedThreads);
        final threadMessages = List<Message>.from(confirmedThreads[threadId]!);
        final idx = threadMessages.indexWhere((m) => m.id == tempMessage.id);
        if (idx != -1) {
          threadMessages[idx] = sentMessage;
        }
        confirmedThreads[threadId] = threadMessages;
        
        emit(CommunicationLoaded(
          threads: confirmedThreads,
          activeThreadId: threadId,
        ));

        // --- SIMULATION LOGIC (Moves from UI to Cubit) ---
        
        // 1. Delivered Status Update after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (state is! CommunicationLoaded) return;
          final s = state as CommunicationLoaded;
          final t = Map<String, List<Message>>.from(s.threads);
          final ms = List<Message>.from(t[threadId] ?? []);
          final i = ms.indexWhere((m) => m.id == sentMessage.id);
          
          if (i != -1) {
            ms[i] = Message(
              id: sentMessage.id,
              text: sentMessage.text,
              isSentByMe: true,
              time: sentMessage.time,
              deliveredAt: DateTime.now(),
              readAt: sentMessage.readAt,
              attachments: sentMessage.attachments,
              quotedMessageId: sentMessage.quotedMessageId,
              senderName: sentMessage.senderName,
              receivers: sentMessage.receivers,
              reactions: sentMessage.reactions,
            );
            t[threadId] = ms;
            emit(s.copyWith(threads: t));
          }
        });

        // 2. Read Status Update after 7 seconds
        Future.delayed(const Duration(seconds: 7), () {
          if (state is! CommunicationLoaded) return;
          final s = state as CommunicationLoaded;
          final t = Map<String, List<Message>>.from(s.threads);
          final ms = List<Message>.from(t[threadId] ?? []);
          final i = ms.indexWhere((m) => m.id == sentMessage.id);
          
          if (i != -1) {
            ms[i] = Message(
              id: sentMessage.id,
              text: sentMessage.text,
              isSentByMe: true,
              time: sentMessage.time,
              deliveredAt: ms[i].deliveredAt,
              readAt: DateTime.now(),
              attachments: sentMessage.attachments,
              quotedMessageId: sentMessage.quotedMessageId,
              senderName: sentMessage.senderName,
              receivers: sentMessage.receivers,
              reactions: sentMessage.reactions,
            );
            t[threadId] = ms;
            emit(s.copyWith(threads: t));
          }
        });
      },
    );
  }

  void addReaction(String threadId, String messageId, String emoji) {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;

    final updatedThreads = Map<String, List<Message>>.from(currentState.threads);
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);
    
    final updatedMessages = threadMessages.map((m) {
      if (m.id == messageId) {
        final newReactions = Map<String, String>.from(m.reactions);
        newReactions['me'] = emoji; 
        return Message(
          id: m.id,
          text: m.text,
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          deliveredTo: m.deliveredTo,
          readBy: m.readBy,
          reactions: newReactions,
          quotedMessageId: m.quotedMessageId,
          attachments: m.attachments,
          senderName: m.senderName,
          receivers: m.receivers,
        );
      }
      return m;
    }).toList();

    updatedThreads[threadId] = updatedMessages;
    emit(currentState.copyWith(threads: updatedThreads));
  }
}
