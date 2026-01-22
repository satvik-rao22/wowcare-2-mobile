import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

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
    ),
    Message(
      text: "Great to know that! Thanks!",
      isSentByMe: false,
      time: DateTime(2025, 1, 13, 16, 50),
    ),
    Message(
      text: "Also, is it possible to make it half day instead? I have doctor appointment in morning",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 9, 12),
    ),
    Message(
      text: "Sure, half day is fine. Just mark it in the attendance sheet when you come back",
      isSentByMe: true,
      time: DateTime(2025, 1, 14, 9, 18),
    ),
    Message(
      text: "Thank you so much! ❤️ Will do",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 9, 20),
    ),
    Message(
      text: "By the way, did you see the new leave policy update? They added 2 extra optional holidays this year",
      isSentByMe: true,
      time: DateTime(2025, 1, 14, 11, 5),
    ),
    Message(
      text: "No I didn't! Where can I find it? HR portal?",
      isSentByMe: false,
      time: DateTime(2025, 1, 14, 11, 8),
    ),
    Message(
      text: "Yes, under Policies → Leave & Attendance → 2025 updates. It's the pinned document",
      isSentByMe: true,
      time: DateTime(2026, 1, 21, 11, 11),
    ),
  ];

  void _sendMessage(){
    if(_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(text: _controller.text.trim(), isSentByMe: true, time: DateTime.now()));
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: !isLandscape,
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                text: 'Messaging',
                fontSize: 16,
              ),
              const SizedBox(height: 10,),
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
                            bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
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
                                        color:  widget.staffInfo['isSigned']
                                            ? const Color.fromRGBO(0, 177, 21, 1)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: widget.staffInfo['isSigned'] ? Colors.white : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),

                                    ),
                                  ),

                                ],
                              ),
                              const SizedBox(width: 10,),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          reverse: true,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[_messages.length - 1 - index];

                            bool showDateHeader = false;
                            final prevListIndex = _messages.length - 2 - index;

                            if (prevListIndex >= 0) {
                              final prevMessage = _messages[prevListIndex];

                              showDateHeader =
                                  message.time.year  != prevMessage.time.year ||
                                      message.time.month != prevMessage.time.month ||
                                      message.time.day   != prevMessage.time.day;
                            } else {
                              showDateHeader = true;
                            }
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if(showDateHeader)
                                  Center(
                                    child: _buildDateChip(message.time),
                                  ),
                                if(showDateHeader)
                                  const SizedBox(height: 10,),
                                MessageBubble(message: message),
                              ],
                            );
                          },
                        ),
                      ),

                    ],
                  ),

                ),
              ),
              const SizedBox(height: 10,),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: _buildMessageInput(),
                ),
              )
            ],
          ),
        )
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
                    end:   Alignment.centerRight,
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
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
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
            CustomClearAllChip(onTap: () { _sendMessage(); },label: 'Send', fontSize: 16, fontWeight: FontWeight.w600, borderRadius: 8,),

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
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      label = "Today, ${date.day} ${monthNames[date.month - 1]} ${date.year}";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      label = "Yesterday, ${date.day} ${monthNames[date.month - 1]} ${date.year}";
    } else {
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
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
}
