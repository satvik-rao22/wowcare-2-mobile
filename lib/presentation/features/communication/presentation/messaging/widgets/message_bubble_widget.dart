import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';

class Message {
  final String text;
  final bool isSentByMe;
  final DateTime time;

  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<RecipientStatus> deliveredTo;
  final List<RecipientStatus> readBy;

  Message({required this.text, required this.isSentByMe, required this.time, this.deliveredAt, this.readAt, this.deliveredTo = const [], this.readBy = const []});

  bool get isDelivered => deliveredAt != null ||  deliveredTo.isNotEmpty;
  bool get isRead => readAt != null || (readBy.isNotEmpty);
  int get readCount => readBy.length + (readAt != null ? 1: 0);
  int get deliveredCount => deliveredTo.length + (deliveredAt != null ? 1 : 0);
}

class RecipientStatus {
  final String name;
  final String? userId;
  final DateTime? timestamp;

  RecipientStatus({
    required this.name,
    this.userId,
    this.timestamp,
  });

  bool get isDelivered => timestamp != null;
  bool get isRead => timestamp != null;
}

class MessageBubble extends StatefulWidget {
  final Message message;
  final void Function(LongPressStartDetails details)? onLongPress;
  //final VoidCallback? onDelete;
  //final Function(String)? onEdit;

  const MessageBubble({required this.message, this.onLongPress , super.key,});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {





  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isSentByMe;

    return GestureDetector(
      onLongPressStart: widget.message.isSentByMe ? widget.onLongPress : null,
      child: Padding(
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
                    text: widget.message.text,
                    fontSize: 15.5,
                    fontColor: isMe ? Colors.white : AppColors.primaryColor,softWrap: true,
                    overflow: TextOverflow.visible,
                    unlimitedLines: true,

                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 4, left: 4),
                  child: Row(
                    mainAxisAlignment: widget.message.isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      CustomTextWidget(
                        text: _formatTime(widget.message.time),
                        fontSize: 13,
                        fontColor: Color(0x8041414E),
                        applyLetterSpacing: false,
                      ),
                      if(widget.message.isSentByMe)
                        const SizedBox(width: 4,),
                      if(widget.message.isSentByMe)
                        Icon(
                          widget.message.isRead ? Icons.done_all : widget.message.isDelivered ? Icons.done_all : Icons.done,
                          size: 16,
                          color: widget.message.isRead ? AppColors.themeColor : Colors.grey.shade600,
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
