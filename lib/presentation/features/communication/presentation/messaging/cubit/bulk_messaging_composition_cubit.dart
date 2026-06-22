import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_usecase.dart';

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

  int get charCount => messageText.length;
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
  final SendMessageUseCase _sendMessageUseCase;
  final StorageService _storageService;

  BulkMessagingCompositionCubit({
    required List<Map<String, dynamic>> initialRecipients,
    required bool isStaff,
    required CreateOrOpenConversationUseCase createOrOpenConversationUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required StorageService storageService,
    String conversationType = 'ROOM_CHAT',
  }) : _createOrOpenConversationUseCase = createOrOpenConversationUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _storageService = storageService,
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
    unawaited(_runBulkJob(
      orgCode: orgCode,
      schoolCode: schoolCode,
      senderUserCode: senderUserCode,
      actualSenderCode: actualSenderCode,
      recipients: toRetry,
      messageText: state.messageText,
      isStaff: state.isStaff,
      conversationType: state.conversationType,
    ));
  }

  Future<void> _runBulkJob({
    required String orgCode,
    required String schoolCode,
    required String senderUserCode,
    required String actualSenderCode,
    required List<Map<String, dynamic>> recipients,
    required String messageText,
    required bool isStaff,
    required String conversationType,
  }) async {
    final failed = <Map<String, dynamic>>[];

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

                if (messageText.isNotEmpty) {
                  final msg = Message(
                    id: 'bulk-${DateTime.now().millisecondsSinceEpoch}',
                    code: '',
                    text: messageText,
                    isSentByMe: true,
                    senderUserCode: senderUserCode.isNotEmpty
                        ? senderUserCode
                        : actualSenderCode,
                    time: DateTime.now(),
                  );
                  await _sendMessageUseCase(conversationCode, msg);
                }
              } catch (_) {
                failed.add(recipient);
              }
            }),
          );
        }
      } else {
        final recipientCodes = recipients
            .map(_recipientCode)
            .where((code) => code.isNotEmpty)
            .toSet()
            .toList();

        if (recipientCodes.isEmpty) return;

        final isAdminChat = conversationType == 'ADMIN_CHAT';
        final filteredRecipientCodes = isAdminChat
            ? recipientCodes.where((c) => !c.startsWith('STF_')).toList()
            : recipientCodes;

        // Dedupe is only meaningful when the audience resolves to a single
        // student scope (e.g. "message about this one child") — an ad-hoc
        // multi-recipient broadcast has no single existing thread to reuse,
        // so it always creates fresh, same as before.
        final singleStudentScope = filteredRecipientCodes.length == 1
            ? filteredRecipientCodes.first
            : '';

        final result = await _createOrOpenConversationUseCase(
          type: isAdminChat
              ? ConversationType.adminChat
              : ConversationType.roomChat,
          studentCode: singleStudentScope,
          participantCodes: [
            if (actualSenderCode.isNotEmpty) actualSenderCode,
            ...filteredRecipientCodes,
          ],
          title: (recipients.first['name'] as String? ?? '').trim(),
          description: messageText,
        );

        await result.fold(
          (_) {
            failed.addAll(recipients);
          },
          (conversation) async {
            if (messageText.isNotEmpty) {
              final msg = Message(
                id: 'bulk-${DateTime.now().millisecondsSinceEpoch}',
                code: '',
                text: messageText,
                isSentByMe: true,
                senderUserCode: senderUserCode.isNotEmpty
                    ? senderUserCode
                    : actualSenderCode,
                time: DateTime.now(),
              );
              await _sendMessageUseCase(conversation.code, msg);
            }
          },
        );
      }

      // Notify the conversation list to refresh now that all conversations and
      // messages have been created. The cubit may be closed at this point
      // (compose screen was disposed when isBulkStarted fired), so we emit
      // only if still open but ALWAYS broadcast the list-changed event.
      MessagingEventService.instance.notifyConversationListChanged(
        conversationType,
      );

      if (!isClosed) {
        emit(state.copyWith(
          isSuccess: failed.isEmpty,
          failedRecipients: failed,
          progressMessage: failed.isEmpty
              ? ''
              : '${failed.length} message(s) failed to send. Tap retry.',
        ));
      }
    } catch (_) {
      // Catastrophic failure — mark all recipients as failed so retry is offered.
      MessagingEventService.instance.notifyConversationListChanged(
        conversationType,
      );
      if (!isClosed) {
        emit(state.copyWith(
          failedRecipients: recipients,
          progressMessage: 'Bulk send failed. Tap retry.',
        ));
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
