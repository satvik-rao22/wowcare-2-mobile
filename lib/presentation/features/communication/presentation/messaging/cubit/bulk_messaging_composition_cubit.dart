import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/communication/models/create_conversation_request.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/usecases/create_conversation_usecase.dart';
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
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String progressMessage;

  const BulkMessagingCompositionState({
    this.selectedRecipients = const [],
    this.selectedRecipientNames = const [],
    this.attachments = const [],
    this.messageText = '',
    this.isStaff = true,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.progressMessage = '',
  });

  int get charCount => messageText.length;
  bool get canSend =>
      !isLoading && (messageText.trim().isNotEmpty || attachments.isNotEmpty);

  BulkMessagingCompositionState copyWith({
    List<Map<String, dynamic>>? selectedRecipients,
    List<String>? selectedRecipientNames,
    List<SelectedAttachment>? attachments,
    String? messageText,
    bool? isStaff,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    String? progressMessage,
  }) {
    return BulkMessagingCompositionState(
      selectedRecipients: selectedRecipients ?? this.selectedRecipients,
      selectedRecipientNames:
          selectedRecipientNames ?? this.selectedRecipientNames,
      attachments: attachments ?? this.attachments,
      messageText: messageText ?? this.messageText,
      isStaff: isStaff ?? this.isStaff,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage, // Reset error if not provided
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedRecipients,
    selectedRecipientNames,
    attachments,
    messageText,
    isStaff,
    isLoading,
    isSuccess,
    errorMessage,
    progressMessage,
  ];
}

class BulkMessagingCompositionCubit
    extends Cubit<BulkMessagingCompositionState> {
  final CreateConversationUseCase _createConversationUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final StorageService _storageService;

  BulkMessagingCompositionCubit({
    required List<Map<String, dynamic>> initialRecipients,
    required bool isStaff,
    required CreateConversationUseCase createConversationUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required StorageService storageService,
  }) : _createConversationUseCase = createConversationUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _storageService = storageService,
       super(
         BulkMessagingCompositionState(
           isStaff: isStaff,
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

  Future<void> sendMessages() async {
    if (!state.canSend) return;

    emit(
      state.copyWith(
        isLoading: true,
        isSuccess: false,
        errorMessage: null,
        progressMessage: 'Initializing...',
      ),
    );

    try {
      final orgCode =
          await _storageService.getString(StorageKeys.organizationCode) ?? '';
      if (isClosed) return;
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (isClosed) return;

      if (orgCode.isEmpty || schoolCode.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Organization or School code not found.',
          ),
        );
        return;
      }

      final senderCode =
          (await _storageService.getString(StorageKeys.staffCode) ?? '').trim();
      final senderUserCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      final actualSenderCode = senderCode.isNotEmpty ? senderCode : senderUserCode;

      if (isClosed) return;
      final messageText = state.messageText.trim();

      if (state.isStaff) {
        // Staff: One-to-One chat for each recipient
        int successCount = 0;
        for (var i = 0; i < state.selectedRecipients.length; i++) {
          if (isClosed) return;
          final recipient = state.selectedRecipients[i];
          final recipientCode = _recipientCode(recipient);
          final recipientName = (recipient['name'] ?? 'recipient').toString();
          if (recipientCode.isEmpty) continue;

          emit(
            state.copyWith(
              progressMessage:
                  'Sending to $recipientName (${i + 1}/${state.selectedRecipients.length})...',
            ),
          );

          final request = CreateConversationRequest(
            title: recipientName,
            type: 'STAFF_DIRECT',
            description: messageText,
            organizationCode: orgCode,
            schoolCode: schoolCode,
            participants: [
              {
                'userCode': actualSenderCode,
                'participantType': 'STAFF',
              },
              {
                'userCode': recipientCode,
                'participantType': 'STAFF',
              }
            ],
          );

          final result = await _createConversationUseCase(request);
          if (isClosed) return;

          await result.fold(
            (_) async {},
            (conversation) async {
              successCount++;
              // Backend ignores initialMessage field — send as a real message.
              if (messageText.isNotEmpty) {
                final msg = Message(
                  id: 'bulk-${DateTime.now().millisecondsSinceEpoch}',
                  code: '',
                  text: messageText,
                  isSentByMe: true,
                  senderUserCode: senderUserCode.isNotEmpty ? senderUserCode : actualSenderCode,
                  time: DateTime.now(),
                );
                await _sendMessageUseCase(conversation.code, msg);
              }
            },
          );
          if (isClosed) return;
        }

        if (successCount == state.selectedRecipients.length) {
          emit(
            state.copyWith(
              isLoading: false,
              isSuccess: true,
              progressMessage: 'All messages sent successfully!',
            ),
          );
        } else if (successCount > 0) {
          emit(
            state.copyWith(
              isLoading: false,
              isSuccess: true,
              progressMessage:
                  'Sent $successCount of ${state.selectedRecipients.length} messages.',
            ),
          );
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: 'Failed to send messages.',
            ),
          );
        }
      } else {
        // Parents/Students: Group Chat with all recipients
        emit(state.copyWith(progressMessage: 'Creating group chat...'));

        final recipientCodes = state.selectedRecipients
            .map(_recipientCode)
            .where((code) => code.isNotEmpty)
            .toSet()
            .toList();

        if (recipientCodes.isEmpty) {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: 'No valid recipients found.',
            ),
          );
          return;
        }

        final request = CreateConversationRequest(
          title: 'Bulk Message ${DateTime.now().toString().substring(0, 16)}',
          type: 'ROOM_CHAT',
          description: messageText,
          organizationCode: orgCode,
          schoolCode: schoolCode,
          participants: [
            if (actualSenderCode.isNotEmpty)
              {
                'userCode': actualSenderCode,
                'participantType': 'STAFF',
              },
            ...recipientCodes.map((code) => {
                  'userCode': code,
                  'participantType':
                      code.startsWith('STF_') ? 'STAFF' : 'GUARDIAN',
                }),
          ],
        );

        final result = await _createConversationUseCase(request);
        if (isClosed) return;

        await result.fold(
          (failure) async => emit(
            state.copyWith(
              isLoading: false,
              errorMessage: failure.message ?? 'Failed to send message.',
            ),
          ),
          (conversation) async {
            // Backend ignores initialMessage field — send as a real message.
            if (messageText.isNotEmpty) {
              final msg = Message(
                id: 'bulk-${DateTime.now().millisecondsSinceEpoch}',
                code: '',
                text: messageText,
                isSentByMe: true,
                senderUserCode: senderUserCode.isNotEmpty ? senderUserCode : actualSenderCode,
                time: DateTime.now(),
              );
              await _sendMessageUseCase(conversation.code, msg);
            }
            emit(
              state.copyWith(
                isLoading: false,
                isSuccess: true,
                progressMessage: 'Group message sent successfully!',
              ),
            );
          },
        );
      }
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'An unexpected error occurred: $e',
        ),
      );
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
