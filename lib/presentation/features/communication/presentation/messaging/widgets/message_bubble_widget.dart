import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';

class Message {
  final String text;
  final bool isSentByMe;
  final DateTime time;

  Message({required this.text, required this.isSentByMe, required this.time});
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;

  const MessageBubble({required this.message, this.onDelete, this.onEdit, super.key});

  void _showMessageOptions(BuildContext context, LongPressStartDetails details) {
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

          break;
        case 'edit':
          if (onEdit != null) {
            onEdit!(message.text);
          }
          break;

        case 'delete':
          if (onDelete != null) {
            onDelete!();
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;

    return GestureDetector(
      onLongPressStart: (details) => _showMessageOptions(context, details),
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
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
