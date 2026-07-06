import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart'
    show ChatAttachment;
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_attachment_uploader.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/message_entity_mapper.dart';
import 'package:wowcare/domain/features/communication/usecases/add_reaction_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_attachment_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/edit_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_messages_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/mark_conversation_read_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/remove_reaction_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_messages_usecase.dart';
import 'conversation_thread_state.dart';

/// Manages the full message thread for a single conversation.
///
/// Works for STAFF_DIRECT, ROOM_CHAT, and ADMIN_CHAT — behaviour differences
/// are solely in the data returned by the backend; the cubit is type-agnostic.
///
/// Offline-first pattern:
///   1. Emit Isar cache immediately for a fast first frame.
///   2. Refresh from API in the background and replace.
///   3. Optimistic send: inject a [MessageStatus.pending] message, replace on
///      confirmation or mark [MessageStatus.failed] on error.
class ConversationThreadCubit extends Cubit<ConversationThreadState> {
  ConversationThreadCubit({
    required String conversationCode,
    required String currentUserCode,
    required WatchMessagesUseCase watchMessagesUseCase,
    required GetMessagesEntityUseCase getMessagesUseCase,
    required SendMessageEntityUseCase sendMessageUseCase,
    required EditMessageEntityUseCase editMessageUseCase,
    required DeleteMessageEntityUseCase deleteMessageUseCase,
    required DeleteAttachmentEntityUseCase deleteAttachmentUseCase,
    required AddReactionEntityUseCase addReactionUseCase,
    required RemoveReactionUseCase removeReactionUseCase,
    required MarkConversationReadUseCase markConversationReadUseCase,
    required ChatAttachmentUploader attachmentUploader,
    Duration markReadDebounceDuration = const Duration(seconds: 2),
    bool isDraft = false,
    Future<ConversationEntity?> Function()? onResolveConversation,
  }) : _currentUserCode = currentUserCode,
       _isDraft = isDraft,
       _onResolveConversation = onResolveConversation,
       _watchMessagesUseCase = watchMessagesUseCase,
       _getMessagesUseCase = getMessagesUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _editMessageUseCase = editMessageUseCase,
       _deleteMessageUseCase = deleteMessageUseCase,
       _deleteAttachmentUseCase = deleteAttachmentUseCase,
       _addReactionUseCase = addReactionUseCase,
       _removeReactionUseCase = removeReactionUseCase,
       _markConversationReadUseCase = markConversationReadUseCase,
       _attachmentUploader = attachmentUploader,
       _markReadDebounceDuration = markReadDebounceDuration,
       super(
         ConversationThreadState.initial(conversationCode: conversationCode),
       );

  final String _currentUserCode;

  /// True until a draft conversation (e.g. a classroom chat that doesn't exist
  /// yet) has been created on the server. While draft, realtime/API loads are
  /// skipped (an empty conversationCode would 403) and the thread shows the
  /// composer over an empty list — the conversation is created lazily on the
  /// first send via [_onResolveConversation], mirroring the web client.
  bool _isDraft;

  /// Creates (or resolves) the real conversation for a draft thread on first
  /// send. Returns the now-real [ConversationEntity], or null on failure.
  final Future<ConversationEntity?> Function()? _onResolveConversation;

  final WatchMessagesUseCase _watchMessagesUseCase;
  final GetMessagesEntityUseCase _getMessagesUseCase;
  final SendMessageEntityUseCase _sendMessageUseCase;
  final EditMessageEntityUseCase _editMessageUseCase;
  final DeleteMessageEntityUseCase _deleteMessageUseCase;
  final DeleteAttachmentEntityUseCase _deleteAttachmentUseCase;
  final ChatAttachmentUploader _attachmentUploader;
  final AddReactionEntityUseCase _addReactionUseCase;
  final RemoveReactionUseCase _removeReactionUseCase;
  final MarkConversationReadUseCase _markConversationReadUseCase;

  StreamSubscription<List<MessageEntity>>? _messagesSubscription;
  bool _firestoreActive = false;

  int _refreshRequestId = 0;
  static const int _pageSize = 50;

