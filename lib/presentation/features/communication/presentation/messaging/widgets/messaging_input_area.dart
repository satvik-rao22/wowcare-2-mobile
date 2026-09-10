import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'attachment_widget.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'dart:io';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

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
        padding: const EdgeInsets.fromLTRB(
          AppSizes.xs,
          AppSizes.xs,
          AppSizes.xs,
          AppSizes.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quotedMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: AppSurfaces.sub(radius: AppRadius.md),
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
                margin: const EdgeInsets.only(bottom: AppSizes.xs),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxs),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pendingAttachments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSizes.xs),
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
                                decoration: BoxDecoration(
                                  color: AppColors.blackColor.withValues(
                                    alpha: 0.54,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(AppSizes.xxs),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppColors.messagingOnAccent,
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
                    padding: EdgeInsets.all(AppSizes.xs),
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
                      filled: true,
                      fillColor: AppSurfaces.fieldFill,
                      hintText: AppStrings.typeAMessage,
                      hintStyle: AppTextStyles.size14.copyWith(
                        color: AppColors.messagingComposerHint,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.messagingInputBorder,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.messagingInputBorder,
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
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                GestureDetector(
                  onTap: onSend,
                  child: SkeuKeyBox(
                    variant: KeyVariant.primary,
                    padding: const EdgeInsets.all(AppSizes.sm),
                    child: const Icon(
                      Icons.send,
                      color: AppColors.messagingOnAccent,
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
