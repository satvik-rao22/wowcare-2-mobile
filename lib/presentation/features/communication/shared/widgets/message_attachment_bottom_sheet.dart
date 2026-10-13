import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

/// Modern attachment bottom sheet with quick emoji reactions, attachment
/// options, and a shortcut to open the participant info dialog.
///
/// Usage:
/// ```dart
/// MessageAttachmentBottomSheet.show(
///   context,
///   onAttachmentsSelected: (list) { ... },
///   onEmojiSelected: (emoji) { ... },
///   onViewParticipants: () { ... },
/// );
/// ```
class MessageAttachmentBottomSheet extends StatefulWidget {
  const MessageAttachmentBottomSheet({
    super.key,
    required this.onAttachmentsSelected,
    required this.onEmojiSelected,
    this.onViewParticipants,
  });

  final void Function(List<ChatAttachment>) onAttachmentsSelected;
  final void Function(String emoji) onEmojiSelected;
  final VoidCallback? onViewParticipants;

  static Future<void> show(
    BuildContext context, {
    required void Function(List<ChatAttachment>) onAttachmentsSelected,
    required void Function(String emoji) onEmojiSelected,
    VoidCallback? onViewParticipants,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparentColor,
      builder: (_) => MessageAttachmentBottomSheet(
        onAttachmentsSelected: onAttachmentsSelected,
        onEmojiSelected: onEmojiSelected,
        onViewParticipants: onViewParticipants,
      ),
    );
  }

  @override
  State<MessageAttachmentBottomSheet> createState() =>
      _MessageAttachmentBottomSheetState();
}

class _MessageAttachmentBottomSheetState
    extends State<MessageAttachmentBottomSheet> {
  static const _emojis = ['😀', '😍', '👍', '❤️', '🎉', '👏', '😢', '😮'];

  // ── Attachment actions ────────────────────────────────────────────────────

  // Photos and documents up to 10 MB, videos up to 200 MB. FilePickerUtils
  // drops anything else and tells the user why — this sheet has already
  // closed by then, so it couldn't show that itself.
  static const int _maxSizeMB = 10;
  static const int _maxVideoSizeMB = 200;

  Future<void> _pickCamera() async {
    Navigator.of(context).pop();
    _attach(
      await FilePickerUtils.pick(
        type: PickType.image,
        source: PickSource.camera,
        maxSizeMB: _maxSizeMB,
      ),
    );
  }

  /// Photos AND videos together, in one browse — every format either type
  /// supports, not just images.
  Future<void> _pickGallery() async {
    Navigator.of(context).pop();
    _attach(
      await FilePickerUtils.pick(
        type: PickType.imageOrVideo,
        multiple: true,
        maxSizeMB: _maxSizeMB,
        maxVideoSizeMB: _maxVideoSizeMB,
      ),
    );
  }

  Future<void> _pickDocument() =>
      _pickFromStorage(FilePickerUtils.allowedDocumentExtensions);

  /// The sheet has already popped by the time the picker returns, so every
  /// failure here (a picker exception, a provider that hands back no local
  /// path) must go through [MessageAttachmentBottomSheet.onAttachmentError]
  /// or the user sees nothing at all.
  Future<void> _pickFromStorage(List<String> allowedExtensions) async {
    Navigator.of(context).pop();
    _attach(
      await FilePickerUtils.pick(multiple: true, maxSizeMB: _maxSizeMB),
    );
  }

  /// Each file is typed by its own extension — a gallery pick can mix photos
  /// and videos.
  void _attach(List<PickedFile> files) {
    if (files.isEmpty) return;
    widget.onAttachmentsSelected([
      for (final file in files)
        ChatAttachment(
          localPath: file.path,
          name: file.name,
          type: file.isImage ? 'image' : (file.isVideo ? 'video' : 'document'),
          sizeBytes: file.size,
          mimeType: file.mimeType,
          remoteUrl: '',
        ),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSizes.sm, bottom: AppSizes.xxs),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.messagingSheetHandle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Quick reactions ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
              AppSizes.xxs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.quickReactions,
                style: AppTextStyles.sectionHeader.copyWith(
                  color: AppColors.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
              itemBuilder: (_, i) {
                final emoji = _emojis[i];
                return Tooltip(
                  message: AppStrings.quickReactions,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onEmojiSelected(emoji);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.messagingDialogBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.messagingInputBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: AppTextStyles.size16.copyWith(fontSize: 22),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSizes.sm),
          const Divider(height: 1, color: AppColors.messagingDividerLight),
          const SizedBox(height: AppSizes.xs),

          // ── Attachment grid ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.sm,
              crossAxisSpacing: AppSizes.sm,
              childAspectRatio: 1.15,
              children: [
                _AttachmentGridItem(
                  icon: Icons.camera_alt_rounded,
                  label: AppStrings.camera,
                  color: AppColors.messagingAttachmentCamera,
                  onTap: _pickCamera,
                ),
                _AttachmentGridItem(
                  icon: Icons.photo_library_rounded,
                  label: AppStrings.gallery,
                  color: AppColors.messagingAttachmentGallery,
                  onTap: _pickGallery,
                ),
                _AttachmentGridItem(
                  icon: Icons.insert_drive_file_rounded,
                  label: AppStrings.documentOption,
                  color: AppColors.messagingAttachmentDocument,
                  onTap: _pickDocument,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.xs),
          const Divider(height: 1, color: AppColors.messagingDividerLight),

          // ── View Participants ───────────────────────────────────────
          if (widget.onViewParticipants != null)
            Tooltip(
              message: AppStrings.viewParticipants,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onViewParticipants!();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.group_rounded,
                          color: AppColors.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          AppStrings.viewParticipants,
                          style: AppTextStyles.sectionHeader.copyWith(
                            fontSize: 15,
                            color: AppColors.messagingTextStrong,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSizes.xs),
        ],
      ),
    );
  }
}

// ── Attachment grid item ──────────────────────────────────────────────────────

class _AttachmentGridItem extends StatelessWidget {
  const _AttachmentGridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.size14.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
