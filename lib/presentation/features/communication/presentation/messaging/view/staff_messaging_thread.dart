import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/attachment_widget.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
import '../../../../../../domain/features/communication/entities/message.dart';
import '../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../shared/common/widgets/gradient_add_button.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';
import '../widgets/message_bubble_widget.dart';

class StaffMessagingThread extends StatefulWidget {
  const StaffMessagingThread({super.key, required this.staffInfo});
  final Map<String, dynamic> staffInfo;

  @override
  State<StaffMessagingThread> createState() => _StaffMessagingThreadState();
}

class _StaffMessagingThreadState extends State<StaffMessagingThread> {
  //final ScrollController _scrollController = ScrollController();
  final AutoScrollController _scrollController = AutoScrollController();
  final TextEditingController _controller = TextEditingController();

  final List<Message> _messages = [
    Message(
      id: const Uuid().v4(),
      text: "Hello! I want to take day off tomorrow ?",
      isSentByMe: false,
      time: DateTime(2025, 1, 13, 14, 45),
      reactions: {
        'natasha': '😂',
        'eddie': '😂',
        'john': '😂',
        'manager': '👍',
      },
    ),
    Message(
      id: const Uuid().v4(),
      text: "Okay Natasha!",
      isSentByMe: true,
      time: DateTime(2025, 1, 13, 16, 45),
      attachments: [
        ChatAttachment(
          name: 'Vacation Request.pdf',
          type: 'document',
          sizeBytes: 1240000,
          mimeType: 'application/pdf',
          remoteUrl:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        ),
      ],
    ),
    Message(
      id: const Uuid().v4(),
      text: "Great to know that! Thanks!",
      isSentByMe: false,
      time: DateTime(2025, 1, 13, 16, 50),
      reactions: {'manager': '🙏', 'hr': '🙏', 'john': '🙏'},
    ),
    Message(
      id: const Uuid().v4(),
      text:
          "Also, is it possible to make it half day instead? I have doctor appointment in morning",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 9, 12),
      deliveredAt: DateTime(2025, 1, 14, 9, 12),
      reactions: {
        'natasha': '👍',
        'eddie': '👍',
        'john': '❤️',
        'manager': '🙏',
        'hr': '🙏',
      },
      attachments: [
        ChatAttachment(
          name: 'Doctor Appointment Letter.jpg',
          type: 'image',
          sizeBytes: 3200000,
          mimeType: 'image/jpeg',
          remoteUrl:
              "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
        ),
        ChatAttachment(
          name: 'Medical Certificate.pdf',
          type: 'document',
          sizeBytes: 1450000,
          mimeType: 'application/pdf',
          remoteUrl:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        ),
      ],
    ),
    Message(
      id: const Uuid().v4(),
      text:
          "Sure, half day is fine. Just mark it in the attendance sheet when you come back",
      isSentByMe: true,
      time: DateTime(2025, 1, 14, 9, 18),
      readAt: DateTime(2025, 1, 14, 9, 18),
      reactions: {
        'natasha': '😂',
        'eddie': '😂',
        'john': '😂',
        'manager': '👍',
        'natashi': '👍',
        'eddiey': '👍',
        'johny': '❤️',
        'managery': '🙏',
        'hr': '🙏',
      },
      attachments: [
        ChatAttachment(
          name: 'Team Meeting Notes.pdf',
          type: 'document',
          sizeBytes: 980000,
          mimeType: 'application/pdf',
          remoteUrl:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        ),
      ],
    ),
    Message(
      id: const Uuid().v4(),
      text: "Thank you so much! ❤️ Will do",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 9, 20),
      attachments: [
        ChatAttachment(
          name: 'Thank You Card.jpg',
          type: 'image',
          sizeBytes: 2100000,
          mimeType: 'image/jpeg',
          remoteUrl:
              "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
        ),
      ],
    ),
    Message(
      id: const Uuid().v4(),
      text:
          "By the way, did you see the new leave policy update? They added 2 extra optional holidays this year",
      isSentByMe: true,
      time: DateTime(2025, 1, 14, 11, 5),
      readAt: DateTime(2025, 1, 14, 11, 5),
      attachments: [
        ChatAttachment(
          name: 'New Leave Policy 2025.pdf',
          type: 'document',
          sizeBytes: 2800000,
          mimeType: 'application/pdf',
          remoteUrl:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        ),
      ],
    ),
    Message(
      id: const Uuid().v4(),
      text: "No I didn't! Where can I find it? HR portal?",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 11, 8),
      attachments: [
        ChatAttachment(
          name: 'HR Portal Screenshot.jpg',
          type: 'image',
          sizeBytes: 1800000,
          mimeType: 'image/jpeg',
          remoteUrl:
              'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
        ),
        ChatAttachment(
          name: 'Policies Folder.jpg',
          type: 'image',
          sizeBytes: 1450000,
          mimeType: 'image/jpeg',
          remoteUrl:
              "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
        ),
      ],
    ),
    Message(
      id: const Uuid().v4(),
      text:
          "Yes, under Policies → Leave & Attendance → 2025 updates. It's the pinned document",
      isSentByMe: true,
      time: DateTime(2026, 1, 21, 11, 11),
      deliveredTo: [
        RecipientStatus(
          name: "Natasha White",
          timestamp: DateTime(2026, 1, 21, 11, 12),
        ),
        RecipientStatus(
          name: "Eddie Barns",
          timestamp: DateTime(2026, 1, 21, 11, 13),
        ),
        RecipientStatus(
          name: "John Doe",
          timestamp: DateTime(2026, 1, 21, 11, 15),
        ),
        RecipientStatus(
          name: "Natasha White",
          timestamp: DateTime(2026, 1, 21, 11, 12),
        ),
        RecipientStatus(
          name: "Eddie Barns",
          timestamp: DateTime(2026, 1, 21, 11, 13),
        ),
        RecipientStatus(
          name: "John Doe",
          timestamp: DateTime(2026, 1, 21, 11, 15),
        ),
      ],
      readBy: [
        RecipientStatus(
          name: "Natasha White",
          timestamp: DateTime(2026, 1, 21, 11, 14),
        ),
        RecipientStatus(
          name: "Eddie Barns",
          timestamp: DateTime(2026, 1, 21, 11, 16),
        ),
        RecipientStatus(
          name: "Natasha White",
          timestamp: DateTime(2026, 1, 21, 11, 12),
        ),
        RecipientStatus(
          name: "Eddie Barns",
          timestamp: DateTime(2026, 1, 21, 11, 13),
        ),
        RecipientStatus(
          name: "John Doe",
          timestamp: DateTime(2026, 1, 21, 11, 15),
        ),
      ],
      attachments: [
        ChatAttachment(
          name: 'Policy Update Screenshot 1.jpg',
          type: 'image',
          sizeBytes: 2400000,
          mimeType: 'image/jpeg',
          remoteUrl:
              "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
        ),
        ChatAttachment(
          name: 'Policy Update Screenshot 2.jpg',
          type: 'image',
          sizeBytes: 2100000,
          mimeType: 'image/jpeg',
          remoteUrl:
              'https://images.unsplash.com/photo-1554224154-22dec7ec8818?w=800&q=80',
        ),
        ChatAttachment(
          name: 'Policy Update Screenshot 3.jpg',
          type: 'image',
          sizeBytes: 1950000,
          mimeType: 'image/jpeg',
          remoteUrl:
              "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
        ),
        ChatAttachment(
          name: 'Policy Update Screenshot 4.jpg',
          type: 'image',
          sizeBytes: 2300000,
          mimeType: 'image/jpeg',
          remoteUrl:
              "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
        ),
        ChatAttachment(
          name: 'Policy Update Screenshot 5.jpg',
          type: 'image',
          sizeBytes: 2050000,
          mimeType: 'image/jpeg',
          remoteUrl:
              "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
        ),
      ],
    ),
  ];
  late final ReactionsController _reactionsController;

  Message? _quotedMessage = null;
  String? _quotedMessageId;
  List<ChatAttachment> _pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    _reactionsController = ReactionsController(currentUserId: 'me'); // for now
  }

  @override
  void dispose() {
    _reactionsController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    //if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    final hasText = text.isNotEmpty;
    final hasAttachments = _pendingAttachments.isNotEmpty;

    if (!hasText && !hasAttachments) return;

    final now = DateTime.now();
    final newMessage = Message(
      id: const Uuid().v4(),
      text: _controller.text.trim(),
      isSentByMe: true,
      time: now,
      deliveredAt: null,
      readAt: null,
      attachments: List.from(_pendingAttachments),
      quotedMessageId: _quotedMessageId,
      // For group simulation
      // deliveredTo: {},
      // readBy: {},
    );
    setState(() {
      _messages.add(newMessage);
      _controller.clear();
      _pendingAttachments.clear();
      _quotedMessage = null;
      _quotedMessageId = null;
    });

    //_controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.scrollToIndex(
        0,
        preferPosition: AutoScrollPosition.begin,
        duration: const Duration(milliseconds: 300),
      );
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == newMessage.id);
        if (idx == -1) return;

        _messages[idx] = Message(
          id: newMessage.id,
          text: newMessage.text,
          isSentByMe: true,
          time: newMessage.time,
          deliveredAt: DateTime.now(),
          readAt: newMessage.readAt,
          attachments: newMessage.attachments,
          quotedMessageId: newMessage.quotedMessageId,
          // deliveredTo: newMessage.deliveredTo,
        );
      });
    });

    Future.delayed(const Duration(seconds: 7), () {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == newMessage.id);
        if (idx == -1) return;

        _messages[idx] = Message(
          id: newMessage.id,
          text: newMessage.text,
          isSentByMe: true,
          time: newMessage.time,
          deliveredAt: _messages[idx].deliveredAt,
          readAt: DateTime.now(),
          attachments: newMessage.attachments,
          quotedMessageId: newMessage.quotedMessageId,
          // readBy: {'user123': DateTime.now()},
        );
        //_quotedMessageId = null;
      });
    });
  }

  int? _getReversedIndex(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return null;
    return _messages.length - 1 - index;
  }

  void _scrollToMessage(String messageId) {
    final index = _getReversedIndex(messageId);
    if (index == null) {
      print("Message $messageId not found");
      return;
    }

    _scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.middle,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    Message message,
    LongPressStartDetails details,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          details.globalPosition.dx,
          details.globalPosition.dy,
          40,
          40,
        ),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        if (message.isSentByMe) ...[
          const PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: AppColors.primaryColor),
              title: CustomTextWidget(
                text: 'Edit',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                applyLetterSpacing: false,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: AppColors.primaryColor,
              ),
              title: CustomTextWidget(
                text: 'Delete',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                applyLetterSpacing: false,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        const PopupMenuItem<String>(
          value: 'reply',
          child: ListTile(
            leading: Icon(Icons.reply, color: AppColors.primaryColor),
            title: CustomTextWidget(
              text: 'Reply',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              applyLetterSpacing: false,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.copy, color: AppColors.primaryColor),
            title: CustomTextWidget(
              text: 'Copy',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              applyLetterSpacing: false,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'info',
          child: ListTile(
            leading: Icon(Icons.info, color: AppColors.primaryColor),
            title: CustomTextWidget(
              text: 'Info',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              applyLetterSpacing: false,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'react',
          child: ListTile(
            leading: Icon(Icons.emoji_emotions_outlined),
            title: Text('React'),
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'reply':
          setState(() {
            _quotedMessageId = message.id;
            _quotedMessage = message;
          });
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: message.text));
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Message copied successfully',
            isSuccess: true,
          );
          break;
        case 'info':
          _showMessageStatusDialog(context, message);
          break;
        case 'edit':
          _showEditDialog(context, message);
          break;

        case 'delete':
          setState(() {
            _messages.removeWhere((m) => m.id == message.id);
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Message deleted successfully',
              isSuccess: true,
            );
          });
          break;
        case 'react':
          _showEmojiPicker(context, message);
          break;
      }
    });
  }

  void _showEmojiPicker(BuildContext context, Message message) {
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
              _onReactionAdded(message, emoji.emoji);
            },
            config: const Config(
              //height: 380,
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

  void _onReactionAdded(Message message, String emoji) {
    final currentUserId = 'me'; // dummy for now
    setState(() {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        final currentReactions = Map<String, String>.from(
          _messages[index].reactions,
        );
        currentReactions[currentUserId] = emoji;
        _messages[index] = Message(
          id: _messages[index].id,
          text: _messages[index].text,
          isSentByMe: _messages[index].isSentByMe,
          time: _messages[index].time,
          deliveredAt: _messages[index].deliveredAt,
          readAt: _messages[index].readAt,
          deliveredTo: _messages[index].deliveredTo,
          readBy: _messages[index].readBy,
          attachments: _messages[index].attachments,
          reactions: currentReactions,
        );
      }
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(
      //   SnackBar(
      //     content: Text('Reacted with $emoji'),
      //   ),
      // );
    });
  }

  void _showEditDialog(BuildContext context, Message message) {
    final TextEditingController editingController = TextEditingController(
      text: message.text,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,

        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          //height: 60,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(89, 120, 247, 0.1),
                Color.fromRGBO(156, 132, 255, 0.1),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomTextWidget(text: 'Edit message'),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: Icon(Icons.clear, color: AppColors.primaryColor),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: editingController,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Edit your message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              //border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 60,
            //padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: TextButton(
              onPressed: () {
                final newText = editingController.text.trim();
                if (newText.isNotEmpty && newText != message.text) {
                  setState(() {
                    final idx = _messages.indexWhere((m) => m.id == message.id);
                    if (idx != -1) {
                      _messages[idx] = Message(
                        id: message.id,
                        text: newText,
                        isSentByMe: message.isSentByMe,
                        time: message.time,
                        deliveredAt: message.deliveredAt,
                        readAt: message.readAt,
                        deliveredTo: message.deliveredTo,
                        readBy: message.readBy,
                        attachments: message.attachments,
                        reactions: message.reactions,
                      );
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Message updated successfully',
                        isSuccess: true,
                      );
                    }
                  });
                }
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(overlayColor: Colors.transparent),
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: !isLandscape,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF4F7FD),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              _messages[_messages.length - 1 - index];
                          final messageId = message.id;
                          //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                          // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                          // final key = keyMap.putIfAbsent(
                          //   messageId,
                          //   () => GlobalKey(),
                          // );
                          Message? quotedMessage;
                          if (message.quotedMessageId != null) {
                            quotedMessage = _messages.firstWhere(
                              (m) => m.id == message.quotedMessageId,
                            ); // ?? null;
                          }
                          bool showDateHeader = false;
                          final prevListIndex = _messages.length - 2 - index;

                          if (prevListIndex >= 0) {
                            final prevMessage = _messages[prevListIndex];

                            showDateHeader =
                                message.time.year != prevMessage.time.year ||
                                message.time.month != prevMessage.time.month ||
                                message.time.day != prevMessage.time.day;
                          } else {
                            showDateHeader = true;
                          }

                          return AutoScrollTag(
                            key: ValueKey(messageId),
                            controller: _scrollController,
                            index: index,
                            highlightColor: Colors.green.withValues(alpha: 0.7),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showDateHeader)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: _buildDateChip(message.time),
                                    ),
                                  ),
                                if (showDateHeader) const SizedBox(height: 10),
                                MessageBubble(
                                  //key: key,
                                  //scrollKey: scrollKey,
                                  message: message,
                                  quotedMessage: quotedMessage,
                                  onLongPress: (LongPressStartDetails details) {
                                    _showMessageOptions(
                                      context,
                                      message,
                                      details,
                                    );
                                  },
                                  onScrollToQuoted: (quoteId) {
                                    _scrollToMessage(quoteId);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: SingleChildScrollView(
                      reverse: true, // new messages appear at bottom
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          child: _buildMessageInput(),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
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
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: const Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE9ECEF),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      DocumentImageWidget(
                                        fileUuid: widget.staffInfo['avatar'],
                                        name: widget.staffInfo['name'],
                                        size: 45,
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: widget.staffInfo['isSigned']
                                                ? const Color.fromRGBO(
                                                    0,
                                                    177,
                                                    21,
                                                    1,
                                                  )
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  widget.staffInfo['isSigned']
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: CustomTextWidget(
                                      text: widget.staffInfo['name'],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              reverse: true,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    _messages[_messages.length - 1 - index];
                                final messageId = message.id;
                                //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                                // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                                // final key = keyMap.putIfAbsent(
                                //   messageId,
                                //   () => GlobalKey(),
                                // );
                                Message? quotedMessage;
                                if (message.quotedMessageId != null) {
                                  quotedMessage = _messages.firstWhere(
                                    (m) => m.id == message.quotedMessageId,
                                  ); // ?? null;
                                }
                                bool showDateHeader = false;
                                final prevListIndex =
                                    _messages.length - 2 - index;

                                if (prevListIndex >= 0) {
                                  final prevMessage = _messages[prevListIndex];

                                  showDateHeader =
                                      message.time.year !=
                                          prevMessage.time.year ||
                                      message.time.month !=
                                          prevMessage.time.month ||
                                      message.time.day != prevMessage.time.day;
                                } else {
                                  showDateHeader = true;
                                }

                                return AutoScrollTag(
                                  key: ValueKey(messageId),
                                  controller: _scrollController,
                                  index: index,
                                  highlightColor: Colors.green.withValues(
                                    alpha: 0.7,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showDateHeader)
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: _buildDateChip(message.time),
                                          ),
                                        ),
                                      if (showDateHeader)
                                        const SizedBox(height: 10),

                                      MessageBubble(
                                        //key: key,
                                        //scrollKey: scrollKey,
                                        message: message,
                                        quotedMessage: quotedMessage,
                                        onLongPress:
                                            (LongPressStartDetails details) {
                                              _showMessageOptions(
                                                context,
                                                message,
                                                details,
                                              );
                                            },
                                        onScrollToQuoted: (quoteId) {
                                          _scrollToMessage(quoteId);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: _buildMessageInput(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_quotedMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromRGBO(89, 120, 247, 0.1),
                      Color.fromRGBO(156, 132, 255, 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextWidget(
                        text: _quotedMessage?.text,
                        fontSize: 14,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _quotedMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            if (_pendingAttachments.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 90),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pendingAttachments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final att = _pendingAttachments[index];

                    return SizedBox(
                      width: 80,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShowFullScreenMediaView(
                                imageFile: File(att.localPath!),
                                title: att.name,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          fit: StackFit.loose,
                          children: [
                            ClipRRect(
                              clipBehavior: Clip.none,
                              borderRadius: BorderRadius.circular(12),
                              child: Thumbnail(
                                mimeType:
                                    att.mimeType ?? 'application/octet-stream',
                                dataResolver: () async {
                                  return await File(
                                    att.localPath!,
                                  ).readAsBytes();
                                },
                                widgetSize: 80,
                                decoration: WidgetDecoration(
                                  backgroundColor: Colors.white,
                                  iconColor: AppColors.primaryColor,
                                  textColor: AppColors.primaryColor,
                                  wrapperBgColor: Colors.transparent,
                                  wrapperSize: 84,
                                ),
                                errorBuilder: (context, error) => Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      att.isImage
                                          ? Icons.image
                                          : Icons.picture_as_pdf,
                                      size: 40,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: -2.5,
                              right: -2.5,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _pendingAttachments.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(
                                      BorderSide(color: Colors.white, width: 2),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            if (!att.isImage)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    att.name.length > 15
                                        ? '${att.name.substring(0, 12)}...'
                                        : att.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.fromRGBO(89, 120, 247, 0.1),
                          Color.fromRGBO(156, 132, 255, 0.1),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 10,
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: 2000,
                            decoration: InputDecoration(
                              hintText: "Type your message here...",
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '$currentLength / $maxLength',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: currentLength >= maxLength!
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12,
                          ),
                          child: AttachmentWidget(
                            iconWidget: GradientAddButton(
                              wantedButtonSize: 28,
                              isRectangle: false,
                            ),
                            onAttachmentsSelected: (attachments) {
                              setState(() {
                                _pendingAttachments.addAll(attachments);
                              });
                            },
                          ),
                          // child: GradientAddButton(
                          //   onTap: () {},
                          //   wantedButtonSize: 26,
                          //   isRectangle: false,
                          // ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CustomClearAllChip(
                  onTap: () {
                    _sendMessage();
                  },
                  label: 'Send',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  borderRadius: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(DateTime date) {
    final now = DateTime.now();

    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final monthNames = [
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
      label = "Today, ${date.day} ${monthNames[date.month - 1]} ${date.year}";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      final monthNames = [
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
      label =
          "Yesterday, ${date.day} ${monthNames[date.month - 1]} ${date.year}";
    } else {
      final monthNames = [
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
      label = "${date.day} ${monthNames[date.month - 1]} ${date.year}";
    }

    return CustomTextWidget(
      text: label,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      applyLetterSpacing: false,
    );
  }

  void _showMessageStatusDialog(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(89, 120, 247, 0.1),
                Color.fromRGBO(156, 132, 255, 0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomTextWidget(
                text: 'Message Info',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.primaryColor),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomTextWidget(
                  text: 'Message Content',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    //color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor, width: 1),
                  ),
                  child: CustomTextWidget(
                    text: message.text,
                    fontSize: 15,
                    unlimitedLines: true,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Delivery & Read info
                _buildStatusSection(message),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const CustomTextWidget(
                text: 'Close',
                fontColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(Message message) {
    final hasDelivery = message.isDelivered;
    final hasRead = message.isRead;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDelivery || hasRead) ...[
          const CustomTextWidget(
            text: 'Status',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (hasDelivery)
                _buildRecipientList(
                  title: 'Delivered To',
                  icon: Icons.check_circle_outline,
                  recipients: message.deliveredTo,
                  fallbackTime: message.deliveredAt,
                  color: Colors.blueGrey,
                ),

              if (hasRead) ...[
                const SizedBox(height: 8),
                _buildRecipientList(
                  title: 'Read By',
                  icon: Icons.done_all,
                  recipients: message.readBy,
                  fallbackTime: message.readAt,
                  color: AppColors.primaryColor,
                ),
              ],
            ],
          ),
        ] else ...[
          const CustomTextWidget(
            text: 'Message is still sending...',
            fontSize: 14,
            fontColor: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildRecipientList({
    required String title,
    required IconData icon,
    required List<RecipientStatus> recipients,
    DateTime? fallbackTime,
    required Color color,
  }) {
    final count = recipients.length + (fallbackTime != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            CustomTextWidget(
              text: '$title ($count)',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (recipients.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: recipients
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: CustomTextWidget(text: r.name, fontSize: 13),
                          ),
                          if (r.timestamp != null) ...[
                            const SizedBox(width: 10),
                            CustomTextWidget(
                              text: _formatTimeShort(r.timestamp!),
                              fontSize: 12,
                              fontColor: Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
        // if (recipients.isNotEmpty)
        //   ...recipients.map((r) => Padding(
        //     padding: const EdgeInsets.only(left: 32, bottom: 6),
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Flexible(
        //           fit: FlexFit.loose,
        //           child: CustomTextWidget(
        //             text: r.name,
        //             fontSize: 13,
        //           ),
        //         ),
        //         if (r.timestamp != null) ...[
        //           const SizedBox(width: 4,),
        //           CustomTextWidget(
        //             text: _formatTimeShort(r.timestamp!),
        //             fontSize: 12,
        //             fontColor: Colors.grey.shade600,
        //           ),
        //         ]
        //
        //       ],
        //     ),
        //   ))
        else if (fallbackTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: CustomTextWidget(
              text: 'Recipient • ${_formatFullTime(fallbackTime)}',
              fontSize: 13,
              fontColor: Colors.grey.shade700,
            ),
          ),
      ],
    );
  }

  String _formatTimeShort(
    DateTime dt, {
    bool use24Hour = false,
    String separator = ':',
  }) {
    if (use24Hour) {
      return "${dt.hour.toString().padLeft(2, '0')}${separator}${dt.minute.toString().padLeft(2, '0')}";
    }

    final hour = dt.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$hour12$separator$minute $period';
  }
  // String _formatTimeShort(DateTime dt) {
  //   return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  // }

  String _formatFullTime(DateTime dt) {
    final now = DateTime.now();
    String dayPart =
        (dt.day == now.day && dt.month == now.month && dt.year == now.year)
        ? 'Today'
        : (dt.day == now.day - 1
              ? 'Yesterday'
              : '${dt.day} ${_monthName(dt.month)} ${dt.year}');

    return '$dayPart, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  String _monthName(int month) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
