import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';

class Message {
  final String text;
  final bool isSentByMe;
  final DateTime time;

  Message({required this.text, required this.isSentByMe, required this.time});
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF5978F7), Color(0xFF9C84FF)],
                        )
                      : null,
                  color: isMe ? null : Color(0xFFDCE6FF),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: CustomTextWidget(
                  text: message.text,
                  fontSize: 15.5,
                  fontColor: isMe ? Colors.white : AppColors.primaryColor,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 3, right: 4, left: 4),
                child: CustomTextWidget(
                  text: _formatTime(message.time),
                  fontSize: 13,
                  fontColor: Color(0x8041414E),
                  applyLetterSpacing: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
