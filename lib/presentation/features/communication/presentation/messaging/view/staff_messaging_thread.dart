import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [
    Message(
      text: "Hello! I want to take day off tomorrow ?",
      isSentByMe: false,
      time: DateTime(2025, 1, 13, 14, 45),
    ),
    Message(
      text: "Okay Natasha!",
      isSentByMe: true,
      time: DateTime(2025, 1, 13, 16, 45),
      readAt: DateTime(2025, 1, 13, 16, 45),
    ),
    Message(
      text: "Great to know that! Thanks!",
      isSentByMe: false,
      time: DateTime(2025, 1, 13, 16, 50),
    ),
    Message(
      text:
          "Also, is it possible to make it half day instead? I have doctor appointment in morning",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 9, 12),
    ),
    Message(
      text:
          "Sure, half day is fine. Just mark it in the attendance sheet when you come back",
      isSentByMe: true,
      time: DateTime(2025, 1, 14, 9, 18),
      readAt: DateTime(2025, 1, 14, 9, 18),
    ),
    Message(
      text: "Thank you so much! ❤️ Will do",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 9, 20),
    ),
    Message(
      text:
          "By the way, did you see the new leave policy update? They added 2 extra optional holidays this year, By the way, did you see the new leave policy update? They added 2 extra optional holidays this year",
      isSentByMe: true,
      time: DateTime(2025, 1, 14, 11, 5),
      readAt: DateTime(2025, 1, 14, 11, 5),
    ),
    Message(
      text: "No I didn't! Where can I find it? HR portal?",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 11, 8),
    ),
    Message(
      text:
          "Yes, under Policies → Leave & Attendance → 2025 updates. It's the pinned documentBy the way, did you see the new leave policy update? They added 2 extra optional holidays this year, By the way, did you see the new leave policy update? They added 2 extra optional holidays this year",
      isSentByMe: true,
      time: DateTime(2026, 1, 21, 11, 11),
      deliveredTo: [
        RecipientStatus(name: "Natasha White", timestamp: DateTime(2026, 1, 21, 11, 12)),
        RecipientStatus(name: "Eddie Barns",   timestamp: DateTime(2026, 1, 21, 11, 13)),
        RecipientStatus(name: "John Doe",      timestamp: DateTime(2026, 1, 21, 11, 15)),
        RecipientStatus(name: "Natasha White", timestamp: DateTime(2026, 1, 21, 11, 12)),
        RecipientStatus(name: "Eddie Barns",   timestamp: DateTime(2026, 1, 21, 11, 13)),
        RecipientStatus(name: "John Doe",      timestamp: DateTime(2026, 1, 21, 11, 15)),
      ],
      readBy: [
        RecipientStatus(name: "Natasha White", timestamp: DateTime(2026, 1, 21, 11, 14)),
        RecipientStatus(name: "Eddie Barns",   timestamp: DateTime(2026, 1, 21, 11, 16)),
        RecipientStatus(name: "Natasha White", timestamp: DateTime(2026, 1, 21, 11, 12)),
        RecipientStatus(name: "Eddie Barns",   timestamp: DateTime(2026, 1, 21, 11, 13)),
        RecipientStatus(name: "John Doe",      timestamp: DateTime(2026, 1, 21, 11, 15)),
      ],
    ),
  ];
  late final ReactionsController _reactionsController;

  @override
  void initState(){
    super.initState();
    _reactionsController = ReactionsController(currentUserId: 'me'); // for now
  }

  @override
  void dispose(){
    _reactionsController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final now = DateTime.now();
    final newMessage = Message(
      text: _controller.text.trim(),
      isSentByMe: true,
      time: now,
      deliveredAt: null,
      readAt: null,
      // For group simulation
      // deliveredTo: {},
      // readBy: {},
    );
    setState(() {
      _messages.add(newMessage);
    });

    // setState(() {
    //   _messages.add(
    //     Message(
    //       text: _controller.text.trim(),
    //       isSentByMe: true,
    //       time: DateTime.now(),
    //       deliveredAt: null,
    //       readAt: null
    //     ),
    //   );
    // });

    _controller.clear();
    // Simulate delivery (works for both 1:1 and group)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        final idx = _messages.indexWhere((m) => m.time == newMessage.time);
        if (idx == -1) return;

        // For 1:1
        _messages[idx] = Message(
          text: newMessage.text,
          isSentByMe: true,
          time: newMessage.time,
          deliveredAt: DateTime.now(),
          readAt: newMessage.readAt,
          // deliveredTo: newMessage.deliveredTo, // if group
        );
      });
    });

    // Simulate read
    Future.delayed(const Duration(seconds: 7), () {
      setState(() {
        final idx = _messages.indexWhere((m) => m.time == newMessage.time);
        if (idx == -1) return;

        _messages[idx] = Message(
          text: newMessage.text,
          isSentByMe: true,
          time: newMessage.time,
          deliveredAt: _messages[idx].deliveredAt,
          readAt: DateTime.now(),
          // readBy: {'user123': DateTime.now()}, // for group
        );
      });
    });
  }

  void _showMessageOptions(BuildContext context, Message message, LongPressStartDetails details) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

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
                leading: Icon(Icons.edit, color: AppColors.primaryColor,),
                title: CustomTextWidget(text: 'Edit', fontSize: 15, fontWeight: FontWeight.w500, applyLetterSpacing: false,),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.primaryColor,),
                title: CustomTextWidget(text: 'Delete', fontSize: 15, fontWeight: FontWeight.w500, applyLetterSpacing: false, ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          const PopupMenuItem<String>(
            value: 'copy',
            child: ListTile(
              leading: Icon(Icons.copy, color: AppColors.primaryColor,),
              title: CustomTextWidget(text: 'Copy', fontSize: 15, fontWeight: FontWeight.w500, applyLetterSpacing: false,),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'info',
            child: ListTile(
              leading: Icon(Icons.info, color: AppColors.primaryColor,),
              title: CustomTextWidget(text: 'Info', fontSize: 15, fontWeight: FontWeight.w500, applyLetterSpacing: false,),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'copy':
          Clipboard.setData(ClipboardData(text: message.text));
          CoreUtils.showTopSnackBar(
              context: context,
              message: 'Message copied successfully',
              isSuccess: true
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
            _messages.removeWhere((m) => m.time == message.time);
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Message deleted successfully',
              isSuccess: true,
            );
          });
          break;
      }
    });
  }
  void _showEditDialog(BuildContext context, Message message) {
    final TextEditingController editingController = TextEditingController(text:  message.text);
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
              CustomTextWidget(text: 'Edit message',),
              IconButton(onPressed: () => Navigator.pop(dialogContext), icon: Icon(Icons.clear, color: AppColors.primaryColor,)),
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
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 2,
                ),
              ),
              //border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              borderRadius: BorderRadius.circular(
                16.0 ,
              ),
            ),
            child: TextButton(
              onPressed: (){
                final newText = editingController.text.trim();
                if (newText.isNotEmpty && newText != message.text) {
                  setState(() {
                    final idx = _messages.indexWhere((m) => m.time == message.time);
                    if (idx != -1) {
                      _messages[idx] = Message(
                        text: newText,
                        isSentByMe: message.isSentByMe,
                        time: message.time,
                        deliveredAt: message.deliveredAt,
                        readAt: message.readAt,
                        deliveredTo: message.deliveredTo,
                        readBy: message.readBy,
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
        child: Column(
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
                                          ? const Color.fromRGBO(0, 177, 21, 1)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.staffInfo['isSigned']
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
                            CustomTextWidget(
                              text: widget.staffInfo['name'],
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
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
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDateHeader)
                                Center(child: _buildDateChip(message.time)),
                              if (showDateHeader) const SizedBox(height: 10),

                              if(message.isSentByMe)
                                MessageBubble(
                                message: message,
                                onLongPress: (LongPressStartDetails details){
                                  _showMessageOptions(context, message, details);
                                },

                              )
                              else
                                ChatMessageWrapper(
                                  messageId: message.time.toIso8601String(),
                                  controller: _reactionsController,
                                  child: MessageBubble(
                                    message: message,
                                    onLongPress: (LongPressStartDetails details){
                                      _showMessageOptions(context, message, details);
                                    },
                                  ),
                                  config: ChatReactionsConfig(

                                    availableReactions: ['👍', '❤️', '😂', '😮', '➕'],

                                    // availableReactions: const [
                                    //   '👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '+'
                                    // ],

                                    showAddReactionButton: true,
                                    enableHapticFeedback: true,
                                    enableLongPress: true,
                                    enableDoubleTap: false,
                                    maxReactionsToShow: 5,
                                    reactionSize: 24.0,
                                    stackedValue: 4.0,

                                    emojiPickerBuilder: (context, onEmojiSelected) {
                                      print('emojiPickerBuilder was invoked!');
                                      return SizedBox(
                                        height: 380,
                                        child: EmojiPicker(
                                          onEmojiSelected: (category, emoji) {
                                            onEmojiSelected(emoji.emoji);
                                            print('Emoji selected: ${emoji.emoji}');
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


                                    menuItems:
                                    [
                                      MenuItem(
                                        label: 'Delete',
                                        icon: Icons.delete_outline,
                                        isDestructive: true,
                                      ),
                                      MenuItem(
                                        label: 'Copy',
                                        icon: Icons.copy,
                                        isDestructive: false,
                                      ),
                                    ],

                                    showContextMenu: true,
                                  ),

                                  onMenuItemTapped: (item) {
                                    final label = item.label.toLowerCase();

                                    if (label == 'delete') {
                                      setState(() {
                                        _messages.removeWhere((m) => m.time == message.time);
                                        CoreUtils.showTopSnackBar(
                                          context: context,
                                          message: 'Message deleted successfully',
                                          isSuccess: true,
                                        );
                                      });
                                    } else if (label == 'copy') {
                                      Clipboard.setData(ClipboardData(text: message.text));
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message: 'Message copied successfully',
                                        isSuccess: true,
                                      );
                                    }

                                  },


                                  onReactionAdded: (emoji) {
                                    // if (emoji == '+') {
                                    //   showModalBottomSheet(
                                    //     context: context,
                                    //     builder: (_) =>
                                    //         EmojiPicker(
                                    //           onEmojiSelected: (category, emoji) {
                                    //             Navigator.pop(context);
                                    //           },
                                    //           config: const Config(
                                    //             height: 380,
                                    //             checkPlatformCompatibility: true,
                                    //             emojiSet: null,
                                    //             locale: Locale('en'),
                                    //             emojiTextStyle: null,
                                    //             customBackspaceIcon: null,
                                    //             customSearchIcon: null,
                                    //             viewOrderConfig: ViewOrderConfig(),
                                    //             emojiViewConfig: EmojiViewConfig(),
                                    //             skinToneConfig: SkinToneConfig(enabled: true),
                                    //             categoryViewConfig: CategoryViewConfig(
                                    //               recentTabBehavior: RecentTabBehavior.RECENT,
                                    //             ),
                                    //             bottomActionBarConfig: BottomActionBarConfig(enabled: false),
                                    //             searchViewConfig: SearchViewConfig(),
                                    //           ),
                                    //         ),
                                    //     // EmojiPicker(
                                    //     //   onEmojiSelected: (_, e) {
                                    //     //     Navigator.pop(context);
                                    //     //     // apply reaction manually
                                    //     //     print('Picked ${e.emoji}');
                                    //     //   },
                                    //     //   config: const Config(height: 380),
                                    //     // ),
                                    //   );
                                    // }
                                    setState(() {

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Reacted with $emoji')),
                                      );
                                    });
                                  },

                                  onReactionRemoved: (emoji) {
                                    setState(() {
                                      // message.reactions.remove(emoji);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Removed $emoji')),
                                      );
                                    });
                                  },

                                  alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                                ),

                            ],
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
        child: Row(
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
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12,
                      ),
                      child: GradientAddButton(
                        onTap: () {},
                        wantedButtonSize: 26,
                        isRectangle: false,
                      ),
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
          constraints: const BoxConstraints(
            maxHeight: 320,
          ),
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
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 1,
                    ),
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
              borderRadius: BorderRadius.circular(
                16.0 ,
              ),
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
    final hasRead     = message.isRead;

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
              if (hasDelivery) _buildRecipientList(
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
          )
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
              border: Border.all(
                color: AppColors.primaryColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: recipients.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: CustomTextWidget(
                        text: r.name ,
                        fontSize: 13,
                      ),
                    ),
                    if (r.timestamp != null) ...[
                      const SizedBox(width: 10),
                      CustomTextWidget(
                        text: _formatTimeShort(r.timestamp!),
                        fontSize: 12,
                        fontColor: Colors.grey.shade600,
                      ),
                    ]
                  ],
                ),
              )).toList(),
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
    String dayPart = (dt.day == now.day && dt.month == now.month && dt.year == now.year)
        ? 'Today'
        : (dt.day == now.day - 1 ? 'Yesterday' : '${dt.day} ${_monthName(dt.month)} ${dt.year}');

    return '$dayPart, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  String _monthName(int month) => [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][month - 1];

}
