import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/features/communication/entities/conversation.dart';
import '../../../../domain/features/communication/entities/message.dart';
import '../../../../domain/features/communication/usecases/get_conversations_usecase.dart';
import '../../../../domain/features/communication/usecases/get_messages_usecase.dart';
import '../../../../domain/features/communication/usecases/get_cached_conversations_usecase.dart';
import '../../../../domain/features/communication/usecases/get_cached_messages_usecase.dart';
import '../../../../domain/features/communication/usecases/add_reaction_usecase.dart';
import '../../../../domain/features/communication/usecases/send_message_usecase.dart';
import 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationsUseCase getConversationsUseCase;
  final GetCachedConversationsUseCase getCachedConversationsUseCase;
  final GetCachedMessagesUseCase getCachedMessagesUseCase;
  final AddReactionUseCase addReactionUseCase;
  final List<Timer> _statusTimers = [];

  CommunicationCubit({
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.getConversationsUseCase,
    required this.getCachedConversationsUseCase,
    required this.getCachedMessagesUseCase,
    required this.addReactionUseCase,
  }) : super(CommunicationInitial());

  Future<void> loadConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    // 1. Try Loading from cache first for better UX
    if (page == 0) {
      final cacheResult = await getCachedConversationsUseCase();
      cacheResult.fold(
        (_) => null, // Ignore cache errors
        (conversations) {
          if (conversations.isNotEmpty && !isClosed) {
            emit(
              CommunicationConversationsLoaded({
                null: conversations,
                if (type != null) type: conversations,
              }),
            );
          }
        },
      );
    }

    // 2. Only show loading if we don't have cached data (or if not on first page)
    if (state is! CommunicationConversationsLoaded) {
      emit(CommunicationConversationsLoading());
    }

    // 3. Fetch fresh data from remote
    final result = await getConversationsUseCase(
      type: type,
      status: status,
      page: page,
      size: size,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // If we already have cached data, don't show full error screen, maybe just a toast?
        // For now, let's stick to the failure if cache is empty.
        if (state is! CommunicationConversationsLoaded) {
          emit(CommunicationError(failure.message ?? 'Unknown error'));
        }
      },
      (conversations) {
        final currentMap = state is CommunicationConversationsLoaded
            ? (state as CommunicationConversationsLoaded).conversationsByType
            : <String?, List<Conversation>>{};

        final updatedMap = Map<String?, List<Conversation>>.from(currentMap);
        updatedMap[type] = conversations;

        emit(CommunicationConversationsLoaded(updatedMap));
      },
    );
  }

  Future<void> loadMessages(String threadId, {String? currentUserId}) async {
    final Map<String, List<Message>> currentThreads =
        state is CommunicationLoaded
        ? (state as CommunicationLoaded).threads
        : {};

    // 1. Try Loading from Isar cache first for faster initial loading
    final cacheResult = await getCachedMessagesUseCase(threadId);
    cacheResult.fold(
      (_) => null, // Ignore cache errors
      (cachedMessages) {
        if (cachedMessages.isNotEmpty && !isClosed) {
          final newThreads = Map<String, List<Message>>.from(currentThreads);
          newThreads[threadId] = cachedMessages;
          emit(
            CommunicationLoaded(threads: newThreads, activeThreadId: threadId),
          );
        }
      },
    );

    // 2. Only emit Loading if we have absolutely no cached messages in the state
    final Map<String, List<Message>> updatedThreads =
        state is CommunicationLoaded
        ? (state as CommunicationLoaded).threads
        : {};
    if (!updatedThreads.containsKey(threadId) || updatedThreads[threadId]!.isEmpty) {
      emit(CommunicationLoading());
    }

    // 3. Fetch latest data from remote in the background and update state/cache
    final result = await getMessagesUseCase(threadId, currentUserId: currentUserId);
    if (isClosed) return;

    result.fold(
      (failure) {
        // Only show error page if we don't already have cached messages
        final Map<String, List<Message>> finalThreads =
            state is CommunicationLoaded
            ? (state as CommunicationLoaded).threads
            : {};
        if (!finalThreads.containsKey(threadId) || finalThreads[threadId]!.isEmpty) {
          emit(CommunicationError(failure.message ?? 'Unknown error'));
        }
      },
      (messages) {
        final Map<String, List<Message>> latestThreads =
            state is CommunicationLoaded
            ? (state as CommunicationLoaded).threads
            : {};
        final newThreads = Map<String, List<Message>>.from(latestThreads);
        newThreads[threadId] = messages;
        emit(
          CommunicationLoaded(threads: newThreads, activeThreadId: threadId),
        );
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
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    updatedThreads[threadId] = List<Message>.from(
      updatedThreads[threadId] ?? [],
    )..add(tempMessage);

    emit(
      CommunicationSending(threads: updatedThreads, activeThreadId: threadId),
    );

    final result = await sendMessageUseCase(threadId, tempMessage);
    if (isClosed) return;

    result.fold(
      (failure) {
        // Rollback on failure
        final rollbackThreads = Map<String, List<Message>>.from(
          currentState.threads,
        );
        emit(CommunicationError(failure.message ?? 'Unknown error'));
        emit(
          CommunicationLoaded(
            threads: rollbackThreads,
            activeThreadId: threadId,
          ),
        );
      },
      (sentMessage) {
        // Update state with confirmed message
        final confirmedThreads = Map<String, List<Message>>.from(
          updatedThreads,
        );
        final threadMessages = List<Message>.from(confirmedThreads[threadId]!);
        final idx = threadMessages.indexWhere((m) => m.id == tempMessage.id);
        if (idx != -1) {
          threadMessages[idx] = sentMessage;
        }
        confirmedThreads[threadId] = threadMessages;

        emit(
          CommunicationLoaded(
            threads: confirmedThreads,
            activeThreadId: threadId,
          ),
        );

        // --- SIMULATION LOGIC (Moves from UI to Cubit) ---

        // 1. Delivered Status Update after 2 seconds
        _statusTimers.add(
          Timer(const Duration(seconds: 2), () {
            if (isClosed || state is! CommunicationLoaded) return;
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
          }),
        );

        // 2. Read Status Update after 7 seconds
        _statusTimers.add(
          Timer(const Duration(seconds: 7), () {
            if (isClosed || state is! CommunicationLoaded) return;
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
          }),
        );
      },
    );
  }

  @override
  Future<void> close() {
    for (final timer in _statusTimers) {
      timer.cancel();
    }
    _statusTimers.clear();
    return super.close();
  }

  Future<void> addReaction(
    String threadId,
    String messageId,
    String emoji,
  ) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;

    // Optimistically update the UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
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

    // Persist reaction in the background
    await addReactionUseCase(threadId, messageId, emoji);
  }
}
