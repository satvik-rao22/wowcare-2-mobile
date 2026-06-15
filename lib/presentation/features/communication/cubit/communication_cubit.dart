import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/features/communication/entities/conversation.dart';
import '../../../../domain/features/communication/entities/message.dart';
import '../../../../domain/features/communication/usecases/get_conversations_usecase.dart';
import '../../../../domain/features/communication/usecases/get_messages_usecase.dart';
import '../../../../domain/features/communication/usecases/get_cached_conversations_usecase.dart';
import '../../../../domain/features/communication/usecases/get_cached_messages_usecase.dart';
import '../../../../domain/features/communication/usecases/add_reaction_usecase.dart';
import '../../../../domain/features/communication/usecases/send_message_usecase.dart';
import '../../../../domain/features/communication/usecases/edit_message_usecase.dart';
import '../../../../domain/features/communication/usecases/delete_message_usecase.dart';
import '../../../../domain/features/communication/usecases/remove_reaction_legacy_usecase.dart';
import '../../../../domain/features/communication/usecases/clear_cache_usecase.dart';
import 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationsUseCase getConversationsUseCase;
  final GetCachedConversationsUseCase getCachedConversationsUseCase;
  final GetCachedMessagesUseCase getCachedMessagesUseCase;
  final AddReactionUseCase addReactionUseCase;
  final EditMessageUseCase editMessageUseCase;
  final DeleteMessageUseCase deleteMessageUseCase;
  final RemoveReactionLegacyUseCase removeReactionLegacyUseCase;
  final ClearMessagesCacheUseCase clearMessagesCacheUseCase;
  final ClearConversationsCacheUseCase clearConversationsCacheUseCase;

  CommunicationCubit({
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.getConversationsUseCase,
    required this.getCachedConversationsUseCase,
    required this.getCachedMessagesUseCase,
    required this.addReactionUseCase,
    required this.editMessageUseCase,
    required this.deleteMessageUseCase,
    required this.removeReactionLegacyUseCase,
    required this.clearMessagesCacheUseCase,
    required this.clearConversationsCacheUseCase,
  }) : super(CommunicationInitial());

  /// Clears Isar cache for a specific thread's messages.
  Future<void> clearThreadCache(String threadId) async {
    await clearMessagesCacheUseCase(threadId);
  }

  /// Clears the full Isar conversations cache then reloads from API.
  Future<void> refreshConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    await clearConversationsCacheUseCase();
    await loadConversations(type: type, status: status, page: page, size: size);
  }

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
            // Merge into existing map so both tabs keep their own data.
            final currentMap = state is CommunicationConversationsLoaded
                ? (state as CommunicationConversationsLoaded).conversationsByType
                : <String?, List<Conversation>>{};
            final mergedMap = Map<String?, List<Conversation>>.from(currentMap);
            mergedMap[null] = conversations;
            if (type != null) mergedMap[type] = conversations;
            emit(CommunicationConversationsLoaded(mergedMap));
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
        final sorted = List<Conversation>.from(conversations)
          ..sort((a, b) {
            final aTime = a.lastMessageAt ?? a.updatedAt;
            final bTime = b.lastMessageAt ?? b.updatedAt;
            return bTime.compareTo(aTime);
          });
        updatedMap[type] = sorted;

        emit(CommunicationConversationsLoaded(updatedMap));
      },
    );
  }

  /// Sorts messages oldest-first so the ListView (reverse: false) shows the
  /// latest message at the bottom, matching standard chat UX.
  List<Message> _sortByTime(List<Message> messages) {
    final sorted = List<Message>.from(messages);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
  }

  Future<void> loadMessages(String threadId, {String? currentUserId}) async {
    final Map<String, List<Message>> currentThreads =
        state is CommunicationLoaded
        ? (state as CommunicationLoaded).threads
        : {};

    // 1. Try Loading from Isar cache first for faster initial loading.
    //    Pass currentUserId so isSentByMe is re-derived from senderUserCode,
    //    preventing stale/null Isar booleans from flipping the bubble style.
    final cacheResult = await getCachedMessagesUseCase(
      threadId,
      currentUserId: currentUserId,
    );
    cacheResult.fold(
      (_) => null, // Ignore cache errors
      (cachedMessages) {
        if (cachedMessages.isNotEmpty && !isClosed) {
          final newThreads = Map<String, List<Message>>.from(currentThreads);
          newThreads[threadId] = _sortByTime(cachedMessages);
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
    if (!updatedThreads.containsKey(threadId) ||
        updatedThreads[threadId]!.isEmpty) {
      emit(CommunicationLoading());
    }

    // 3. Fetch latest data from remote in the background and update state/cache
    final result = await getMessagesUseCase(
      threadId,
      currentUserId: currentUserId,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // Only show error page if we don't already have cached messages
        final Map<String, List<Message>> finalThreads =
            state is CommunicationLoaded
            ? (state as CommunicationLoaded).threads
            : {};
        if (!finalThreads.containsKey(threadId) ||
            finalThreads[threadId]!.isEmpty) {
          emit(CommunicationError(failure.message ?? 'Unknown error'));
        }
      },
      (messages) {
        final Map<String, List<Message>> latestThreads =
            state is CommunicationLoaded
            ? (state as CommunicationLoaded).threads
            : {};
        final newThreads = Map<String, List<Message>>.from(latestThreads);
        newThreads[threadId] = _sortByTime(messages);
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
    String? senderUserCode,
    List<String> receivers = const [],
  }) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;

    final tempMessage = Message(
      id: threadId, // message id
      code: '$senderUserCode', // temp code for optimistic UI
      text: text,
      isSentByMe: true,
      senderUserCode: senderUserCode,
      time: DateTime.now(),
      attachments: attachments,
      quotedMessageId: quotedMessageId,
      senderName: senderName,
      receivers: receivers,
    );

    // Optimistic update — append then re-sort so the new bubble lands at bottom
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    updatedThreads[threadId] = _sortByTime(
      List<Message>.from(updatedThreads[threadId] ?? [])..add(tempMessage),
    );

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
      },
    );
  }

  Future<void> addReaction(
    String threadId,
    String messageCode,
    String emoji,
  ) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;

    // Optimistically update the UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        final newReactions = Map<String, String>.from(m.reactions);
        newReactions['me'] = emoji;
        return Message(
          id: m.id,
          code: m.code,
          text: m.text,
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          editedAt: m.editedAt,
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

    final result = await addReactionUseCase(threadId, messageCode, emoji);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(currentState.copyWith(threads: originalThreads));
      },
      (_) {},
    );
  }

  Future<void> editMessage(
    String threadId,
    String messageCode,
    String content,
  ) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;

    // Optimistically update the UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        return Message(
          id: m.id,
          code: m.code,
          text: content,
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          editedAt: DateTime.now(),
          deliveredTo: m.deliveredTo,
          readBy: m.readBy,
          reactions: m.reactions,
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

    final result = await editMessageUseCase(messageCode, content);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(currentState.copyWith(threads: originalThreads));
      },
      (_) {},
    );
  }

  Future<void> deleteMessage(
    String threadId,
    String messageCode,
  ) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;

    // Optimistically replace with deleted placeholder in the UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        return Message(
          id: m.id,
          code: m.code,
          text: '🚫 This Message Has Been Deleted',
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          editedAt: m.editedAt,
          deliveredTo: m.deliveredTo,
          readBy: m.readBy,
          reactions: const {},
          quotedMessageId: m.quotedMessageId,
          attachments: const [],
          senderName: m.senderName,
          receivers: m.receivers,
        );
      }
      return m;
    }).toList();

    updatedThreads[threadId] = updatedMessages;
    emit(currentState.copyWith(threads: updatedThreads));

    final result = await deleteMessageUseCase(messageCode);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(currentState.copyWith(threads: originalThreads));
      },
      (_) {},
    );
  }

  Future<void> removeReaction(
    String threadId,
    String messageCode,
    String emoji,
  ) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;

    // Optimistically remove reaction from UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        final newReactions = Map<String, String>.from(m.reactions)
          ..remove('me');
        return Message(
          id: m.id,
          code: m.code,
          text: m.text,
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          editedAt: m.editedAt,
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

    final result = await removeReactionLegacyUseCase(messageCode: messageCode, emoji: emoji);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(currentState.copyWith(threads: originalThreads));
      },
      (_) {},
    );
  }
}
