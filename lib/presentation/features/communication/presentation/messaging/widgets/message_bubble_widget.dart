import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';

class Message {
  final String text;
  final bool isSentByMe;
  final DateTime time;

  final DateTime? deliveredAt;
  final DateTime? readAt;
  final Map<String, DateTime>? deliveredTo;
  final Map<String, DateTime>? readBy;

  Message({required this.text, required this.isSentByMe, required this.time, this.deliveredAt, this.readAt, this.deliveredTo, this.readBy});

  bool get isDelivered => deliveredAt != null || (deliveredTo != null && deliveredTo!.isNotEmpty);
  bool get isRead => readAt != null || (readBy != null && readBy!.isNotEmpty);
  int get readCount => readBy?.length ?? (readAt != null ? 1: 0);
}

class MessageBubble extends StatefulWidget {
  final Message message;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;

  const MessageBubble({required this.message, this.onDelete, this.onEdit, super.key});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {

  void _showPickerDialog() {
    final TextEditingController editingController = TextEditingController(text:  widget.message.text);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,

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
                if(newText.isNotEmpty){
                  if(widget.onEdit != null){
                    widget.onEdit!(newText);
                  }
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
        if (widget.message.isSentByMe) ...[
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
          Clipboard.setData(ClipboardData(text: widget.message.text));
          CoreUtils.showTopSnackBar(
              context: context,
              message: 'Message copied successfully',
              isSuccess: true
          );
          break;
        case 'info':

          break;
        case 'edit':
          _showPickerDialog();
          // if (widget.onEdit != null) {
          //   widget.onEdit!(widget.message.text);
          // }
          break;

        case 'delete':
          if (widget.onDelete != null) {
            widget.onDelete!();
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isSentByMe;

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
