import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_input_bar.dart';

/// Full-screen conversation thread for v2 conversations (STAFF_DIRECT, ROOM_CHAT, ADMIN_CHAT).
class ConversationThreadScreen extends StatefulWidget {
  const ConversationThreadScreen({super.key, required this.conversation});

  final ConversationEntity conversation;

  @override
  State<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen> {
  late final ConversationThreadCubit _cubit;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _senderCode = '';
  String _senderName = '';
  ParticipantRole _senderRole = ParticipantRole.staff;
  String _organizationCode = '';
  String _schoolCode = '';

  @override
  void initState() {
    super.initState();
    _cubit = ConversationThreadCubit(
      conversationCode: widget.conversation.code,
      getMessagesUseCase: serviceLocator(),
      sendMessageUseCase: serviceLocator(),
      editMessageUseCase: serviceLocator(),
      deleteMessageUseCase: serviceLocator(),
      addReactionUseCase: serviceLocator(),
      removeReactionUseCase: serviceLocator(),
      markConversationReadUseCase: serviceLocator(),
    );
    unawaited(_cubit.loadMessages());
    unawaited(_loadSenderInfo());
  }

  Future<void> _loadSenderInfo() async {
    final storage = serviceLocator<StorageService>();
    final userCode =
        (await storage.getString(StorageKeys.userCode) ?? '').trim();
    final displayName =
        (await storage.getString(StorageKeys.displayName) ?? '').trim();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final school =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final rolesRaw =
        (await storage.getString(StorageKeys.roles) ?? '').trim().toUpperCase();

    if (!mounted) return;
    setState(() {
      _senderCode = userCode;
      _senderName = displayName.isNotEmpty ? displayName : userCode;
      _organizationCode = orgCode;
      _schoolCode = school;
      _senderRole = ParticipantRole.fromApiString(rolesRaw);
    });
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Participants dialog ────────────────────────────────────────────────────

  List<ParticipantDisplayData> get _participantData =>
      widget.conversation.participants.map((p) {
        final roleStr = p.role.toApiString().toUpperCase();
        // Normalise PARENT → GUARDIAN so the dialog groups correctly.
        final normalised =
            roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
        return ParticipantDisplayData(
          userCode: p.userCode,
          displayName: p.userName.isNotEmpty ? p.userName : p.userCode,
          role: normalised,
        );
      }).toList();

  void _showParticipantsDialog() {
    final studentName = widget.conversation.title;
    ParticipantInfoDialog.show(
      context,
      participants: _participantData,
      studentName: studentName,
    );
  }

  // ── Attachment bottom sheet ────────────────────────────────────────────────

  void _showAttachmentSheet() {
    MessageAttachmentBottomSheet.show(
      context,
      onAttachmentsSelected: (_) {
        // ConversationThreadScreen uses text-only send for now;
        // attachment support can be wired when the send usecase supports it.
      },
      onEmojiSelected: (emoji) {
        final pos = _inputController.selection.isValid
            ? _inputController.selection.baseOffset
            : _inputController.text.length;
        final text = _inputController.text;
        _inputController.value = _inputController.value.copyWith(
          text: text.substring(0, pos) + emoji + text.substring(pos),
          selection: TextSelection.collapsed(offset: pos + emoji.length),
        );
      },
      onViewParticipants: _showParticipantsDialog,
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _senderCode.isEmpty) return;
    _inputController.clear();
    await _cubit.sendMessage(
      text: text,
      senderCode: _senderCode,
      senderName: _senderName,
      senderRole: _senderRole,
      organizationCode: _organizationCode,
      schoolCode: _schoolCode,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationThreadCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: AppColors.primaryColor),
          title: Text(
            widget.conversation.title.isNotEmpty
                ? widget.conversation.title
                : 'Conversation',
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            Tooltip(
              message: 'View Participants',
              child: IconButton(
                icon: Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryColor),
                onPressed: _showParticipantsDialog,
              ),
            ),
          ],
        ),
        body: BlocConsumer<ConversationThreadCubit, ConversationThreadState>(
          listener: (context, state) {
            if (state.hasMessages) _scrollToBottom();
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(child: _buildMessageList(state)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: ChatInputBar(
                      controller: _inputController,
                      isSending: state.isSending,
                      onSend: () => unawaited(_sendMessage()),
                      onAttachmentTap: _showAttachmentSheet,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageList(ConversationThreadState state) {
    if (state.isLoading && !state.hasMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasMessages && state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.primaryColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF636E72)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _cubit.loadMessages,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.hasMessages) {
      return const Center(
        child: Text(
          'No messages yet. Say hello!',
          style: TextStyle(color: Color(0xFFB2BEC3), fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cubit.refreshMessages,
      color: AppColors.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final isMe = message.senderCode == _senderCode;
          return _MessageBubble(message: message, isMe: isMe);
        },
      ),
    );
  }

}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final MessageEntity message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.isDeleted;
    final isPending = message.isPending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.15),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF636E72),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDeleted
                        ? const Color(0xFFF1F3F5)
                        : isMe
                            ? AppColors.primaryColor
                            : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: isDeleted
                      ? Text(
                          message.deletedPlaceholder ?? 'Message deleted',
                          style: const TextStyle(
                            color: Color(0xFFB2BEC3),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          message.text,
                          style: TextStyle(
                            color:
                                isMe ? Colors.white : AppColors.primaryColor,
                            fontSize: 15,
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.sentAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFB2BEC3),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isPending
                            ? Icons.access_time_rounded
                            : message.isFailed
                                ? Icons.error_outline_rounded
                                : Icons.done_all_rounded,
                        size: 12,
                        color: message.isFailed
                            ? Colors.red
                            : const Color(0xFFB2BEC3),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final local = SchoolZoneDateTime.dateTimeFromInstantInSchool(dt, tz);
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
