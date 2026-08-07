import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/usecases/cache_draft_message_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/cache_message_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_entity_usecase.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_attachment_uploader.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/pending_attachment_storage.dart';

class SelectedAttachment extends Equatable {
  final File file;
  final bool isImage;

  const SelectedAttachment.file(this.file, {required this.isImage});

  @override
  List<Object?> get props => [file.path, isImage];
}

class BulkMessagingCompositionState extends Equatable {
  final List<Map<String, dynamic>> selectedRecipients;
  final List<String> selectedRecipientNames;
  final List<SelectedAttachment> attachments;
  final String messageText;
  final bool isStaff;
  final String conversationType;
  final bool isLoading;
  final bool isSuccess;

  /// True the instant the background bulk job is launched — UI should
  /// navigate away immediately and show a processing snackbar.
  final bool isBulkStarted;
  final String? errorMessage;
  final String progressMessage;

  /// Recipients that failed to receive the message in the last bulk send.
  /// Non-empty after the job completes with at least one failure.
  final List<Map<String, dynamic>> failedRecipients;

  const BulkMessagingCompositionState({
    this.selectedRecipients = const [],
    this.selectedRecipientNames = const [],
    this.attachments = const [],
    this.messageText = '',
    this.isStaff = true,
    this.conversationType = 'ROOM_CHAT',
    this.isLoading = false,
    this.isSuccess = false,
    this.isBulkStarted = false,
    this.errorMessage,
    this.progressMessage = '',
    this.failedRecipients = const [],
  });

  // `messageText` is the raw HTML-aware text (see HtmlAwareTextController),
  // which includes the invisible <b>/<i>/<u>/<s> markup the rich text
  // toolbar inserts — counting it raw would show e.g. "11/2000" for a bolded
  // 4-character word. Count the stripped/visible text the user actually
  // sees instead, matching ChatInputBar's counter.
  int get charCount =>
      MessageContentProcessor.stripHtmlTags(messageText).length;
  bool get canSend =>
      !isLoading &&
      !isBulkStarted &&
      selectedRecipients.isNotEmpty &&
      (messageText.trim().isNotEmpty || attachments.isNotEmpty);

  BulkMessagingCompositionState copyWith({
    List<Map<String, dynamic>>? selectedRecipients,
    List<String>? selectedRecipientNames,
    List<SelectedAttachment>? attachments,
    String? messageText,
    bool? isStaff,
    String? conversationType,
    bool? isLoading,
    bool? isSuccess,
    bool? isBulkStarted,
    String? errorMessage,
    String? progressMessage,
    List<Map<String, dynamic>>? failedRecipients,
  }) {
    return BulkMessagingCompositionState(
      selectedRecipients: selectedRecipients ?? this.selectedRecipients,
      selectedRecipientNames:
          selectedRecipientNames ?? this.selectedRecipientNames,
      attachments: attachments ?? this.attachments,
      messageText: messageText ?? this.messageText,
      isStaff: isStaff ?? this.isStaff,
      conversationType: conversationType ?? this.conversationType,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isBulkStarted: isBulkStarted ?? this.isBulkStarted,
      errorMessage: errorMessage,
      progressMessage: progressMessage ?? this.progressMessage,
      failedRecipients: failedRecipients ?? this.failedRecipients,
    );
  }

  @override
  List<Object?> get props => [
    selectedRecipients,
    selectedRecipientNames,
    attachments,
    messageText,
    isStaff,
    conversationType,
    isLoading,
    isSuccess,
    isBulkStarted,
    errorMessage,
    progressMessage,
    failedRecipients,
  ];
}

