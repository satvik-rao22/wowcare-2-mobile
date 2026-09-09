part of 'chat_input_bar.dart';

// Quote/edit/attachment preview strips + keyboard Intents (Mandate 6 split from chat_input_bar.dart). A `part` file:
// library-private, shares the parent's imports, pure move, no behaviour change.

class _QuotePreview extends StatelessWidget {
  const _QuotePreview({this.message, this.onCancel});

  final Message? message;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.sm, 0, AppSizes.sm, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.primaryColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (message!.senderName?.isNotEmpty ?? false)
                        ? message!.senderName!
                        : AppStrings.you,
                    style: AppTextStyles.size14.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CustomTextWidget(
                    text: MessageContentProcessor.previewText(message!.text),
                    fontSize: 13,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontColor: AppColors.messagingPreviewBody,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.messagingDismissIcon,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _EditPreview extends StatelessWidget {
  const _EditPreview({this.message, this.onCancel});

  final Message? message;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.sm, 0, AppSizes.sm, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.messagingEditAccent, width: 3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: AppColors.primaryColor),
                      const SizedBox(width: AppSizes.xxs),
                      Text(
                        AppStrings.editingMessage,
                        style: AppTextStyles.size14.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  CustomTextWidget(
                    text: MessageContentProcessor.previewText(message!.text),
                    fontSize: 13,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontColor: AppColors.messagingPreviewBody,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.messagingDismissIcon,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

// ── Attachment thumbnails ──────────────────────────────────────────────────────

class _AttachmentPreviewStrip extends StatelessWidget {
  const _AttachmentPreviewStrip({required this.attachments, this.onRemove});

  final List<ChatAttachment> attachments;
  final void Function(int)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      // Extra top padding gives the tiles breathing room from the field above and
      // leaves headroom for the remove badge (which sits at top:-4) so it isn't clipped.
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSizes.sm, AppSizes.sm, AppSizes.sm, 6),
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
        itemBuilder: (context, i) {
          final att = attachments[i];
          final isVideo =
              att.type == 'video' || att.mimeType.startsWith('video/');
          final canPreview =
              (att.isImage || isVideo) && (att.localPath?.isNotEmpty ?? false);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Tapping an image/video tile opens a full-screen in-app preview.
              GestureDetector(
                onTap: canPreview
                    ? () => context.push(
                        CommunicationRoutes.mediaViewer,
                        extra: MediaViewerArgs(
                          imageFile: att.isImage ? File(att.localPath!) : null,
                          videoFile: isVideo ? File(att.localPath!) : null,
                          title: att.name,
                        ),
                      )
                    : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      // A pending composer attachment normally carries a local
                      // file path; guard against a null path (e.g. a
                      // remote-only/not-yet-materialized entry) so the preview
                      // strip renders a neutral placeholder instead of throwing
                      // a null-check error at build.
                      child: att.localPath == null
                          ? Container(
                              width: 76,
                              height: 76,
                              color: AppColors.messagingDividerLight,
                              child: Icon(
                                att.isImage
                                    ? Icons.image_outlined
                                    : Icons.insert_drive_file_outlined,
                                color: AppColors.primaryColor,
                              ),
                            )
                          : att.isImage
                          ? Image.file(
                              File(att.localPath!),
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            )
                          : Thumbnail(
                              mimeType: att.mimeType,
                              dataResolver: () =>
                                  File(att.localPath!).readAsBytes(),
                              widgetSize: 76,
                              decoration: WidgetDecoration(
                                backgroundColor: AppColors.cardColor,
                                iconColor: AppColors.primaryColor,
                                textColor: AppColors.primaryColor,
                                wrapperBgColor: AppColors.transparentColor,
                                wrapperSize: 80,
                              ),
                            ),
                    ),
                    // Play affordance so a video tile reads as tappable/previewable.
                    if (isVideo)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.messagingScrimDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.messagingOnAccent,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              if (!att.isImage)
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.messagingScrimDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      att.name.length > 12
                          ? '${att.name.substring(0, 10)}…'
                          : att.name,
                      style: AppTextStyles.size14.copyWith(
                        color: AppColors.messagingOnAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => onRemove?.call(i),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.messagingRemoveBadge,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.messagingOnAccent, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppColors.messagingOnAccent,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Input row ──────────────────────────────────────────────────────────────────

class _CopyIntent extends Intent {
  const _CopyIntent();
}

class _CutIntent extends Intent {
  const _CutIntent();
}

class _PasteIntent extends Intent {
  const _PasteIntent();
}

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}
