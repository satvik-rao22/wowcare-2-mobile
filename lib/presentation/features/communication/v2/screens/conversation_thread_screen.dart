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
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

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

  // ── Participants ──────────────────────────────────────────────────────────

  List<ParticipantDisplayData> get _participantData =>
      widget.conversation.participants.map((p) {
        final roleStr = p.role.toApiString().toUpperCase();
        final normalised = roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
        return ParticipantDisplayData(
          userCode: p.userCode,
          displayName: p.userName.isNotEmpty ? p.userName : p.userCode,
          role: normalised,
        );
      }).toList();

  void _showParticipantsDialog() {
    ParticipantInfoDialog.show(
      context,
      participants: _participantData,
      studentName: widget.conversation.title,
    );
  }

  // ── Attachment sheet ──────────────────────────────────────────────────────

  void _showAttachmentSheet() {
    unawaited(MessageAttachmentBottomSheet.show(
      context,
      onAttachmentsSelected: (_) {},
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
    ));
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

  // ── Date chip ─────────────────────────────────────────────────────────────

  String _dateSeparatorLabel(DateTime date) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final d = SchoolZoneDateTime.dateTimeFromInstantInSchool(date, tz);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        DateTime.now().toUtc(), tz);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today, ${d.day} ${months[d.month - 1]} ${d.year}';
    } else if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day - 1) {
      return 'Yesterday, ${d.day} ${months[d.month - 1]} ${d.year}';
    }
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final da = SchoolZoneDateTime.dateTimeFromInstantInSchool(a, tz);
    final db = SchoolZoneDateTime.dateTimeFromInstantInSchool(b, tz);
    return da.year != db.year || da.month != db.month || da.day != db.day;
  }

  // ── Role color (matches parent messaging) ────────────────────────────────

  String _roleFallbackName(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'GUARDIAN':
        return 'Guardian';
      case 'STAFF':
        return 'Staff';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'GUARDIAN':
        return const Color(0xFF6C63FF);
      case 'STAFF':
        return const Color(0xFF00897B);
      case 'ADMIN':
        return const Color(0xFFE65100);
      default:
        return AppColors.primaryColor;
    }
  }

  // ── Participant header ────────────────────────────────────────────────────

  Widget _buildParticipantHeader() {
    final participants = widget.conversation.participants;
    final title = widget.conversation.title.isNotEmpty
        ? widget.conversation.title
        : 'Conversation';
    final count = participants.isNotEmpty ? participants.length : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border:
            Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      text: title,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    if (count != null)
                      Text(
                        '$count participant${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF636E72),
                        ),
                      ),
                  ],
                ),
              ),
              Tooltip(
                message: 'View Participants',
                child: IconButton(
                  icon: const Icon(Icons.info_outline_rounded,
                      color: AppColors.primaryColor),
                  onPressed: _showParticipantsDialog,
                ),
              ),
            ],
          ),
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: participants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final p = participants[index];
                  final roleStr =
                      p.role.toApiString().toUpperCase() == 'PARENT'
                          ? 'GUARDIAN'
                          : p.role.toApiString().toUpperCase();
                  // Always show display name — never fall back to userCode
                  final name = p.userName.isNotEmpty
                      ? p.userName
                      : _roleFallbackName(roleStr);
                  final initial =
                      name.isNotEmpty ? name[0].toUpperCase() : '?';
                  final color = _roleColor(roleStr);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor:
                              color.withValues(alpha: 0.25),
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            roleStr,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList(ConversationThreadState state) {
    if (state.isLoading && !state.hasMessages) {
      return const ChatThreadShimmer();
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

    final messages = state.messages;

    return RefreshIndicator(
      onRefresh: _cubit.refreshMessages,
      color: AppColors.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          // reverse: true means index 0 = last message
          final msg = messages[messages.length - 1 - index];
          final prevIndex = messages.length - 2 - index;
          final isMe = msg.senderCode == _senderCode;

          bool showDateHeader;
          if (prevIndex >= 0) {
            showDateHeader =
                _isDifferentDay(msg.sentAt, messages[prevIndex].sentAt);
          } else {
            showDateHeader = true;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDateHeader) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Center(
                    child: CustomTextWidget(
                      text: _dateSeparatorLabel(msg.sentAt),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      applyLetterSpacing: false,
                    ),
                  ),
                ),
              ],
              _ThreadMessageBubble(message: msg, isMe: isMe),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocProvider<ConversationThreadCubit>.value(
      value: _cubit,
      child: GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: !isLandscape,
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: BlocConsumer<ConversationThreadCubit, ConversationThreadState>(
            listener: (context, state) {
              if (state.hasMessages) _scrollToBottom();
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(text: 'Messaging', fontSize: 16),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF4F7FD),
                      ),
                      child: Column(
                        children: [
                          _buildParticipantHeader(),
                          Expanded(child: _buildMessageList(state)),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: ChatInputBar(
                              controller: _inputController,
                              isSending: state.isSending,
                              onSend: () => unawaited(_sendMessage()),
                              onAttachmentTap: _showAttachmentSheet,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Message bubble (matches parent messaging design) ─────────────────────────

class _ThreadMessageBubble extends StatelessWidget {
  const _ThreadMessageBubble({required this.message, required this.isMe});

  final MessageEntity message;
  final bool isMe;

  String _formatTime(DateTime dt) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final local = SchoolZoneDateTime.dateTimeFromInstantInSchool(dt, tz);
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.isDeleted;
    final isPending = message.isPending;
    final senderInitial = message.senderName.isNotEmpty
        ? message.senderName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // ── Avatar row ──────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor:
                        AppColors.primaryColor.withValues(alpha: 0.15),
                    child: Text(
                      senderInitial,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),

              // ── Sender name ──────────────────────────────────────────
              if (message.senderName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isMe ? 'You' : message.senderName,
                    style: const TextStyle(
                      color: Color.fromRGBO(87, 51, 83, 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),

              // ── Bubble ────────────────────────────────────────────────
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  margin: EdgeInsets.only(
                      left: isMe ? 60 : 0, right: isMe ? 0 : 60),
                  decoration: BoxDecoration(
                    color: isDeleted
                        ? const Color(0xFFF1F3F5)
                        : isMe
                            ? null
                            : const Color.fromRGBO(220, 230, 255, 1),
                    gradient: (!isDeleted && isMe)
                        ? AppColors.buildPrimaryGradient()
                        : null,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(isMe ? 70 : 50),
                      topLeft: Radius.circular(isMe ? 50 : 70),
                      bottomLeft: Radius.circular(isMe ? 50 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 50),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: isDeleted
                        ? const Text(
                            '🚫 This Message Has Been Deleted',
                            style: TextStyle(
                              color: Color.fromRGBO(87, 51, 83, 1),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            message.text,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : AppColors.primaryColor,
                              fontSize: 15.5,
                              fontFamily: 'Manrope',
                            ),
                          ),
                  ),
                ),
              ),

              // ── Time + status ────────────────────────────────────────
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.sentAt),
                    style: const TextStyle(
                      color: Color.fromRGBO(65, 65, 78, 0.5),
                      fontSize: 15,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isPending
                          ? Icons.access_time_rounded
                          : message.isFailed
                              ? Icons.error_outline_rounded
                              : Icons.done_all,
                      size: 16,
                      color: message.isFailed
                          ? Colors.red
                          : const Color.fromRGBO(65, 65, 78, 0.5),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