class BulkMessagingCompositionCubit
    extends Cubit<BulkMessagingCompositionState> {
  final CreateOrOpenConversationUseCase _createOrOpenConversationUseCase;
  final SendMessageEntityUseCase _sendMessageUseCase;
  final ChatAttachmentUploader _attachmentUploader;
  final StorageService _storageService;

  /// STAFF_DIRECT recipients are viewed through the LEGACY
  /// CommunicationCubit/StaffMessagingThread stack (its own Isar
  /// [Message]/MessageCollection cache), which is entirely separate from
  /// the [MessageEntity]/MessageEntityCollection cache [_sendMessageUseCase]
  /// (always the v2 usecase, for every recipient type) writes to
  /// internally. Without ALSO caching an optimistic draft into the legacy
  /// store here, a bulk STAFF_DIRECT send is invisible in that recipient's
  /// own thread for the whole upload window — the v2 draft it creates lives
  /// in a cache that screen never reads.
  final CacheMessageUseCase _cacheMessageUseCase;
  final DiscardCachedMessageUseCase _discardCachedMessageUseCase;

  /// ROOM_CHAT/ADMIN_CHAT recipients are viewed through
  /// ConversationThreadCubit, which DOES read the same v2 cache
  /// [_sendMessageUseCase] writes to — but only once [_sendMessageUseCase]
  /// itself is called, which happens AFTER the (potentially multi-second)
  /// attachment upload. Caching here too, before upload starts, closes that
  /// same gap for this branch.
  final CacheDraftMessageUseCase _cacheDraftMessageUseCase;

  BulkMessagingCompositionCubit({
    required List<Map<String, dynamic>> initialRecipients,
    required bool isStaff,
    required CreateOrOpenConversationUseCase createOrOpenConversationUseCase,
    required SendMessageEntityUseCase sendMessageUseCase,
    required ChatAttachmentUploader attachmentUploader,
    required StorageService storageService,
    required CacheMessageUseCase cacheMessageUseCase,
    required DiscardCachedMessageUseCase discardCachedMessageUseCase,
    required CacheDraftMessageUseCase cacheDraftMessageUseCase,
    String conversationType = 'ROOM_CHAT',
  }) : _createOrOpenConversationUseCase = createOrOpenConversationUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _attachmentUploader = attachmentUploader,
       _storageService = storageService,
       _cacheMessageUseCase = cacheMessageUseCase,
       _discardCachedMessageUseCase = discardCachedMessageUseCase,
       _cacheDraftMessageUseCase = cacheDraftMessageUseCase,
       super(
         BulkMessagingCompositionState(
           isStaff: isStaff,
           conversationType: conversationType,
           selectedRecipients: List<Map<String, dynamic>>.from(
             initialRecipients,
           ),
           selectedRecipientNames: initialRecipients
               .map((recipient) => recipient['name'] as String)
               .toList(),
         ),
       );

  void updateMessageText(String value) {
    if (isClosed) return;
    emit(state.copyWith(messageText: value));
  }

  void addAttachment(File file, {required bool isImage}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        attachments: [
          ...state.attachments,
          SelectedAttachment.file(file, isImage: isImage),
        ],
      ),
    );
  }

  /// Same as [addAttachment] but for a multi-select pick — appends all of
  /// [files] in a single emit instead of one rebuild per file.
  void addAttachments(List<File> files, {required bool isImage}) {
    if (isClosed || files.isEmpty) return;
    emit(
      state.copyWith(
        attachments: [
          ...state.attachments,
          ...files.map((f) => SelectedAttachment.file(f, isImage: isImage)),
        ],
      ),
    );
  }

  void removeAttachmentAt(int index) {
    if (isClosed) return;
    if (index < 0 || index >= state.attachments.length) return;
    final updated = List<SelectedAttachment>.from(state.attachments)
      ..removeAt(index);
    emit(state.copyWith(attachments: updated));
  }

  void removeRecipientByName(String name) {
    if (isClosed) return;
    final names = List<String>.from(state.selectedRecipientNames)..remove(name);
    final recipients = state.selectedRecipients
        .where((recipient) => recipient['name'] != name)
        .toList();

    emit(
      state.copyWith(
        selectedRecipients: recipients,
        selectedRecipientNames: names,
      ),
    );
  }

  /// Starts the bulk send job in the background.
  ///
  /// Emits [isBulkStarted] = true immediately so the UI can navigate away and
  /// show a progress snackbar. The actual work runs fire-and-forget and never
  /// blocks the caller.
  Future<void> sendMessages(BuildContext context) async {
    if (!state.canSend) return;

    // Collect everything from storage before firing the background job so we
    // don't need the BuildContext after this point.
    final orgCode =
        (await _storageService.getString(StorageKeys.organizationCode) ?? '')
            .trim();
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

    if (isClosed) return;

    if (orgCode.isEmpty || schoolCode.isEmpty) {
      emit(
        state.copyWith(errorMessage: 'Organization or School code not found.'),
      );
      return;
    }

    final senderCode =
        (await _storageService.getString(StorageKeys.staffCode) ?? '').trim();
    final senderUserCode =
        (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
    final actualSenderCode = senderCode.isNotEmpty
        ? senderCode
        : senderUserCode;

    if (isClosed) return;

    // Snapshot state before going async — it won't change under us.
    final recipients = List<Map<String, dynamic>>.from(
      state.selectedRecipients,
    );
    final messageText = state.messageText.trim();
    final isStaff = state.isStaff;
    final conversationType = state.conversationType;
    final attachments = List<SelectedAttachment>.from(state.attachments);

    // Signal the UI immediately so it can navigate back.
    emit(state.copyWith(isBulkStarted: true));

    // Fire-and-forget — do not await.
    unawaited(
      _runBulkJob(
        orgCode: orgCode,
        schoolCode: schoolCode,
        senderUserCode: senderUserCode,
        actualSenderCode: actualSenderCode,
        recipients: recipients,
        messageText: messageText,
        attachments: attachments,
        isStaff: isStaff,
        conversationType: conversationType,
      ),
    );
  }

  /// Re-runs the bulk job for only the recipients that failed in the previous
  /// attempt. Clears [failedRecipients] on completion.
  Future<void> retryFailed({
    required String orgCode,
    required String schoolCode,
    required String senderUserCode,
    required String actualSenderCode,
  }) async {
    if (isClosed || state.failedRecipients.isEmpty) return;
    final toRetry = List<Map<String, dynamic>>.from(state.failedRecipients);
    emit(state.copyWith(failedRecipients: const [], isBulkStarted: true));
    unawaited(
      _runBulkJob(
        orgCode: orgCode,
        schoolCode: schoolCode,
        senderUserCode: senderUserCode,
        actualSenderCode: actualSenderCode,
        recipients: toRetry,
        messageText: state.messageText,
        attachments: List<SelectedAttachment>.from(state.attachments),
        isStaff: state.isStaff,
        conversationType: state.conversationType,
      ),
    );
  }

  /// Convert the picker's [SelectedAttachment]s (local files) into unuploaded
  /// [ChatAttachment]s ready for [_attachmentUploader]. Built once per bulk run.
  Future<List<ChatAttachment>> _baseAttachments(
    List<SelectedAttachment> selected,
  ) async {
    final result = <ChatAttachment>[];
    for (final a in selected) {
      final size = await a.file.length();
      result.add(
        ChatAttachment(
          localPath: a.file.path,
          name: p.basename(a.file.path),
          type: a.isImage ? 'image' : 'document',
          sizeBytes: size,
          mimeType: lookupMimeType(a.file.path) ?? 'application/octet-stream',
          remoteUrl: '',
        ),
      );
    }
    return result;
  }

  /// Caches an optimistic "sending" preview of the message for
  /// [conversationCode] BEFORE its upload/send starts, into whichever local
  /// store that recipient's own thread screen actually reads from — see the
  /// [_cacheMessageUseCase]/[_cacheDraftMessageUseCase] field docs. Without
  /// this, opening that recipient's thread while their copy is still
  /// uploading showed nothing at all until the whole background job
  /// finished.
  Future<void> _cacheOptimisticDraft({
    required bool isStaff,
    required String conversationCode,
    required String tempCode,
    required String text,
    required String senderUserCode,
    required List<ChatAttachment> durableAttachments,
    required String orgCode,
    required String schoolCode,
  }) async {
    final now = AppTime.nowUtc();
    if (isStaff) {
      await _cacheMessageUseCase(
        conversationCode,
        Message(
          id: tempCode,
          code: tempCode,
          text: text,
          isSentByMe: true,
          senderUserCode: senderUserCode,
          time: now,
          attachments: durableAttachments,
          isSending: true,
        ),
      );
      return;
    }
    await _cacheDraftMessageUseCase(
      MessageEntity(
        id: tempCode,
        code: tempCode,
        conversationCode: conversationCode,
        senderCode: senderUserCode,
        senderName: '',
        senderRole: ParticipantRole.staff,
        text: text,
        messageType: MessageType.text,
        status: MessageStatus.pending,
        sentAt: now,
        organizationCode: orgCode,
        schoolCode: schoolCode,
        localTempCode: tempCode,
        attachments: _toAttachmentEntities(
          durableAttachments,
          conversationCode: conversationCode,
          messageCode: tempCode,
          uploadedBy: senderUserCode,
          uploadedAt: now,
        ),
      ),
    );
  }

  /// Maps uploaded/local [ChatAttachment]s to the [AttachmentEntity] shape
  /// [MessageEntity] carries. Used both for the pre-upload optimistic
  /// draft's attachments AND the `attachments:` param passed to
  /// [_sendMessageUseCase] — [MessageEntityRepositoryImpl.sendMessage]
  /// unconditionally rebuilds and re-saves its own optimistic row from
  /// whatever `attachments` it's given (empty by default), which would
  /// otherwise clobber the richer draft just cached above with an
  /// attachment-less one the instant the send call starts.
  List<AttachmentEntity> _toAttachmentEntities(
    List<ChatAttachment> attachments, {
    required String conversationCode,
    required String messageCode,
    required String uploadedBy,
    required DateTime uploadedAt,
  }) {
    return attachments
        .map(
          (a) => AttachmentEntity(
            code: a.code ?? '',
            messageCode: messageCode,
            conversationCode: conversationCode,
            fileName: a.name,
            fileUrl: a.remoteUrl,
            mimeType: a.mimeType,
            fileSizeBytes: a.sizeBytes,
            attachmentType: AttachmentType.fromMimeType(a.mimeType),
            localFilePath: a.localPath,
            uploadedBy: uploadedBy,
            uploadedAt: uploadedAt,
            attachmentId: a.attachmentId,
          ),
        )
        .toList();
  }

  /// Resolves the legacy-store draft [_cacheOptimisticDraft] wrote for a
  /// STAFF_DIRECT recipient once the send settles. The v2 branch needs no
  /// equivalent call — [MessageEntityRepositoryImpl.sendMessage] already
  /// resolves its OWN draft in place via the shared `localTempCode`. The
  /// legacy store has no such mechanism (the confirmed write from
  /// [_sendMessageUseCase] lands in the v2 cache, not this one), so the
  /// draft row here is orphaned unless explicitly discarded (success) or
  /// flipped to failed (failure).
  Future<void> _resolveLegacyDraft({
    required bool isStaff,
    required String conversationCode,
    required String tempCode,
    required bool succeeded,
    required String text,
    required String senderUserCode,
    required List<ChatAttachment> durableAttachments,
  }) async {
    if (!isStaff) return;
    if (succeeded) {
      await _discardCachedMessageUseCase(tempCode);
      return;
    }
    await _cacheMessageUseCase(
      conversationCode,
      Message(
        id: tempCode,
        code: tempCode,
        text: text,
        isSentByMe: true,
        senderUserCode: senderUserCode,
        time: AppTime.nowUtc(),
        attachments: durableAttachments,
        isFailed: true,
      ),
    );
  }

  /// Upload [base] into [conversationCode] (session → presign → S3 → complete →
  /// register, via the same uploader the chat thread uses) and return the
  /// uploaded attachments (real code/attachmentId/remoteUrl resolved) for
  /// sendMessage. Throws if any upload fails, so the caller marks that
  /// recipient failed (all-or-nothing, no partial send).
  Future<List<ChatAttachment>> _uploadAttachmentsFor(
    String conversationCode,
    List<ChatAttachment> base,
  ) async {
    if (base.isEmpty) return const [];
    return _attachmentUploader.uploadAll(
      conversationCode: conversationCode,
      attachments: base,
    );
  }

  Future<void> _runBulkJob({
    required String orgCode,
    required String schoolCode,
    required String senderUserCode,
    required String actualSenderCode,
    required List<Map<String, dynamic>> recipients,
    required String messageText,
    required List<SelectedAttachment> attachments,
    required bool isStaff,
    required String conversationType,
  }) async {
    final failed = <Map<String, dynamic>>[];
    // Build the local ChatAttachment list once (picked files → attachments).
    // Each recipient's conversation uploads its own copy of these below —
    // attachments are scoped per conversation. Copied into permanent app
    // storage once (not per-recipient — every recipient's optimistic draft
    // just reads the same file) so the local preview survives the composer
    // screen having already been popped/disposed by the time any of this
    // runs.
    final baseAttachments = await PendingAttachmentStorage.persistLocally(
      await _baseAttachments(attachments),
    );

    try {
      if (isStaff) {
        // Send in small concurrent batches rather than one-at-a-time so a
        // large recipient list doesn't take N sequential round-trips — each
        // recipient's outcome is still tracked independently in [failed], so
        // one failure never blocks the rest of the batch.
        const batchSize = 8;
        for (var i = 0; i < recipients.length; i += batchSize) {
          final batch = recipients.skip(i).take(batchSize);
          await Future.wait(
            batch.map((recipient) async {
              // Do NOT check isClosed here — the cubit is closed when the
              // compose screen is disposed (immediately after isBulkStarted
              // fires), but the job must continue to completion regardless
              // of widget lifecycle.
              final recipientCode = _recipientCode(recipient);
              final recipientName = (recipient['name'] ?? 'recipient')
                  .toString();
              if (recipientCode.isEmpty) return;

              try {
                // ── Find-or-create: reuse existing STAFF_DIRECT thread ────
                final result = await _createOrOpenConversationUseCase(
                  type: ConversationType.staffDirect,
                  studentCode: '',
                  participantCodes: [recipientCode],
                  title: recipientName,
                  description: messageText,
                );
                final conv = result.fold((_) => null, (c) => c);
                if (conv == null) {
                  failed.add(recipient);
                  return;
                }
                final conversationCode = conv.code;
                final tempCode =
                    'bulk-${AppTime.nowUtc().microsecondsSinceEpoch}-$recipientCode';

                // Visible immediately in this recipient's own thread (local
                // preview + pending indicator) even while the upload below
                // is still running.
                await _cacheOptimisticDraft(
                  isStaff: true,
                  conversationCode: conversationCode,
                  tempCode: tempCode,
                  text: messageText,
                  senderUserCode: senderUserCode,
                  durableAttachments: baseAttachments,
                  orgCode: orgCode,
                  schoolCode: schoolCode,
                );

                // Upload this message's attachments into THIS conversation, then
                // send text + attachmentIds. Without this the attachments picked
                // in the composer were silently dropped (text-only send).
                final uploadedAttachments = await _uploadAttachmentsFor(
                  conversationCode,
                  baseAttachments,
                );
                final attachmentIds = uploadedAttachments
                    .map((a) => a.attachmentId)
                    .whereType<int>()
                    .toList();
                if (messageText.isNotEmpty || attachmentIds.isNotEmpty) {
                  final sendResult = await _sendMessageUseCase(
                    conversationCode: conversationCode,
                    text: messageText,
                    attachmentIds: attachmentIds,
                    attachments: _toAttachmentEntities(
                      uploadedAttachments,
                      conversationCode: conversationCode,
                      messageCode: tempCode,
                      uploadedBy: senderUserCode,
                      uploadedAt: AppTime.nowUtc(),
                    ),
                    localTempCode: tempCode,
                  );
                  await _resolveLegacyDraft(
                    isStaff: true,
                    conversationCode: conversationCode,
                    tempCode: tempCode,
                    succeeded: sendResult.isRight(),
                    text: messageText,
                    senderUserCode: senderUserCode,
                    durableAttachments: baseAttachments,
                  );
                  sendResult.fold((_) => failed.add(recipient), (_) {});
                } else {
                  await _resolveLegacyDraft(
                    isStaff: true,
                    conversationCode: conversationCode,
                    tempCode: tempCode,
                    succeeded: true,
                    text: messageText,
                    senderUserCode: senderUserCode,
                    durableAttachments: baseAttachments,
                  );
                }
              } catch (_) {
                failed.add(recipient);
              }
            }),
          );
        }
      } else {
        final isAdminChat = conversationType == 'ADMIN_CHAT';
        final recipientByCode = <String, Map<String, dynamic>>{
          for (final r in recipients) _recipientCode(r): r,
        }..removeWhere((code, _) => code.isEmpty);

        final filteredRecipientCodes = isAdminChat
            ? recipientByCode.keys.where((c) => !c.startsWith('STF_'))
            : recipientByCode.keys;
        final codes = filteredRecipientCodes.toList();
        if (codes.isEmpty) return;

        // Same broadcast pattern as the staff branch above: one
        // independent conversation per recipient (their own room/admin
        // chat scoped to that student), not a single shared group thread
        // with everyone lumped in — selecting N students should reach N
        // separate conversations, exactly like selecting N staff does.
        const batchSize = 8;
        for (var i = 0; i < codes.length; i += batchSize) {
          final batch = codes.skip(i).take(batchSize);
          await Future.wait(
            batch.map((recipientCode) async {
              final recipient = recipientByCode[recipientCode]!;
              final recipientName = (recipient['name'] ?? 'recipient')
                  .toString();
              final recipientClassroomCode = (recipient['classroomCode'] ?? '')
                  .toString();

              try {
                final result = await _createOrOpenConversationUseCase(
                  type: isAdminChat
                      ? ConversationType.adminChat
                      : ConversationType.roomChat,
                  studentCode: recipientCode,
                  classroomCode: recipientClassroomCode,
                  participantCodes: [
                    if (senderUserCode.isNotEmpty) senderUserCode,
                  ],
                  title: recipientName,
                  description: messageText,
                );
                final conv = result.fold((_) => null, (c) => c);
                if (conv == null) {
                  failed.add(recipient);
                  return;
                }
                final tempCode =
                    'bulk-${AppTime.nowUtc().microsecondsSinceEpoch}-$recipientCode';

                // Visible immediately in this recipient's own thread (local
                // preview + pending indicator) even while the upload below
                // is still running.
                await _cacheOptimisticDraft(
                  isStaff: false,
                  conversationCode: conv.code,
                  tempCode: tempCode,
                  text: messageText,
                  senderUserCode: senderUserCode,
                  durableAttachments: baseAttachments,
                  orgCode: orgCode,
                  schoolCode: schoolCode,
                );

                final uploadedAttachments = await _uploadAttachmentsFor(
                  conv.code,
                  baseAttachments,
                );
                final attachmentIds = uploadedAttachments
                    .map((a) => a.attachmentId)
                    .whereType<int>()
                    .toList();
                if (messageText.isNotEmpty || attachmentIds.isNotEmpty) {
                  final sendResult = await _sendMessageUseCase(
                    conversationCode: conv.code,
                    text: messageText,
                    attachmentIds: attachmentIds,
                    attachments: _toAttachmentEntities(
                      uploadedAttachments,
                      conversationCode: conv.code,
                      messageCode: tempCode,
                      uploadedBy: senderUserCode,
                      uploadedAt: AppTime.nowUtc(),
                    ),
                    localTempCode: tempCode,
                  );
                  sendResult.fold((_) => failed.add(recipient), (_) {});
                }
              } catch (_) {
                failed.add(recipient);
              }
            }),
          );
        }
      }

      // Notify the conversation list to refresh now that all conversations and
      // messages have been created. The cubit may be closed at this point
      // (compose screen was disposed when isBulkStarted fired), so we emit
      // only if still open but ALWAYS broadcast the list-changed event.
      MessagingEventService.instance.notifyConversationListChanged(
        conversationType,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            isSuccess: failed.isEmpty,
            failedRecipients: failed,
            progressMessage: failed.isEmpty
                ? ''
                : '${failed.length} message(s) failed to send. Tap retry.',
          ),
        );
      }
    } catch (_) {
      // Catastrophic failure — mark all recipients as failed so retry is offered.
      MessagingEventService.instance.notifyConversationListChanged(
        conversationType,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            failedRecipients: recipients,
            progressMessage: 'Bulk send failed. Tap retry.',
          ),
        );
      }
    }
  }

  String _recipientCode(Map<String, dynamic> recipient) {
    return (recipient['userCode'] ??
            recipient['code'] ??
            recipient['staffCode'] ??
            recipient['studentCode'] ??
            '')
        .toString()
        .trim();
  }
}
