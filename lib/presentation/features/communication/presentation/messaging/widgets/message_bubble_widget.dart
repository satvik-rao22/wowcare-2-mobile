import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';

class Message {
  final String id;
  final String text;
  final bool isSentByMe;
  final DateTime time;

  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<RecipientStatus> deliveredTo;
  final List<RecipientStatus> readBy;

  final Map<String, String> reactions;

  final String? quotedMessageId;

  Message({
    required this.text,
    required this.isSentByMe,
    required this.time,
    this.deliveredAt,
    this.readAt,
    this.deliveredTo = const [],
    this.readBy = const [],
    this.reactions = const {},
    this.quotedMessageId, required this.id,
  });

  bool get isDelivered => deliveredAt != null || deliveredTo.isNotEmpty;
  bool get isRead => readAt != null || (readBy.isNotEmpty);
  int get readCount => readBy.length + (readAt != null ? 1 : 0);
  int get deliveredCount => deliveredTo.length + (deliveredAt != null ? 1 : 0);

  int get reactionCount => reactions.length;
  Map<String, int> get emojiCounts{
    final counts = <String, int>{};
    for (var emoji in reactions.values){
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  bool hasReacted(String currentUserId) => reactions.containsKey(currentUserId);
  String? getMyReaction(String currentUserId) => reactions[currentUserId];
}

class RecipientStatus {
  final String name;
  final String? userId;
  final DateTime? timestamp;

  RecipientStatus({required this.name, this.userId, this.timestamp});

  bool get isDelivered => timestamp != null;
  bool get isRead => timestamp != null;
}

class MessageBubble extends StatefulWidget {
  final Message message;
  final Message? quotedMessage;
  //final GlobalKey? scrollKey;
  final void Function(LongPressStartDetails details)? onLongPress;
  final void Function(String quotedId)? onScrollToQuoted;
  //final void Function(String messageId, double height)? onHeightMeasured;
  //final void Function(String messageId, BuildContext context)? onContextReady;
  //final VoidCallback? onDelete;
  //final Function(String)? onEdit;

  const MessageBubble({required this.message, this.quotedMessage, this.onLongPress, this.onScrollToQuoted, super.key});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     widget.onContextReady?.call(
  //       widget.message.id,
  //       context,
  //     );
  //   });
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final box = context.findRenderObject() as RenderBox?;
  //     if (box != null && box.hasSize) {
  //       widget.onHeightMeasured?.call(
  //         widget.message.id,
  //         box.size.height,
  //       );
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isSentByMe;
    final reactions = widget.message.reactions;

    return GestureDetector(
      onLongPressStart: widget.message.isSentByMe ? widget.onLongPress : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  //key: widget.scrollKey,
                  // padding: const EdgeInsets.symmetric(
                  //   horizontal: 14,
                  //   vertical: 10,
                  // ),
                  padding: EdgeInsets.fromLTRB(14, 10, 14, isMe ? reactions.isNotEmpty? 24: 10 : 26),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.quotedMessageId != null)
                        GestureDetector(
                          onTap: () {
                            widget.onScrollToQuoted?.call(widget.message.quotedMessageId!);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextWidget(
                                  text: widget.quotedMessage!.text.length > 100
                                      ? '${widget.quotedMessage?.text.substring(0, 100)}...'
                                      : widget.quotedMessage?.text,
                                  fontSize: 13,
                                  fontColor: isMe ? Colors.white : AppColors.primaryColor,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  unlimitedLines: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      CustomTextWidget(
                        text: widget.message.text,
                        fontSize: 15.5,
                        fontColor: isMe ? Colors.white : AppColors.primaryColor,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        unlimitedLines: true,
                      ),
                    ],
                  ),
                ),

                if(reactions.isEmpty)
                  Positioned(
                    bottom: isMe ?-22 : 2, // slightly overlaps bottom edge
                    right: isMe ? 0 : 12,
                    left: isMe ? null : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTextWidget(
                            text: _formatTime(widget.message.time),
                            fontSize: 13,
                            fontColor: const Color(0x8041414E),
                            applyLetterSpacing: false,
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              widget.message.isRead
                                  ? Icons.done_all
                                  : widget.message.isDelivered
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 16,
                              color: widget.message.isRead ? Colors.blueAccent : Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )


                else if (reactions.isNotEmpty && !isMe)...[
                  Positioned(
                    bottom: isMe ?-22 : 2, // slightly overlaps bottom edge
                    right: isMe ? 0 : 12,
                    left: isMe ? null : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTextWidget(
                            text: _formatTime(widget.message.time),
                            fontSize: 13,
                            fontColor: const Color(0x8041414E),
                            applyLetterSpacing: false,
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              widget.message.isRead
                                  ? Icons.done_all
                                  : widget.message.isDelivered
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 16,
                              color: widget.message.isRead ? Colors.blueAccent : Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    right: isMe ? 12 : null,
                    left: isMe ? null : 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        alignment: WrapAlignment.end,
                        children: widget.message.emojiCounts.entries.map((entry) {
                          final emoji = entry.key;
                          final count = entry.value;
                          // return Stack(
                          //   clipBehavior: Clip.none,
                          //   children: [
                          //     Text(
                          //       emoji,
                          //       style: const TextStyle(fontSize: 16),
                          //     ),
                          //     if (count > 1)
                          //       Positioned(
                          //         right: -6,
                          //         bottom: -4,
                          //         child: Container(
                          //           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          //           decoration: BoxDecoration(
                          //             color: AppColors.primaryColor,
                          //             borderRadius: BorderRadius.circular(8),
                          //             border: Border.all(color: Colors.white, width: 1.5),
                          //           ),
                          //           child: Text(
                          //             '$count',
                          //             style: const TextStyle(
                          //               color: Colors.white,
                          //               fontSize: 10,
                          //               fontWeight: FontWeight.bold,
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                          //   ],
                          // );
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                            decoration: BoxDecoration(
                              //color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 16)),
                                if (count > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: CustomTextWidget(
                                      text: '$count',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      applyLetterSpacing: false,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ]

                else
                  Positioned(
                      bottom: isMe ?-22 : 2, // slightly overlaps bottom edge
                      right: isMe ? 0 : 12,
                      left: isMe ? null : null,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4,right: 4, top: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomTextWidget(
                                  text: _formatTime(widget.message.time),
                                  fontSize: 13,
                                  fontColor: const Color(0x8041414E),
                                  applyLetterSpacing: false,
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    widget.message.isRead
                                        ? Icons.done_all
                                        : widget.message.isDelivered
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 16,
                                    color: widget.message.isRead ? Colors.blueAccent : Colors.grey.shade600,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4,),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              alignment: WrapAlignment.end,
                              children: widget.message.emojiCounts.entries.map((entry) {
                                final emoji = entry.key;
                                final count = entry.value;
                                // return Stack(
                                //   clipBehavior: Clip.none,
                                //   children: [
                                //     Text(
                                //       emoji,
                                //       style: const TextStyle(fontSize: 16),
                                //     ),
                                //     if (count > 1)
                                //       Positioned(
                                //         right: -6,
                                //         bottom: -4,
                                //         child: Container(
                                //           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                //           decoration: BoxDecoration(
                                //             color: AppColors.primaryColor,
                                //             borderRadius: BorderRadius.circular(8),
                                //             border: Border.all(color: Colors.white, width: 1.5),
                                //           ),
                                //           child: Text(
                                //             '$count',
                                //             style: const TextStyle(
                                //               color: Colors.white,
                                //               fontSize: 10,
                                //               fontWeight: FontWeight.bold,
                                //             ),
                                //           ),
                                //         ),
                                //       ),
                                //   ],
                                // );
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                  decoration: BoxDecoration(
                                    //color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(emoji, style: const TextStyle(fontSize: 16)),
                                      if (count > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: CustomTextWidget(
                                            text: '$count',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            applyLetterSpacing: false,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        ],
                      )
                  )

              ],
            ),
            // child: Column(
            //   crossAxisAlignment: isMe
            //       ? CrossAxisAlignment.end
            //       : CrossAxisAlignment.start,
            //   children: [
            //     Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 14,
            //         vertical: 10,
            //       ),
            //       decoration: BoxDecoration(
            //         gradient: isMe
            //             ? const LinearGradient(
            //                 begin: Alignment.centerLeft,
            //                 end: Alignment.centerRight,
            //                 colors: [Color(0xFF5978F7), Color(0xFF9C84FF)],
            //               )
            //             : null,
            //         color: isMe ? null : Color(0xFFDCE6FF),
            //         borderRadius: BorderRadius.only(
            //           topLeft: const Radius.circular(18),
            //           topRight: const Radius.circular(18),
            //           bottomLeft: Radius.circular(isMe ? 18 : 4),
            //           bottomRight: Radius.circular(isMe ? 4 : 18),
            //         ),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.black.withOpacity(0.08),
            //             blurRadius: 4,
            //             offset: const Offset(0, 1),
            //           ),
            //         ],
            //       ),
            //       child: CustomTextWidget(
            //         text: widget.message.text,
            //         fontSize: 15.5,
            //         fontColor: isMe ? Colors.white : AppColors.primaryColor,softWrap: true,
            //         overflow: TextOverflow.visible,
            //         unlimitedLines: true,
            //
            //       ),
            //     ),
            //
            //     Padding(
            //       padding: const EdgeInsets.only(top: 3, right: 4, left: 4),
            //       child: Row(
            //         mainAxisAlignment: widget.message.isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            //         children: [
            //           CustomTextWidget(
            //             text: _formatTime(widget.message.time),
            //             fontSize: 13,
            //             fontColor: Color(0x8041414E),
            //             applyLetterSpacing: false,
            //           ),
            //           if(widget.message.isSentByMe)
            //             const SizedBox(width: 4,),
            //           if(widget.message.isSentByMe)
            //             Icon(
            //               widget.message.isRead ? Icons.done_all : widget.message.isDelivered ? Icons.done_all : Icons.done,
            //               size: 16,
            //               color: widget.message.isRead ? AppColors.themeColor : Colors.grey.shade600,
            //             )
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
