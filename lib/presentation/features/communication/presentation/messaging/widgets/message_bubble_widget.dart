import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';
import 'full_attachment_viewer.dart';

import '../../../../../../domain/features/communication/entities/message.dart';

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
  final bool
  isParentMessaging; // if yes then the avatar and name of the sender will also be shown

  const MessageBubble({
    required this.message,
    this.quotedMessage,
    this.onLongPress,
    this.isParentMessaging = false,
    this.onScrollToQuoted,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  void _showReactionsDialog(BuildContext context, Message message) {
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
                text: 'Reactions',
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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: message.reactions.entries.map((entry) {
                  final name = entry.key;
                  final emoji = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextWidget(
                            text: name,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isSentByMe;
    final reactions = widget.message.reactions;
    final hasAttachments = widget.message.hasAttachments;

    return GestureDetector(
      onLongPressStart: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: widget.isParentMessaging
              ? Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        DocumentImageWidget(
                          fileUuid: widget.message.senderName ?? '',
                          name: widget.message.senderName ?? '',
                          size: 25,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: CustomTextWidget(
                            text: widget.message.senderName ?? '',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.70,
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
                            padding: EdgeInsets.fromLTRB(
                              14,
                              10,
                              14,
                              isMe
                                  ? reactions.isNotEmpty
                                        ? 24
                                        : 10
                                  : 26,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF5978F7),
                                        Color(0xFF9C84FF),
                                      ],
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
                                      widget.onScrollToQuoted?.call(
                                        widget.message.quotedMessageId!,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomTextWidget(
                                            text:
                                                widget
                                                        .quotedMessage!
                                                        .text
                                                        .length >
                                                    100
                                                ? '${widget.quotedMessage?.text.substring(0, 100)}...'
                                                : widget.quotedMessage?.text,
                                            fontSize: 13,
                                            fontColor: isMe
                                                ? Colors.white
                                                : AppColors.primaryColor,
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            unlimitedLines: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                if (hasAttachments) ...[
                                  const SizedBox(height: 8),
                                  _buildAttachmentsPreview(),
                                  const SizedBox(height: 10),
                                ],

                                CustomTextWidget(
                                  text: widget.message.text,
                                  fontSize: 15.5,
                                  fontColor: isMe
                                      ? Colors.white
                                      : AppColors.primaryColor,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  unlimitedLines: true,
                                ),
                              ],
                            ),
                          ),

                          if (reactions.isEmpty)
                            Positioned(
                              bottom: isMe ? -22 : 2,
                              right: isMe ? 0 : 12,
                              left: isMe ? null : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
                                        color: widget.message.isRead
                                            ? Colors.blueAccent
                                            : Colors.grey.shade600,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          else if (reactions.isNotEmpty && !isMe) ...[
                            Positioned(
                              bottom: isMe ? -22 : 2,
                              right: isMe ? 0 : 12,
                              left: isMe ? null : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
                                        color: widget.message.isRead
                                            ? Colors.blueAccent
                                            : Colors.grey.shade600,
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
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showReactionsDialog(
                                    context,
                                    widget.message,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
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
                                      children: widget.message.emojiCounts.entries.map((
                                        entry,
                                      ) {
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
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              emoji,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (count > 1)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                child: CustomTextWidget(
                                                  text: '$count',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  applyLetterSpacing: false,
                                                ),
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            Positioned(
                              bottom: isMe ? -22 : 2,
                              right: isMe ? 0 : 12,
                              left: isMe ? null : null,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      right: 4,
                                      top: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomTextWidget(
                                          text: _formatTime(
                                            widget.message.time,
                                          ),
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
                                            color: widget.message.isRead
                                                ? Colors.blueAccent
                                                : Colors.grey.shade600,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showReactionsDialog(
                                        context,
                                        widget.message,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 2,
                                          alignment: WrapAlignment.end,
                                          children: widget.message.emojiCounts.entries.map((
                                            entry,
                                          ) {
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                //color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    emoji,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (count > 1)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 4,
                                                          ),
                                                      child: CustomTextWidget(
                                                        text: '$count',
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        applyLetterSpacing:
                                                            false,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                  ],
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
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
                        padding: EdgeInsets.fromLTRB(
                          14,
                          10,
                          14,
                          isMe
                              ? reactions.isNotEmpty
                                    ? 24
                                    : 10
                              : 26,
                        ),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF5978F7),
                                    Color(0xFF9C84FF),
                                  ],
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
                                  widget.onScrollToQuoted?.call(
                                    widget.message.quotedMessageId!,
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextWidget(
                                        text:
                                            widget.quotedMessage!.text.length >
                                                100
                                            ? '${widget.quotedMessage?.text.substring(0, 100)}...'
                                            : widget.quotedMessage?.text,
                                        fontSize: 13,
                                        fontColor: isMe
                                            ? Colors.white
                                            : AppColors.primaryColor,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                        unlimitedLines: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            if (hasAttachments) ...[
                              const SizedBox(height: 8),
                              _buildAttachmentsPreview(),
                              const SizedBox(height: 10),
                            ],

                            CustomTextWidget(
                              text: widget.message.text,
                              fontSize: 15.5,
                              fontColor: isMe
                                  ? Colors.white
                                  : AppColors.primaryColor,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              unlimitedLines: true,
                            ),
                          ],
                        ),
                      ),

                      if (reactions.isEmpty)
                        Positioned(
                          bottom: isMe ? -22 : 2,
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
                                    color: widget.message.isRead
                                        ? Colors.blueAccent
                                        : Colors.grey.shade600,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else if (reactions.isNotEmpty && !isMe) ...[
                        Positioned(
                          bottom: isMe ? -22 : 2,
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
                                    color: widget.message.isRead
                                        ? Colors.blueAccent
                                        : Colors.grey.shade600,
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _showReactionsDialog(context, widget.message),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
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
                                  children: widget.message.emojiCounts.entries.map((
                                    entry,
                                  ) {
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        //color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (count > 1)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 4,
                                              ),
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
                            ),
                          ),
                        ),
                      ] else
                        Positioned(
                          bottom: isMe ? -22 : 2,
                          right: isMe ? 0 : 12,
                          left: isMe ? null : null,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                  top: 10,
                                ),
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
                                        color: widget.message.isRead
                                            ? Colors.blueAccent
                                            : Colors.grey.shade600,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showReactionsDialog(
                                    context,
                                    widget.message,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
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
                                      children: widget.message.emojiCounts.entries.map((
                                        entry,
                                      ) {
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            //color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                emoji,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (count > 1)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 4,
                                                      ),
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
                                ),
                              ),
                            ],
                          ),
                        ),
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

  // Widget _buildAttachmentsPreview() {
  //   final attachments = widget.message.attachments;
  //   if (attachments.isEmpty) return const SizedBox.shrink();
  //
  //   final images = attachments.where((a) => a.isImage).toList();
  //   final documents = attachments.where((a) => !a.isImage).toList();
  //
  //   final hasMoreImages = images.length > 4;
  //   final displayImages = hasMoreImages ? images.take(4).toList() : images;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       if (images.isNotEmpty)
  //         GridView.builder(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //             crossAxisCount: 2,
  //             crossAxisSpacing: 8,
  //             mainAxisSpacing: 8,
  //             childAspectRatio: 1.0,
  //           ),
  //           itemCount: displayImages.length,
  //           itemBuilder: (context, index) {
  //             final att = displayImages[index];
  //             final isLast = index == displayImages.length - 1;
  //             final remaining = images.length - 4;
  //
  //             return GestureDetector(
  //               onTap: () {
  //                 if (hasMoreImages && isLast) {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (_) => FullAttachmentViewer(attachments: attachments),
  //                     ),
  //                   );
  //                 } else {
  //
  //                 }
  //               },
  //               child: Stack(
  //                 fit: StackFit.expand,
  //                 children: [
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(12),
  //                     child: Thumbnail(
  //                       mimeType: att.mimeType ?? 'image/jpeg',
  //                       dataResolver: () async => await File(att.path).readAsBytes(),
  //                       widgetSize: 140,
  //                       decoration: WidgetDecoration(
  //                         backgroundColor: Colors.white,
  //                         iconColor: Colors.green,
  //                       ),
  //                       errorBuilder: (context, error) => Container(
  //                         color: Colors.grey[300],
  //                         child: const Icon(Icons.image, size: 50, color: Colors.grey),
  //                       ),
  //                     ),
  //                   ),
  //
  //                   if (hasMoreImages && isLast)
  //                     Container(
  //                       decoration: BoxDecoration(
  //                         color: Colors.black.withOpacity(0.45),
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                       child: Center(
  //                         child: CustomTextWidget(
  //                           text: '+$remaining',
  //                           fontSize: 28,
  //                           fontWeight: FontWeight.bold,
  //                           fontColor: Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             );
  //           },
  //         ),
  //
  //       if (documents.isNotEmpty) ...[
  //         const SizedBox(height: 12),
  //         ...documents.map((att) => Padding(
  //           padding: const EdgeInsets.only(bottom: 8),
  //           child: GestureDetector(
  //             onTap: () {
  //             },
  //             child: Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[100],
  //                 borderRadius: BorderRadius.circular(12),
  //                 border: Border.all(color: Colors.grey.shade300),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Container(
  //                     width: 60,
  //                     height: 80,
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey[200],
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                     child: const Icon(
  //                       Icons.picture_as_pdf,
  //                       size: 40,
  //                       color: Colors.redAccent,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         CustomTextWidget(
  //                           text: att.name,
  //                           fontSize: 15,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                         const SizedBox(height: 4),
  //                         CustomTextWidget(
  //                           text: '${(att.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB • PDF',
  //                           fontSize: 13,
  //                           fontColor: Colors.grey[700],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         )),
  //       ],
  //     ],
  //   );
  // }

  Widget _buildAttachmentsPreview() {
    final attachments = widget.message.attachments;
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where((a) => a.isImage).toList();
    final documents = attachments.where((a) => !a.isImage).toList();

    final imageCount = images.length;
    final hasMoreImages = imageCount > 4;
    final displayImages = hasMoreImages ? images.take(4).toList() : images;

    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.70;
    final singleImageWidth = maxBubbleWidth * 0.9;
    final multiImageWidth = maxBubbleWidth * 0.48;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (documents.isNotEmpty) ...[
          ...documents.map((att) {
            final source = att.displaySource;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                // onTap: () {
                // },
                onTap: () async {
                  final source = att.displaySource;
                  if (source == null) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'No file available to open',
                      isError: true,
                    );
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('No file available to open')),
                    // );
                    return;
                  }

                  if (att.localPath != null) {
                    final result = await OpenFile.open(att.localPath!);
                    if (result.type != ResultType.done) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Cannot open file: ${result.message}',
                        isError: true,
                      );
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text('Cannot open file: ${result.message}'),
                      //   ),
                      // );
                    }
                  } else
                    try {
                      // CoreUtils.showTopSnackBar(
                      //   context: context,
                      //   message: 'Downloading file',
                      //   isAdjust: true,
                      // );
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Downloading file...')),
                      // );

                      final response = await http.get(Uri.parse(att.remoteUrl));
                      if (response.statusCode == 200) {
                        final tempDir = await getTemporaryDirectory();
                        final tempFile = File('${tempDir.path}/${att.name}');
                        await tempFile.writeAsBytes(response.bodyBytes);

                        final result = await OpenFile.open(tempFile.path);
                        if (result.type != ResultType.done) {
                          CoreUtils.showTopSnackBar(
                            context: context,
                            message: 'Cannot open file: ${result.message}',
                            isError: true,
                          );
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(content: Text('Cannot open: ${result.message}')),
                          // );
                        }
                      } else {
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message: 'Failed to download the file',
                          isError: true,
                        );
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text('Failed to download file')),
                        // );
                      }
                    } catch (e) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Error: $e',
                        isError: true,
                      );
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(content: Text('Error: $e')),
                      // );
                    }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        // width: 60,
                        // height: 80,
                        width: multiImageWidth * 0.35,
                        height: multiImageWidth * 0.45,
                        child: source != null
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                child: Thumbnail(
                                  mimeType: att.mimeType ?? 'application/pdf',
                                  dataResolver: () async {
                                    try {
                                      final response = await http.get(
                                        Uri.parse(source),
                                      );
                                      if (response.statusCode == 200)
                                        return response.bodyBytes;
                                    } catch (_) {}
                                    return Uint8List(0);
                                  },
                                  //widgetSize: 80,
                                  widgetSize: multiImageWidth * 0.4,
                                  decoration: WidgetDecoration(
                                    backgroundColor: Colors.white,
                                    iconColor: Colors.redAccent,
                                  ),
                                  errorBuilder: (context, error) =>
                                      const Center(
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          size: 40,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  size: 40,
                                  color: Colors.redAccent,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextWidget(
                              text: att.name,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustomTextWidget(
                              text:
                                  '${(att.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB • ${att.type.toUpperCase()}',
                              fontSize: 13,
                              fontColor: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (images.isNotEmpty) const SizedBox(height: 16),
        ],

        if (images.isNotEmpty) ...[
          if (imageCount == 1) ...[
            GestureDetector(
              onTap: () {
                final att = displayImages.first;
                if (att.displaySource != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowFullScreenMediaView(
                        imageUrl: att.remoteUrl,
                        imageFile: att.localPath != null
                            ? File(att.localPath!)
                            : null,
                        title: att.name,
                      ),
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: displayImages.first.displaySource != null
                    ? Thumbnail(
                        mimeType: displayImages.first.mimeType ?? 'image/jpeg',
                        dataResolver: () async {
                          final source = displayImages.first.displaySource!;
                          try {
                            final response = await http.get(Uri.parse(source));
                            if (response.statusCode == 200)
                              return response.bodyBytes;
                          } catch (_) {}
                          return Uint8List(0);
                        },
                        //widgetSize: 300,
                        widgetSize: singleImageWidth,
                        decoration: WidgetDecoration(
                          backgroundColor: Colors.white,
                          iconColor: Colors.green,
                        ),
                        errorBuilder: (context, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        //height: 200,
                        height: singleImageWidth * 0.6,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
          ] else if (imageCount == 2 || imageCount == 4) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                final att = displayImages[index];
                final isLast = index == displayImages.length - 1;

                return GestureDetector(
                  onTap: () {
                    if (hasMoreImages && isLast) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullAttachmentViewer(attachments: attachments),
                        ),
                      );
                    } else if (att.displaySource != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowFullScreenMediaView(
                            imageUrl: att.remoteUrl,
                            imageFile: att.localPath != null
                                ? File(att.localPath!)
                                : null,
                            title: att.name,
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: att.displaySource != null
                            ? Thumbnail(
                                mimeType: att.mimeType ?? 'image/jpeg',
                                dataResolver: () async {
                                  final source = att.displaySource!;
                                  try {
                                    final response = await http.get(
                                      Uri.parse(source),
                                    );
                                    if (response.statusCode == 200)
                                      return response.bodyBytes;
                                  } catch (_) {}
                                  return Uint8List(0);
                                },
                                //widgetSize: 180,
                                widgetSize: multiImageWidth,
                                decoration: WidgetDecoration(
                                  backgroundColor: Colors.white,
                                  iconColor: Colors.green,
                                ),
                                errorBuilder: (context, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else if (imageCount == 3) ...[
            Column(
              children: [
                Row(
                  children: displayImages.take(2).map((att) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () {
                            if (att.displaySource != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShowFullScreenMediaView(
                                    imageUrl: att.remoteUrl,
                                    imageFile: att.localPath != null
                                        ? File(att.localPath!)
                                        : null,
                                    title: att.name,
                                  ),
                                ),
                              );
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: att.displaySource != null
                                ? Thumbnail(
                                    mimeType: att.mimeType ?? 'image/jpeg',
                                    dataResolver: () async {
                                      final source = att.displaySource!;
                                      try {
                                        final response = await http.get(
                                          Uri.parse(source),
                                        );
                                        if (response.statusCode == 200)
                                          return response.bodyBytes;
                                      } catch (_) {}
                                      return Uint8List(0);
                                    },
                                    //widgetSize: 180,
                                    widgetSize: multiImageWidth,
                                    decoration: WidgetDecoration(
                                      backgroundColor: Colors.white,
                                      iconColor: Colors.green,
                                    ),
                                    errorBuilder: (context, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Container(
                                    // height: 180,
                                    height: multiImageWidth,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () {
                    final att = displayImages[2];
                    if (att.displaySource != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowFullScreenMediaView(
                            imageUrl: att.remoteUrl,
                            imageFile: att.localPath != null
                                ? File(att.localPath!)
                                : null,
                            title: att.name,
                          ),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: displayImages[2].displaySource != null
                        ? Thumbnail(
                            mimeType: displayImages[2].mimeType ?? 'image/jpeg',
                            dataResolver: () async {
                              final source = displayImages[2].displaySource!;
                              try {
                                final response = await http.get(
                                  Uri.parse(source),
                                );
                                if (response.statusCode == 200)
                                  return response.bodyBytes;
                              } catch (_) {}
                              return Uint8List(0);
                            },
                            //widgetSize: 200,
                            widgetSize: singleImageWidth,
                            decoration: WidgetDecoration(
                              backgroundColor: Colors.white,
                              iconColor: Colors.green,
                            ),
                            errorBuilder: (context, error) => Container(
                              //height: 180,
                              height: singleImageWidth * 0.6,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            //height: 180,
                            height: singleImageWidth * 0.6,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                final att = displayImages[index];
                final isLast = index == displayImages.length - 1;
                final remaining = images.length - 4;

                return GestureDetector(
                  onTap: () {
                    if (hasMoreImages && isLast) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullAttachmentViewer(attachments: attachments),
                        ),
                      );
                    } else if (att.displaySource != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowFullScreenMediaView(
                            imageUrl: att.remoteUrl,
                            imageFile: att.localPath != null
                                ? File(att.localPath!)
                                : null,
                            title: att.name,
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: att.displaySource != null
                            ? Thumbnail(
                                mimeType: att.mimeType ?? 'image/jpeg',
                                dataResolver: () async {
                                  final source = att.displaySource!;
                                  try {
                                    final response = await http.get(
                                      Uri.parse(source),
                                    );
                                    if (response.statusCode == 200)
                                      return response.bodyBytes;
                                  } catch (_) {}
                                  return Uint8List(0);
                                },
                                //widgetSize: 180,
                                widgetSize: multiImageWidth,
                                decoration: WidgetDecoration(
                                  backgroundColor: Colors.white,
                                  iconColor: Colors.green,
                                ),
                                errorBuilder: (context, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      if (hasMoreImages && isLast)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CustomTextWidget(
                              text: '+$remaining',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
        if (images.isNotEmpty && documents.isNotEmpty)
          const SizedBox(height: 16),
      ],
    );
  }

  // Widget _buildAttachmentsPreview() {
  //   final attachments = widget.message.attachments;
  //   if (attachments.isEmpty) return const SizedBox.shrink();
  //
  //   final images = attachments.where((a) => a.isImage).toList();
  //   final documents = attachments.where((a) => !a.isImage).toList();
  //
  //   final hasMoreImages = images.length > 4;
  //   final displayImages = hasMoreImages ? images.take(4).toList() : images;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //
  //
  //       if (images.isNotEmpty)
  //         Wrap(
  //           spacing: 8,
  //           runSpacing: 8,
  //           alignment: WrapAlignment.start,
  //           children: List.generate(displayImages.length, (index) {
  //             final att = displayImages[index];
  //             final isLast = index == displayImages.length - 1;
  //             final remaining = images.length - 4;
  //
  //             return GestureDetector(
  //               onTap: () {
  //                 if (hasMoreImages && isLast) {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (_) => FullAttachmentViewer(attachments: attachments),
  //                     ),
  //                   );
  //                 } else if (att.displaySource != null) {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (_) => ShowFullScreenMediaView(
  //                         imageUrl: att.remoteUrl,
  //                         imageFile: att.localPath != null ? File(att.localPath!) : null,
  //                         title: att.name,
  //                       ),
  //                     ),
  //                   );
  //                 }
  //               },
  //               child: ConstrainedBox(
  //                 constraints: const BoxConstraints(
  //                   maxWidth: 180,
  //                   maxHeight: 240,
  //                 ),
  //                 child: Stack(
  //                   children: [
  //                     ClipRRect(
  //                       borderRadius: BorderRadius.circular(12),
  //                       child: att.displaySource != null
  //                           ? Thumbnail(
  //                         mimeType: att.mimeType ?? 'image/jpeg',
  //                         dataResolver: () async {
  //                           final source = att.displaySource!;
  //                           if (att.remoteUrl != null) {
  //                             try {
  //                               final response = await http.get(Uri.parse(source));
  //                               if (response.statusCode == 200) return response.bodyBytes;
  //                             } catch (_) {}
  //                             return Uint8List(0);
  //                           } else {
  //                             return await File(source).readAsBytes();
  //                           }
  //                         },
  //                         widgetSize: 180,
  //                         decoration: WidgetDecoration(
  //                           backgroundColor: Colors.white,
  //                           iconColor: Colors.green,
  //                         ),
  //                         errorBuilder: (context, error) => Container(
  //                           color: Colors.grey[300],
  //                           child: const Icon(Icons.image, size: 50, color: Colors.grey),
  //                         ),
  //                       )
  //                           : Container(
  //                         color: Colors.grey[300],
  //                         child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
  //                       ),
  //                     ),
  //
  //
  //                     if (hasMoreImages && isLast)
  //                       Positioned.fill(
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             color: Colors.black.withOpacity(0.55),
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                           child: Center(
  //                             child: CustomTextWidget(
  //                               text: '+$remaining',
  //                               fontSize: 32,
  //                               fontWeight: FontWeight.bold,
  //                               fontColor: Colors.white,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }),
  //         ),
  //
  //
  //
  //       if (documents.isNotEmpty) ...[
  //         const SizedBox(height: 16),
  //         ...documents.map((att) => Padding(
  //           padding: const EdgeInsets.only(bottom: 12),
  //           child: GestureDetector(
  //             onTap: () {},
  //             child: Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[100],
  //                 borderRadius: BorderRadius.circular(12),
  //                 border: Border.all(color: Colors.grey.shade300),
  //               ),
  //               child: Row(
  //                 children: [
  //                   SizedBox(
  //                     width: 60,
  //                     height: 80,
  //                     child: att.displaySource != null
  //                         ? Thumbnail(
  //                       mimeType: att.mimeType ?? 'application/pdf',
  //                       dataResolver: () async {
  //                         final source = att.displaySource!;
  //                         if (att.remoteUrl != null) {
  //                           try {
  //                             final response = await http.get(Uri.parse(source));
  //                             if (response.statusCode == 200) return response.bodyBytes;
  //                           } catch (_) {}
  //                           return Uint8List(0);
  //                         } else {
  //                           return await File(source).readAsBytes();
  //                         }
  //                       },
  //                       widgetSize: 80,
  //                       decoration: WidgetDecoration(
  //                         backgroundColor: Colors.white,
  //                         iconColor: Colors.redAccent,
  //                       ),
  //                       errorBuilder: (context, error) => const Center(
  //                         child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.redAccent),
  //                       ),
  //                     )
  //                         : const Center(
  //                       child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.redAccent),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         CustomTextWidget(
  //                           text: att.name,
  //                           fontSize: 15,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                         const SizedBox(height: 4),
  //                         CustomTextWidget(
  //                           text: '${(att.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB • ${att.type.toUpperCase()}',
  //                           fontSize: 13,
  //                           fontColor: Colors.grey[700],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         )),
  //       ],
  //     ],
  //   );
  // }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
