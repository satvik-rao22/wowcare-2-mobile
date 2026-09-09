import 'package:flutter/material.dart';
import '../../../../../../domain/features/communication/entities/message.dart';
import '../../../../../../shared/common/widgets/custom_text_widget.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'attachment_widget.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'dart:io';

class MessagingInputArea extends StatelessWidget {
  final TextEditingController controller;
  final List<ChatAttachment> pendingAttachments;
  final Message? quotedMessage;
  final VoidCallback onSend;
  final VoidCallback onCancelQuote;
  final Function(List<ChatAttachment>) onAttachmentsSelected;
  final Function(int) onRemoveAttachment;

  const MessagingInputArea({
    super.key,
    required this.controller,
    required this.pendingAttachments,
    this.quotedMessage,
    required this.onSend,
    required this.onCancelQuote,
    required this.onAttachmentsSelected,
    required this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quotedMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
                        text: quotedMessage?.text,
                        fontSize: 14,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onCancelQuote,
                    ),
                  ],
                ),
              ),
            if (pendingAttachments.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 90),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pendingAttachments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final att = pendingAttachments[index];
                    return SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: att.isImage
                                ? Image.file(
                                    File(att.localPath!),
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  )
                                : Thumbnail(
                                    mimeType: att.mimeType,
                                    dataResolver: () async {
                                      return await File(
                                        att.localPath!,
                                      ).readAsBytes();
                                    },
                                    widgetSize: 80,
                                  ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => onRemoveAttachment(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Row(
              children: [
                AttachmentWidget(
                  iconWidget: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primaryColor,
                      size: 28,
                    ),
                  ),
                  onAttachmentsSelected: onAttachmentsSelected,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA0AEC0),
                        fontFamily: 'Manrope',
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.buildPrimaryGradient(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
