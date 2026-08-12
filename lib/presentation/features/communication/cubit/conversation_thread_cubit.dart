import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, AppLifecycleState;
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart'
    show ChatAttachment;
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/reaction_entry.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_attachment_uploader.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/pending_attachment_storage.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/message_entity_mapper.dart';
import 'package:wowcare/domain/features/communication/usecases/add_reaction_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/cache_draft_message_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_attachment_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/edit_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_messages_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_messages_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/mark_conversation_read_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/mark_draft_message_failed_usecase.dart';
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
    ConversationEntity? conversation,
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
    required CacheDraftMessageUseCase cacheDraftMessageUseCase,
    required MarkDraftMessageFailedUseCase markDraftMessageFailedUseCase,
    required GetCachedMessagesEntityUseCase getCachedMessagesEntityUseCase,
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
       _cacheDraftMessageUseCase = cacheDraftMessageUseCase,
       _markDraftMessageFailedUseCase = markDraftMessageFailedUseCase,
       _getCachedMessagesEntityUseCase = getCachedMessagesEntityUseCase,
       _markReadDebounceDuration = markReadDebounceDuration,
       super(
         ConversationThreadState.initial(
           conversationCode: conversationCode,
           // Seed the conversation so the realtime listener uses THIS conversation's
           // own org/school for the Firestore path (see startWatchingMessages) instead
           // of the session's active school — which for a classroom in a different
           // school built the wrong path → permission-denied → no live messages
           // (Classroom Notes). Mirrors staff/parent messaging.
           conversation: conversation,
         ),
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
  final CacheDraftMessageUseCase _cacheDraftMessageUseCase;
  final MarkDraftMessageFailedUseCase _markDraftMessageFailedUseCase;
  final GetCachedMessagesEntityUseCase _getCachedMessagesEntityUseCase;

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

    // Fire-and-forget: seeds any locally-cached draft (a send interrupted by
    // navigating away, or the app being killed, before the server confirmed
    // it) back into the thread. Whichever emission (this seed, or the
    // Firestore/REST load below) lands second still ends up with the draft —
    // [_mergePendingMessages] preserves any `pending`/`failed` +
    // `localTempCode` entry already in `state.messages` that the fresh
    // batch doesn't confirm.
    unawaited(_seedCachedLocalDrafts());

    // Kick off a REST load in parallel with the Firestore subscribe below,
    // rather than waiting for Firestore to fail first. The `onError` handler
    // below is NOT a reliable trigger for this: a `permission-denied` (e.g.
    // the Firebase custom-token sign-in — see FirebaseAuthService.signIn(),
    // fired-and-forgotten from AuthCubit.completeLogin() — still being in
    // flight right after login) gets silently retried inside
    // MessageRealtimeDataSource._watchWithRetry with up to 30s+ of backoff
    // and never reaches this listener's `onError` at all, so the REST
    // fallback below was never actually running — the thread just sat empty
    // until the user pulled-to-refresh (itself a plain REST call). Running
    // both concurrently guarantees a fast first paint regardless of
    // Firestore's connection/auth timing; whichever lands first is shown,
    // and the other reconciles on top via the same merge logic.
    unawaited(loadMessages());

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

  /// Merges any locally-cached, never-confirmed message (interrupted by
  /// navigating away, closing the app, or losing connectivity mid-send —
  /// including one still finishing an attachment upload) into
  /// [state.messages], so it's visible again instead of silently vanishing
  /// once this fresh cubit instance's in-memory state starts empty.
  Future<void> _seedCachedLocalDrafts() async {
    final result = await _getCachedMessagesEntityUseCase(
      state.conversationCode,
      currentUserCode: _currentUserCode,
    );
    if (isClosed) return;
    result.fold((_) {}, (cached) {
      final drafts = cached
          .where((m) => m.localTempCode != null && (m.isPending || m.isFailed))
          .toList();
      if (drafts.isEmpty) return;
      final existingCodes = state.messages.map((m) => m.code).toSet();
      final newDrafts = drafts
          .where((d) => !existingCodes.contains(d.code))
          .toList();
      if (newDrafts.isEmpty) return;
      emit(
        state.copyWith(
          messages: _sortedOldestFirst([...state.messages, ...newDrafts]),
        ),
      );
    });
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
        unawaited(_seedCachedLocalDrafts());
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
      (older) {
        // The backend's `beforeMessageCode` cursor has been observed to
        // hand back the reference message itself (and therefore the exact
        // same page) instead of excluding it — without a dedupe, that both
        // duplicates every message in `older` into the list AND, since the
        // "oldest" boundary (`state.messages.first`) never actually
        // changes, makes every subsequent scroll-triggered fetch refire
        // the identical request forever. Filtering to genuinely-new codes
        // fixes the duplicates, and falling back to `hasOlderMessages:
        // false` when nothing new came back stops the loop even if the
        // backend's cursor never advances.
        final existingCodes = state.messages.map((m) => m.code).toSet();
        final newOlder = _sortedOldestFirst(
          older,
        ).where((m) => !existingCodes.contains(m.code)).toList();
        emit(
          state.copyWith(
            messages: [...newOlder, ...state.messages],
            isLoading: false,
            hasOlderMessages: newOlder.isNotEmpty && older.length >= _pageSize,
            clearError: true,
          ),
        );
      },
    );
  }

  // ─── Send ────────────────────────────────────────────────────────────────────

  /// Send a message with optimistic UI.
  ///
  /// Immediately inserts a [MessageStatus.pending] placeholder — including
  /// local attachment previews — so the bubble appears at the bottom without
  /// waiting for upload or the backend round-trip, AND persists that same
  /// placeholder to Isar right away (via [_cacheDraftMessageUseCase]) so it
  /// survives navigating away or the app being killed before the send
  /// finishes — [_seedCachedLocalDrafts] brings it back on the next open.
  ///
  /// [attachments] are uploaded here (session → presign(batch) → S3 PUT →
  /// complete → register → wait-until-ready, via the same
  /// [ChatAttachmentUploader.uploadAll] documents/activities use) and the
  /// message is NOT sent until every attachment has a real delivery URL —
  /// [ChatAttachmentUploader.uploadAll] blocks on that itself. A message is
  /// never published with a still-processing attachment. If the
  /// upload/registration/wait fails or times out, the send is aborted — no
  /// partial/text-only message is sent — and the failure is surfaced via
  /// [ConversationThreadState.sendError] so the caller can retry without
  /// losing the picked files. [_reconcileAttachments] after a successful
  /// send is then a pure safety net (see its doc comment) rather than the
  /// primary path.
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

    /// Which guardian this private message belongs to. Only meaningful when
    /// [isPrivate] is true. Defaults to [senderCode] (a guardian composing
    /// their own private message) when omitted — pass this explicitly when
    /// STAFF/ADMIN is replying inside a specific guardian's private tab,
    /// since the sender in that case isn't the private party themselves.
    String? privateParentUserCode,
  }) async {
    // Draft thread: create the real conversation before sending (web parity).
    if (_isDraft) {
      final resolved = await _resolveDraftConversation();
      if (!resolved) return;
    }

    // Copy picked files out of the OS's ephemeral temp dir into permanent
    // app storage BEFORE anything else — the local preview needs to survive
    // navigating away, the app backgrounding, or a restart, none of which a
    // temp-dir path can promise (the OS is free to clear it at any time,
    // which silently blanks the preview even though the message/attachment
    // record itself is fine). See [PendingAttachmentStorage].
    attachments = await PendingAttachmentStorage.persistLocally(attachments);

    final tempCode = 'temp-${AppTime.nowUtc().millisecondsSinceEpoch}';

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
      sentAt: AppTime.nowUtc(),
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      isPrivate: isPrivate,
      privateParentUserCode: isPrivate
          ? (privateParentUserCode ?? senderCode)
          : null,
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
    // Persist right away too — before upload starts — so an interrupted
    // send (navigation, app kill, lost connectivity) still has something to
    // resume/retry from instead of vanishing outright.
    await _cacheDraftMessageUseCase(optimistic);

    // Upload any attachments that aren't already uploaded, via the shared
    // uploader — one batched upload session/presign call for the whole
    // selection, not one per file. Blocks until every attachment is READY
    // (see [ChatAttachmentUploader.uploadAll]); if upload, registration, or
    // the wait itself fails, abort the send — no partial message is created.
    List<ChatAttachment> uploadedAttachments = attachments;
    if (attachments.any((a) => !a.isUploaded)) {
      try {
        uploadedAttachments = await _attachmentUploader.uploadAll(
          conversationCode: state.conversationCode,
          attachments: attachments,
        );
      } catch (e) {
        await _markDraftMessageFailedUseCase(tempCode);
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
            sendError: ApiErrorHandler.extractErrorMessage(e),
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
      attachments: uploadedOptimisticAttachments,
      localTempCode: tempCode,
      isPrivate: isPrivate,
      threadParentCode: threadParentCode,
      privateParentUserCode: optimistic.privateParentUserCode,
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
        // Attachments are already READY by this point (uploadAll blocked on
        // it) — this only does anything if the *server's own* echoed
        // attachment objects lag behind with an empty fileUrl.
        unawaited(_reconcileAttachments(finalMessage));
      },
    );
  }

  /// Converts an [AttachmentEntity] back into the [ChatAttachment] shape
  /// [ChatAttachmentUploader] operates on — the inverse of
  /// [mapChatAttachmentToAttachmentEntity].
  ChatAttachment _toChatAttachment(AttachmentEntity a) => ChatAttachment(
    name: a.fileName,
    type: a.isImage ? 'image' : 'file',
    sizeBytes: a.fileSizeBytes,
    mimeType: a.mimeType,
    remoteUrl: a.fileUrl,
    localPath: a.localFilePath,
    code: a.code.isEmpty ? null : a.code,
    attachmentId: a.attachmentId,
  );

  /// Resolves the real delivery URL for any of [message]'s attachments still
  /// showing a local preview (uploaded + registered, but the document
  /// service hasn't finished processing them into a URL yet). Since
  /// [ChatAttachmentUploader.uploadAll] already blocks a send until every
  /// attachment is READY, this is a safety net for the cases that skip that
  /// wait: a server-echoed attachment lagging behind with an empty fileUrl
  /// right after send, or resuming a message that was interrupted (app
  /// killed, navigation) mid-wait on a prior attempt. A single best-effort
  /// poll, not a blocking wait — safe to call repeatedly; a no-op once
  /// nothing is left processing.
  Future<void> _reconcileAttachments(MessageEntity message) async {
    if (!message.hasProcessingAttachments) return;
    final resolved = await _attachmentUploader.resolveDeliveryUrls(
      message.attachments.map(_toChatAttachment).toList(),
    );

    var changed = false;
    final updatedAttachments = <AttachmentEntity>[];
    for (var i = 0; i < message.attachments.length; i++) {
      final original = message.attachments[i];
      final r = resolved[i];
      if (r.remoteUrl.isNotEmpty && r.remoteUrl != original.fileUrl) {
        updatedAttachments.add(
          original.copyWith(fileUrl: r.remoteUrl, clearLocalFilePath: true),
        );
        changed = true;
        // The real delivery URL now renders fine — drop the durable local
        // copy [PendingAttachmentStorage] made so it doesn't sit around
        // forever. Fire-and-forget: never blocks showing the resolved image.
        unawaited(PendingAttachmentStorage.delete(original.localFilePath));
      } else {
        updatedAttachments.add(original);
      }
    }
    if (!changed) return;

    final updatedMessage = message.copyWith(attachments: updatedAttachments);
    await _cacheDraftMessageUseCase(updatedMessage);
    if (isClosed) return;
    // The conversation may have moved on (older message no longer in the
    // loaded window) — only emit if it's still there to replace.
    if (!state.messages.any((m) => m.code == message.code)) return;
    final updated = _replaceMessage(
      state.messages,
      message.code,
      updatedMessage,
    );
    emit(state.copyWith(messages: updated));
  }

  /// Retries a message that either never finished uploading its attachments
  /// (picks up from [AttachmentEntity.localFilePath] — nothing needed if the
  /// user closed the app before the file was even picked-and-persisted,
  /// since that never got this far) or is fully sent but still has an
  /// attachment stuck on "Processing" (just re-polls, no re-upload). When a
  /// retry does re-run [ChatAttachmentUploader.uploadAll], its own 3-way
  /// classification (ready / registered-but-not-uploaded / needs full
  /// upload) makes sure nothing that already finished gets redone.
  Future<void> retrySendMessage(MessageEntity message) async {
    if (!message.isFailed && !message.hasUnuploadedAttachments) {
      // Already sent — nothing failed, just poll again for the ones still
      // processing.
      unawaited(_reconcileAttachments(message));
      return;
    }

    final tempCode = (message.localTempCode ?? '').isNotEmpty
        ? message.localTempCode!
        : message.code;
    final targetCode = message.code;

    final retrying = message.copyWith(status: MessageStatus.pending);
    emit(
      state.copyWith(
        messages: _replaceMessage(state.messages, targetCode, retrying),
        isSending: true,
        clearSendError: true,
      ),
    );
    await _cacheDraftMessageUseCase(retrying);

    final asChatAttachments = message.attachments
        .map(_toChatAttachment)
        .toList();
    List<ChatAttachment> uploaded = asChatAttachments;
    if (asChatAttachments.any((a) => !a.isUploaded)) {
      try {
        uploaded = await _attachmentUploader.uploadAll(
          conversationCode: state.conversationCode,
          attachments: asChatAttachments,
        );
      } catch (e) {
        await _markDraftMessageFailedUseCase(tempCode);
        if (isClosed) return;
        emit(
          state.copyWith(
            messages: _replaceMessage(
              state.messages,
              targetCode,
              retrying.copyWith(status: MessageStatus.failed),
            ),
            isSending: false,
            sendError: ApiErrorHandler.extractErrorMessage(e),
          ),
        );
        return;
      }
    }

    final attachmentIds = uploaded
        .map((a) => a.attachmentId)
        .whereType<int>()
        .toList();
    final entityAttachments = uploaded
        .map(
          (a) => mapChatAttachmentToAttachmentEntity(
            a,
            messageCode: tempCode,
            conversationCode: state.conversationCode,
            uploadedBy: message.senderCode,
          ),
        )
        .toList();

    final result = await _sendMessageUseCase(
      conversationCode: state.conversationCode,
      text: message.text,
      attachmentIds: attachmentIds,
      attachments: entityAttachments,
      localTempCode: tempCode,
      isPrivate: message.isPrivate,
      threadParentCode: message.threadParentCode,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            messages: _replaceMessage(
              state.messages,
              targetCode,
              retrying.copyWith(
                status: MessageStatus.failed,
                attachments: entityAttachments,
              ),
            ),
            isSending: false,
            sendError: failure.message ?? 'Failed to send message.',
          ),
        );
      },
      (confirmed) {
        final finalMessage = confirmed.attachments.isNotEmpty
            ? confirmed
            : confirmed.copyWith(attachments: entityAttachments);
        emit(
          state.copyWith(
            messages: _replaceMessage(state.messages, targetCode, finalMessage),
            isSending: false,
            clearSendError: true,
          ),
        );
        unawaited(_reconcileAttachments(finalMessage));
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

    final originalMessages = state.messages;

    // Optimistic: mark deleted locally
    final optimistic = state.messages.map((m) {
      if (m.code != messageCode) return m;
      return m.copyWithDeleted();
    }).toList();
    emit(state.copyWith(messages: optimistic));

    final result = await _deleteMessageUseCase(messageCode);

    if (isClosed) return;

    // On failure, restore the exact pre-optimistic snapshot synchronously —
    // relying on refreshMessages()'s refetch would race with
    // _mergePendingMessages' "preserve deleted state" guard, which cannot
    // tell a still-propagating delete apart from a failed one and would
    // re-stamp isDeleted onto the (correctly non-deleted) refetched message.
    result.fold((failure) {
      emit(
        state.copyWith(
          messages: originalMessages,
          errorMessage: failure.message ?? 'Failed to delete message.',
        ),
      );
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
      emoji,
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

  void clearError() {
    if (!isClosed && state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _markRead() async {
    // Only mark read while the app is actually in the foreground. This is triggered off Firestore
    // snapshot emissions, so without the gate a message arriving while the recipient's app is
    // backgrounded would be stamped read — zeroing their unread badge for a message they never
    // actually saw (the unread badges are receipt-based).
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.detached) {
      return;
    }
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
      if (old == null) return m;

      MessageEntity result = m;

      // Preserve senderRole if Firestore wrongly defaulted it to parent.
      if (m.senderRole == ParticipantRole.parent &&
          old.senderRole != ParticipantRole.parent) {
        result = result.copyWith(senderRole: old.senderRole);
      }

      // Preserve deleted state when Firestore hasn't yet propagated the delete.
      // Without this guard, a realtime batch triggered by an unrelated event
      // (e.g. another message's reaction) overwrites the optimistic deleted
      // state and makes "This message has been deleted." disappear.
      if (old.isDeleted && !result.isDeleted) {
        result = result.copyWith(
          isDeleted: true,
          deletedAt: old.deletedAt,
          deletedPlaceholder: old.deletedPlaceholder,
        );
      }

      // Preserve attachments if a realtime update arrives without them (a legacy Firestore doc, or
      // any emission that dropped them) so an existing message's image doesn't vanish on live update.
      if (result.attachments.isEmpty && old.attachments.isNotEmpty) {
        result = result.copyWith(attachments: old.attachments);
      }

      return result;
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
      // Append this (user, emoji) only if not already present — a user may
      // hold multiple distinct emojis; adding one must not drop the others.
      if (m.userHasReaction(userCode, emoji)) return m;
      final updated = [
        ...m.reactions,
        ReactionEntry(userCode: userCode, emoji: emoji),
      ];
      return m.copyWithReactions(updated);
    }).toList();
  }

  List<MessageEntity> _removeReactionLocally(
    List<MessageEntity> messages,
    String messageCode,
    String userCode,
    String emoji,
  ) {
    return messages.map((m) {
      if (m.code != messageCode) return m;
      // Drop only the matching (user, emoji) entry — the user's other emojis
      // on this message stay put.
      final updated = m.reactions
          .where((r) => !(r.matchesUser(userCode) && r.emoji == emoji))
          .toList();
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
    editedAt: AppTime.nowUtc(),
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
    deletedAt: AppTime.nowUtc(),
    attachments: attachments,
    reactions: reactions,
    readReceipts: readReceipts,
    threadParentCode: threadParentCode,
    threadParentSenderCode: threadParentSenderCode,
    threadParentSenderName: threadParentSenderName,
    threadParentText: threadParentText,
    localTempCode: localTempCode,
  );

  MessageEntity copyWithReactions(List<ReactionEntry> newReactions) =>
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