  /// Debounces [_markRead] so a burst of Firestore snapshot emissions (e.g.
  /// several participants editing/reacting in quick succession) collapses
  /// into a single `markConversationRead` call instead of one per emission.
  /// Overridable via the constructor for tests; production callers use the
  /// 2-second default.
  Timer? _markReadDebounce;
  final Duration _markReadDebounceDuration;

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    // Flush rather than drop: if the user leaves the thread mid-debounce,
    // the pending read should still be committed so the unread badge
    // reflects what they actually saw.
    if (_markReadDebounce?.isActive ?? false) {
      _markReadDebounce!.cancel();
      unawaited(_markRead());
    }
    return super.close();
  }

  // ─── Firestore realtime stream ───────────────────────────────────────────────

  /// Subscribe to Firestore message stream for this conversation.
  ///
  /// Keeps the message list live without manual refreshes. Pending/failed
  /// optimistic messages sent by this device are preserved — they won't appear
  /// in Firestore until the backend confirms them.
  ///
  /// Falls back silently to the API path ([loadMessages]) when Firestore has no
  /// messages subcollection or returns an error.
  void startWatchingMessages() {
    // Draft thread (conversation not created yet): nothing to watch — show the
    // composer over an empty list. The realtime listener attaches once the
    // first send creates the real conversation (see [_resolveDraftConversation]).
    if (_isDraft) {
      _emitDraftEmpty();
      return;
    }

    _messagesSubscription?.cancel();
    // Use this conversation's own org/school rather than the session's
    // currently-active one — a stale/mismatched active school (multi-school
    // parent/admin, or a recent switch) otherwise builds a Firestore path
    // that doesn't correspond to where this conversation's messages
    // actually live, surfacing as permission-denied rather than just empty.
    _messagesSubscription =
        _watchMessagesUseCase(
          conversationCode: state.conversationCode,
          organizationCode: state.conversation?.organizationCode,
          schoolCode: state.conversation?.schoolCode,
        ).listen(
          (fresh) {
            if (isClosed) return;
            _firestoreActive = true;
            final latest = fresh.isNotEmpty ? fresh.last : null;
            final merged = _mergePendingMessages(_sortedOldestFirst(fresh));
            final int debugPrevCount = state.messages.length;
            emit(
              ConversationThreadState.loaded(
                conversationCode: state.conversationCode,
                messages: merged,
                isFromCache: false,
                hasOlderMessages: state.hasOlderMessages,
                conversation: state.conversation,
              ),
            );
            _scheduleMarkRead();
          },
          onError: (error) {
            // Firestore messages subcollection unavailable — load via API once.
            if (!_firestoreActive) unawaited(loadMessages());
          },
        );
  }

  /// Emits a loaded-but-empty state for a draft thread so the UI shows the
  /// composer over an empty "say hello" list instead of a shimmer or error.
  void _emitDraftEmpty() {
    emit(
      ConversationThreadState.loaded(
        conversationCode: state.conversationCode,
        messages: const [],
        isFromCache: false,
        hasOlderMessages: false,
        conversation: state.conversation,
      ),
    );
  }

  /// Lazily creates the real conversation for a draft thread (first send),
  /// mirroring the web client's create-on-first-message flow. On success the
  /// state is rebound to the real conversationCode + conversation and the
  /// realtime listener is attached. Returns false (and surfaces a sendError)
  /// when creation fails, so the caller aborts the send.
  Future<bool> _resolveDraftConversation() async {
    final resolver = _onResolveConversation;
    if (resolver == null) {
      _isDraft = false;
      return true;
    }
    final conversation = await resolver();
    if (isClosed) return false;
    if (conversation == null || conversation.code.isEmpty) {
      emit(
        state.copyWith(
          isSending: false,
          sendError: 'Could not start the chat. Please try again.',
        ),
      );
      return false;
    }
    _isDraft = false;
    emit(
      state.copyWith(
        conversationCode: conversation.code,
        conversation: conversation,
      ),
    );
    // Attach realtime now that a real conversation exists.
    startWatchingMessages();
    return true;
  }

  // ─── Load / Refresh ─────────────────────────────────────────────────────────

  /// Load messages from API. Used on first entry and as Firestore fallback.
  Future<void> loadMessages() async {
    if (_isDraft) {
      _emitDraftEmpty();
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getMessagesUseCase(
      conversationCode: state.conversationCode,
      size: _pageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to load messages.',
        ),
      ),
      (messages) {
        final sorted = _sortedOldestFirst(messages);
        emit(
          ConversationThreadState.loaded(
            conversationCode: state.conversationCode,
            messages: sorted,
            isFromCache: false,
            hasOlderMessages: messages.length >= _pageSize,
            conversation: state.conversation,
          ),
        );
        _scheduleMarkRead();
      },
    );
  }

  /// Pull-to-refresh: force a fresh API fetch and replace the list.
  Future<void> refreshMessages() async {
    final int requestId = ++_refreshRequestId;
    emit(state.copyWith(isRefreshing: true, clearError: true));

    final result = await _getMessagesUseCase(
      conversationCode: state.conversationCode,
      size: _pageSize,
    );

    if (isClosed || requestId != _refreshRequestId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: failure.message ?? 'Failed to refresh messages.',
        ),
      ),
      (messages) {
        final sorted = _sortedOldestFirst(messages);
        emit(
          ConversationThreadState.loaded(
            conversationCode: state.conversationCode,
            messages: _mergePendingMessages(sorted),
            isFromCache: false,
            hasOlderMessages: messages.length >= _pageSize,
            conversation: state.conversation,
          ),
        );
        _scheduleMarkRead();
      },
    );
  }

  /// Paginate backwards: load messages older than the earliest in the list.
  Future<void> loadOlderMessages() async {
    if (!state.hasOlderMessages || state.isLoading || state.isRefreshing)
      return;
    if (!state.hasMessages) return;

    final int requestId = _refreshRequestId;
    emit(state.copyWith(isLoading: true, clearError: true));

    final oldest = state.messages.first;
    final result = await _getMessagesUseCase(
      conversationCode: state.conversationCode,
      beforeMessageCode: oldest.code,
      size: _pageSize,
    );

    if (isClosed || requestId != _refreshRequestId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to load older messages.',
        ),
      ),
      (older) => emit(
        state.copyWith(
          messages: [..._sortedOldestFirst(older), ...state.messages],
          isLoading: false,
          hasOlderMessages: older.length >= _pageSize,
          clearError: true,
        ),
      ),
    );
  }

  // ─── Send ────────────────────────────────────────────────────────────────────

  /// Send a message with optimistic UI.
  ///
  /// Immediately inserts a [MessageStatus.pending] placeholder — including
  /// local attachment previews — so the bubble appears at the bottom without
  /// waiting for upload or the backend round-trip. Replaces it with the
  /// confirmed message on success, or marks it [MessageStatus.failed] so the
  /// user can retry.
  ///
  /// [attachments] are uploaded here (session → presign → S3 → complete →
  /// register, via the same [ChatAttachmentUploader] legacy messaging uses)
  /// before the message is sent. All-or-nothing: if any attachment fails to
  /// upload, the send is aborted entirely — no partial/text-only message is
  /// sent, and the failure is surfaced via [ConversationThreadState.sendError]
  /// so the caller can retry without losing the picked files.
  Future<void> sendMessage({
    required String text,
    required String senderCode,
    required String senderName,
    required ParticipantRole senderRole,
    required String organizationCode,
    required String schoolCode,
    List<ChatAttachment> attachments = const [],
    bool isPrivate = false,
    String? threadParentCode,
  }) async {
    // Draft thread: create the real conversation before sending (web parity).
    if (_isDraft) {
      final resolved = await _resolveDraftConversation();
      if (!resolved) return;
    }

    final tempCode = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    AttachmentEntity toOptimisticEntity(ChatAttachment a) =>
        mapChatAttachmentToAttachmentEntity(
          a,
          messageCode: tempCode,
          conversationCode: state.conversationCode,
          uploadedBy: senderCode,
        );

    // For a guardian-sent private message, set privateParentUserCode to the
    // sender's own code. This ensures VisibilityHelper.canViewMessage() returns
    // true for the sender during the optimistic phase (before the backend
    // confirms the message and Firestore delivers it with the real value set).
    final optimistic = MessageEntity(
      id: tempCode,
      code: tempCode,
      conversationCode: state.conversationCode,
      senderCode: senderCode,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
      messageType: MessageType.text,
      status: MessageStatus.pending,
      sentAt: DateTime.now(),
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      isPrivate: isPrivate,
      privateParentUserCode: isPrivate ? senderCode : null,
      threadParentCode: threadParentCode,
      localTempCode: tempCode,
      attachments: attachments.map(toOptimisticEntity).toList(),
    );

    // Show immediately — never wait for upload or the network round-trip.
    emit(
      state.copyWith(
        messages: [...state.messages, optimistic],
        isSending: true,
        clearSendError: true,
      ),
    );

    // Upload any attachments that aren't already uploaded, mirroring
    // CommunicationCubit.sendMessage's exact pipeline via the same shared
    // uploader. Parallelised the same way legacy does (Future.wait); if any
    // attachment fails, abort the send — no partial message is created.
    List<ChatAttachment> uploadedAttachments = attachments;
    if (attachments.any((a) => !a.isUploaded)) {
      try {
        uploadedAttachments = await Future.wait(
          attachments.map(
            (a) => _attachmentUploader.upload(
              conversationCode: state.conversationCode,
              attachment: a,
            ),
          ),
        );
      } catch (e) {
        if (isClosed) return;
        final failed = _replaceMessage(
          state.messages,
          tempCode,
          optimistic.copyWith(status: MessageStatus.failed),
        );
        emit(
          state.copyWith(
            messages: failed,
            isSending: false,
            sendError: 'Failed to upload attachment: $e',
          ),
        );
        return;
      }
    }

    final attachmentIds = uploadedAttachments
        .map((a) => a.attachmentId)
        .whereType<int>()
        .toList();
    final uploadedOptimisticAttachments = uploadedAttachments
        .map(toOptimisticEntity)
        .toList();

    final result = await _sendMessageUseCase(
      conversationCode: state.conversationCode,
      text: text,
      attachmentIds: attachmentIds,
      isPrivate: isPrivate,
      threadParentCode: threadParentCode,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        final failed = _replaceMessage(
          state.messages,
          tempCode,
          optimistic.copyWith(
            status: MessageStatus.failed,
            attachments: uploadedOptimisticAttachments,
          ),
        );
        emit(
          state.copyWith(
            messages: failed,
            isSending: false,
            sendError: failure.message ?? 'Failed to send message.',
          ),
        );
      },
      (confirmed) {
        // The create-message response doesn't echo back resolved attachment
        // objects yet (the document is still processing asynchronously) —
        // keep showing the already-uploaded attachment data instead of
        // letting it disappear the instant the optimistic message is
        // replaced. Mirrors CommunicationRemoteDataSourceImpl.sendMessage's
        // fallback; applied here because this contract only sends
        // attachmentIds, leaving the datasource nothing to fall back to.
        final finalMessage = confirmed.attachments.isNotEmpty
            ? confirmed
            : confirmed.copyWith(attachments: uploadedOptimisticAttachments);
        final updated = _replaceMessage(state.messages, tempCode, finalMessage);
        emit(
          state.copyWith(
            messages: updated,
            isSending: false,
            clearSendError: true,
          ),
        );
      },
    );
  }

  // ─── Edit ────────────────────────────────────────────────────────────────────

  Future<void> editMessage({
    required String messageCode,
    required String newText,
  }) async {
    final target = state.messages.firstWhere(
      (m) => m.code == messageCode,
      orElse: () => throw StateError('Message not found'),
    );
    if (target.senderCode != _currentUserCode) {
      emit(
        state.copyWith(
          errorMessage: const AuthorizationFailure(
            'You can only edit your own messages.',
          ).message,
        ),
      );
      return;
    }

    // Optimistic update
    final optimistic = state.messages.map((m) {
      if (m.code != messageCode) return m;
      return m.copyWithText(newText);
    }).toList();
    emit(state.copyWith(messages: optimistic));

    final result = await _editMessageUseCase(
      messageCode: messageCode,
      newText: newText,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        // Roll back
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Failed to edit message.',
          ),
        );
        unawaited(refreshMessages());
      },
      (confirmed) {
        final updated = _replaceMessage(state.messages, messageCode, confirmed);
        emit(state.copyWith(messages: updated));
      },
    );
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteMessage(String messageCode) async {
    final target = state.messages.firstWhere(
      (m) => m.code == messageCode,
      orElse: () => throw StateError('Message not found'),
    );
    if (target.senderCode != _currentUserCode) {
      emit(
        state.copyWith(
          errorMessage: const AuthorizationFailure(
            'You can only delete your own messages.',
          ).message,
        ),
      );
      return;
    }

    // Optimistic: mark deleted locally
    final optimistic = state.messages.map((m) {
      if (m.code != messageCode) return m;
      return m.copyWithDeleted();
    }).toList();
    emit(state.copyWith(messages: optimistic));

    final result = await _deleteMessageUseCase(messageCode);

    if (isClosed) return;

    result.fold((failure) {
      emit(
        state.copyWith(
          errorMessage: failure.message ?? 'Failed to delete message.',
        ),
      );
      unawaited(refreshMessages());
    }, (_) {});
  }

  // ─── Attachments ─────────────────────────────────────────────────────────────

  /// Removes a single attachment from a message without deleting the
  /// message itself — [attachmentId] is the messaging-service id assigned
  /// when the attachment was registered, not the document-service asset
  /// code. Mirrors legacy `CommunicationCubit.deleteAttachment`'s
  /// optimistic-update + rollback pattern.
  Future<void> deleteAttachment({
    required String messageCode,
    required int attachmentId,
  }) async {
    final originalMessages = state.messages;

    final optimistic = state.messages.map((m) {
      if (m.code != messageCode) return m;
      return m.copyWith(
        attachments: m.attachments
            .where((a) => a.attachmentId != attachmentId)
            .toList(),
      );
    }).toList();
    emit(state.copyWith(messages: optimistic));

    final result = await _deleteAttachmentUseCase(
      messageCode: messageCode,
      attachmentId: attachmentId,
    );

    if (isClosed) return;

    result.fold((failure) {
      emit(
        state.copyWith(
          messages: originalMessages,
          errorMessage: failure.message ?? 'Failed to delete attachment.',
        ),
      );
    }, (_) {});
  }

  // ─── Reactions ───────────────────────────────────────────────────────────────

  Future<void> addReaction({
    required String messageCode,
    required String emoji,
    required String currentUserCode,
  }) async {
    final optimistic = _applyReaction(
      state.messages,
      messageCode,
      currentUserCode,
      emoji,
    );
    emit(state.copyWith(messages: optimistic));

    final result = await _addReactionUseCase(
      messageCode: messageCode,
      emoji: emoji,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Failed to add reaction.',
          ),
        );
        unawaited(refreshMessages());
      },
      (_) {
        emit(
          state.copyWith(successMessage: 'Reaction added', clearSuccess: false),
        );
      },
    );
  }

  Future<void> removeReaction({
    required String messageCode,
    required String emoji,
    required String currentUserCode,
  }) async {
    if (currentUserCode != _currentUserCode) {
      emit(
        state.copyWith(
          errorMessage: const AuthorizationFailure(
            'You can only remove your own reactions.',
          ).message,
        ),
      );
      return;
    }

    final optimistic = _removeReactionLocally(
      state.messages,
      messageCode,
      currentUserCode,
    );
    emit(state.copyWith(messages: optimistic));

    final result = await _removeReactionUseCase(
      messageCode: messageCode,
      emoji: emoji,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Failed to remove reaction.',
          ),
        );
        unawaited(refreshMessages());
      },
      (_) {
        emit(
          state.copyWith(
            successMessage: 'Reaction removed',
            clearSuccess: false,
          ),
        );
      },
    );
  }

  // ─── Mark read ───────────────────────────────────────────────────────────────

  Future<void> markConversationRead() async {
    await _markRead();
  }

  void clearSuccess() {
    if (!isClosed) {
      emit(state.copyWith(clearSuccess: true));
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _markRead() async {
    final result = await _markConversationReadUseCase(state.conversationCode);
    // Publish event so ConversationListCubit zeroes the badge immediately —
    // before Firestore confirms the read receipt.
    result.fold(
      (_) {},
      (_) => MessagingEventService.instance.notifyMarkedRead(
        state.conversationCode,
      ),
    );
  }

  /// Debounced trigger for [_markRead], used by data-driven call sites
  /// (Firestore snapshot emissions, load/refresh) so repeated triggers in a
  /// short window collapse into a single API call. Resets on every call, so
  /// it only fires once activity has quieted down for
  /// [_markReadDebounceDuration].
  void _scheduleMarkRead() {
    if (isClosed) return;
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(_markReadDebounceDuration, () {
      if (!isClosed) unawaited(_markRead());
    });
  }

  List<MessageEntity> _sortedOldestFirst(List<MessageEntity> messages) {
    final sorted = List<MessageEntity>.from(messages);
    sorted.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return sorted;
  }

  /// Retain any pending/failed optimistic messages not yet confirmed by the API.
  List<MessageEntity> _mergePendingMessages(List<MessageEntity> fresh) {
    // Preserve `senderRole` if Firestore's realtime stream omitted it (forcing it to parent).
    // The local UI state knows the true role from the initial REST API load.
    final existingMessagesByCode = {
      for (final m in state.messages)
        if (m.code.isNotEmpty) m.code: m,
    };
    final existingMessagesById = {
      for (final m in state.messages)
        if (m.id.isNotEmpty) m.id: m,
    };

    final preservedFresh = fresh.map((m) {
      final old =
          existingMessagesByCode[m.code] ??
          existingMessagesById[m.id] ??
          existingMessagesByCode[m.id] ??
          existingMessagesById[m.code];
      if (old != null &&
          m.senderRole == ParticipantRole.parent &&
          old.senderRole != ParticipantRole.parent) {
        return m.copyWith(senderRole: old.senderRole);
      }
      return m;
    }).toList();

    final pending = state.messages
        .where((m) => m.localTempCode != null && (m.isPending || m.isFailed))
        .toList();
    if (pending.isEmpty) return preservedFresh;
    final freshCodes = preservedFresh.map((m) => m.code).toSet();
    final unconfirmed = pending
        .where((m) => !freshCodes.contains(m.code))
        .toList();
    return [...preservedFresh, ...unconfirmed];
  }

  List<MessageEntity> _replaceMessage(
    List<MessageEntity> messages,
    String code,
    MessageEntity replacement,
  ) {
    return messages.map((m) => m.code == code ? replacement : m).toList();
  }

  List<MessageEntity> _applyReaction(
    List<MessageEntity> messages,
    String messageCode,
    String userCode,
    String emoji,
  ) {
    return messages.map((m) {
      if (m.code != messageCode) return m;
      final updated = Map<String, String>.from(m.reactions);
      updated[userCode] = emoji;
      return m.copyWithReactions(updated);
    }).toList();
  }

  List<MessageEntity> _removeReactionLocally(
    List<MessageEntity> messages,
    String messageCode,
    String userCode,
  ) {
    return messages.map((m) {
      if (m.code != messageCode) return m;
      final updated = Map<String, String>.from(m.reactions)..remove(userCode);
      return m.copyWithReactions(updated);
    }).toList();
  }
}

// ─── MessageEntity convenience extensions ───────────────────────────────────

extension _MessageEntityX on MessageEntity {
  MessageEntity copyWithText(String newText) => MessageEntity(
    id: id,
    code: code,
    conversationCode: conversationCode,
    senderCode: senderCode,
    senderName: senderName,
    senderRole: senderRole,
    senderAvatarUrl: senderAvatarUrl,
    text: newText,
    messageType: messageType,
    status: status,
    sentAt: sentAt,
    organizationCode: organizationCode,
    schoolCode: schoolCode,
    isPrivate: isPrivate,
    isEdited: true,
    isDeleted: isDeleted,
    deletedPlaceholder: deletedPlaceholder,
    editedAt: DateTime.now(),
    deletedAt: deletedAt,
    attachments: attachments,
    reactions: reactions,
    readReceipts: readReceipts,
    threadParentCode: threadParentCode,
    threadParentSenderCode: threadParentSenderCode,
    threadParentSenderName: threadParentSenderName,
    threadParentText: threadParentText,
    localTempCode: localTempCode,
  );

  MessageEntity copyWithDeleted() => MessageEntity(
    id: id,
    code: code,
    conversationCode: conversationCode,
    senderCode: senderCode,
    senderName: senderName,
    senderRole: senderRole,
    senderAvatarUrl: senderAvatarUrl,
    text: text,
    messageType: messageType,
    status: status,
    sentAt: sentAt,
    organizationCode: organizationCode,
    schoolCode: schoolCode,
    isPrivate: isPrivate,
    isEdited: isEdited,
    isDeleted: true,
    deletedPlaceholder: 'This message has been deleted.',
    editedAt: editedAt,
    deletedAt: DateTime.now(),
    attachments: attachments,
    reactions: reactions,
    readReceipts: readReceipts,
    threadParentCode: threadParentCode,
    threadParentSenderCode: threadParentSenderCode,
    threadParentSenderName: threadParentSenderName,
    threadParentText: threadParentText,
    localTempCode: localTempCode,
  );

  MessageEntity copyWithReactions(Map<String, String> newReactions) =>
      MessageEntity(
        id: id,
        code: code,
        conversationCode: conversationCode,
        senderCode: senderCode,
        senderName: senderName,
        senderRole: senderRole,
        senderAvatarUrl: senderAvatarUrl,
        text: text,
        messageType: messageType,
        status: status,
        sentAt: sentAt,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        isPrivate: isPrivate,
        isEdited: isEdited,
        isDeleted: isDeleted,
        deletedPlaceholder: deletedPlaceholder,
        editedAt: editedAt,
        deletedAt: deletedAt,
        attachments: attachments,
        reactions: newReactions,
        readReceipts: readReceipts,
        threadParentCode: threadParentCode,
        threadParentSenderCode: threadParentSenderCode,
        threadParentSenderName: threadParentSenderName,
        threadParentText: threadParentText,
        localTempCode: localTempCode,
      );
}
