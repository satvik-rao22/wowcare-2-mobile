import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_bubble_widget.dart';
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

  late final ReactionsController _reactionsController;
  MessageEntity? _quotedMessage;
  MessageEntity? _editingMessage;
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthCubit>().state;
    final userCodeFromAuth = authState is AuthLoaded
        ? authState.loginResponse.userCode.trim()
        : '';

    _reactionsController = ReactionsController(
      currentUserId: userCodeFromAuth.isNotEmpty ? userCodeFromAuth : 'me',
    );

    _cubit = ConversationThreadCubit(
      conversationCode: widget.conversation.code,
      watchMessagesUseCase: serviceLocator(),
      getMessagesUseCase: serviceLocator(),
      sendMessageUseCase: serviceLocator(),
      editMessageUseCase: serviceLocator(),
      deleteMessageUseCase: serviceLocator(),
      addReactionUseCase: serviceLocator(),
      removeReactionUseCase: serviceLocator(),
      markConversationReadUseCase: serviceLocator(),
    );
    _cubit.startWatchingMessages();
    unawaited(_loadSenderInfo());
  }

  Future<void> _loadSenderInfo() async {
    final storage = serviceLocator<StorageService>();
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    final displayName = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '')
        .trim()
        .toUpperCase();

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
    _reactionsController.dispose();
    _inputFocusNode.dispose();
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
    unawaited(
      MessageAttachmentBottomSheet.show(
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
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _senderCode.isEmpty) return;

    if (_editingMessage != null) {
      final messageCode = _editingMessage!.code;
      _inputController.clear();
      final originalEditMsg = _editingMessage!;
      setState(() {
        _editingMessage = null;
      });

      if (text != originalEditMsg.text) {
        await _cubit.editMessage(
          messageCode: messageCode,
          newText: text,
        );
        if (mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Message updated successfully',
            isSuccess: true,
          );
        }
      }
      return;
    }

    _inputController.clear();
    await _cubit.sendMessage(
      text: text,
      senderCode: _senderCode,
      senderName: _senderName,
      senderRole: _senderRole,
      organizationCode: _organizationCode,
      schoolCode: _schoolCode,
      threadParentCode: _quotedMessage?.code,
    );
    setState(() {
      _quotedMessage = null;
    });
    _scrollToBottom();
  }

  // ── Date chip ─────────────────────────────────────────────────────────────

  String _dateSeparatorLabel(DateTime date) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final d = SchoolZoneDateTime.dateTimeFromInstantInSchool(date, tz);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
      tz,
    );
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
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
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryColor,
                  ),
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
                  final roleStr = p.role.toApiString().toUpperCase() == 'PARENT'
                      ? 'GUARDIAN'
                      : p.role.toApiString().toUpperCase();
                  // Always show display name — never fall back to userCode
                  final name = p.userName.isNotEmpty
                      ? p.userName
                      : _roleFallbackName(roleStr);
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                  final color = _roleColor(roleStr);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: color.withValues(alpha: 0.25),
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
                            horizontal: 4,
                            vertical: 1,
                          ),
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
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
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

          bool showDateHeader;
          if (prevIndex >= 0) {
            showDateHeader = _isDifferentDay(
              msg.sentAt,
              messages[prevIndex].sentAt,
            );
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
              (() {
                final message = _mapEntityToMessage(msg, _senderCode);
                Message? quotedMessage;
                if (msg.threadParentCode != null) {
                  final parentMatches = messages.where(
                    (m) => m.code == msg.threadParentCode,
                  );
                  if (parentMatches.isNotEmpty) {
                    quotedMessage = _mapEntityToMessage(
                      parentMatches.first,
                      _senderCode,
                    );
                  }
                }
                return MessageBubble(
                  message: message,
                  quotedMessage: quotedMessage,
                  currentUserCode: _senderCode,
                  reactionsController: _reactionsController,
                  onScrollToQuoted: (quoteId) {
                    final matchIndex = messages.indexWhere(
                      (m) => m.code == quoteId || m.id == quoteId,
                    );
                    if (matchIndex != -1) {
                      _scrollController.animateTo(
                        (_scrollController.position.maxScrollExtent /
                                messages.length) *
                            (messages.length - 1 - matchIndex),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  onReply: () {
                    setState(() {
                      _quotedMessage = msg;
                    });
                  },
                  onReplyFromMenu: () {
                    setState(() {
                      _quotedMessage = msg;
                    });
                  },
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Message copied successfully',
                      isSuccess: true,
                    );
                  },
                  onEdit: () {
                    setState(() {
                      _editingMessage = msg;
                      _inputController.text = msg.text;
                    });
                    _inputFocusNode.requestFocus();
                  },
                  onDelete: () async {
                    await _cubit.deleteMessage(msg.code);
                    if (context.mounted) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Message deleted successfully',
                        isSuccess: true,
                      );
                    }
                  },
                  onReactionAdded: (emoji) {
                    final myReaction = msg.reactions[_senderCode];
                    if (myReaction == emoji) {
                      _cubit.removeReaction(
                        messageCode: msg.code,
                        emoji: emoji,
                        currentUserCode: _senderCode,
                      );
                    } else {
                      _cubit.addReaction(
                        messageCode: msg.code,
                        emoji: emoji,
                        currentUserCode: _senderCode,
                      );
                    }
                  },
                  onRemoveReaction: (emoji) {
                    _cubit.removeReaction(
                      messageCode: msg.code,
                      emoji: emoji,
                      currentUserCode: _senderCode,
                    );
                  },
                  onReactionTap: () => _showEmojiPicker(context, msg),
                  isParentMessaging: _senderRole == ParticipantRole.parent,
                  isDeleted: msg.isDeleted,
                );
              })(),
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
                                bottom: Radius.circular(12),
                              ),
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
                              focusNode: _inputFocusNode,
                              isSending: state.isSending,
                              onSend: () => unawaited(_sendMessage()),
                              onAttachmentTap: _showAttachmentSheet,
                              quotedMessage: _quotedMessage != null
                                  ? _mapEntityToMessage(
                                      _quotedMessage!,
                                      _senderCode,
                                    )
                                  : null,
                              onCancelQuote: () => setState(() {
                                _quotedMessage = null;
                              }),
                              editingMessage: _editingMessage != null
                                  ? _mapEntityToMessage(
                                      _editingMessage!,
                                      _senderCode,
                                    )
                                  : null,
                              onCancelEdit: () => setState(() {
                                _editingMessage = null;
                                _inputController.clear();
                              }),
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

  Message _mapEntityToMessage(MessageEntity entity, String currentUserCode) {
    return Message(
      id: entity.id,
      code: entity.code,
      text: entity.text,
      isSentByMe: entity.senderCode == currentUserCode,
      time: entity.sentAt,
      editedAt: entity.editedAt,
      reactions: entity.reactions,
      senderName: entity.senderName,
      senderUserCode: entity.senderCode,
      quotedMessageId: entity.threadParentCode,
      isPrivate: entity.isPrivate,
      attachments: entity.attachments
          .map(
            (a) => ChatAttachment(
              name: a.fileName,
              type: a.attachmentType == AttachmentType.image ? 'image' : 'file',
              sizeBytes: a.fileSizeBytes,
              mimeType: a.mimeType,
              remoteUrl: a.fileUrl,
              localPath: a.localFilePath,
            ),
          )
          .toList(),
    );
  }

  void _showEmojiPicker(BuildContext context, MessageEntity message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 380 + MediaQuery.of(context).padding.bottom,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context); // close picker
              final myReaction = message.reactions[_senderCode];
              if (myReaction == emoji.emoji) {
                _cubit.removeReaction(
                  messageCode: message.code,
                  emoji: emoji.emoji,
                  currentUserCode: _senderCode,
                );
              } else {
                _cubit.addReaction(
                  messageCode: message.code,
                  emoji: emoji.emoji,
                  currentUserCode: _senderCode,
                );
              }
            },
            config: const Config(
              checkPlatformCompatibility: true,
              emojiSet: null,
              locale: Locale('en'),
              emojiTextStyle: null,
              customBackspaceIcon: null,
              customSearchIcon: null,
              viewOrderConfig: ViewOrderConfig(),
              emojiViewConfig: EmojiViewConfig(),
              skinToneConfig: SkinToneConfig(enabled: true),
              categoryViewConfig: CategoryViewConfig(
                recentTabBehavior: RecentTabBehavior.RECENT,
              ),
              bottomActionBarConfig: BottomActionBarConfig(enabled: false),
              searchViewConfig: SearchViewConfig(),
            ),
          ),
        );
      },
    );
  }
}
