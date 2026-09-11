import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
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
    this.onAttachmentError,
  });

  final void Function(List<ChatAttachment>) onAttachmentsSelected;
  final void Function(String emoji) onEmojiSelected;
  final VoidCallback? onViewParticipants;

  /// Fired when one or more picked files were rejected (currently: over the
  /// size limit) instead of silently dropping them. Takes a message rather
  /// than the caller re-deriving one, since only this widget knows which
  /// files failed and why.
  ///
  /// Deliberately NOT shown from inside this widget: `_pick*` methods pop
  /// this bottom sheet (`Navigator.of(context).pop()`) before the async
  /// pick/validate work even starts, so by the time `_processFiles` knows a
  /// file was rejected, this widget's own context is already unmounted. The
  /// caller's chat-screen context is what's still alive to show a snackbar.
  final void Function(String message)? onAttachmentError;

  static Future<void> show(
    BuildContext context, {
    required void Function(List<ChatAttachment>) onAttachmentsSelected,
    required void Function(String emoji) onEmojiSelected,
    VoidCallback? onViewParticipants,
    void Function(String message)? onAttachmentError,
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
        onAttachmentError: onAttachmentError,
      ),
    );
  }

  @override
  State<MessageAttachmentBottomSheet> createState() =>
      _MessageAttachmentBottomSheetState();
}

class _MessageAttachmentBottomSheetState
    extends State<MessageAttachmentBottomSheet> {
  final _picker = ImagePicker();

  static const _emojis = ['😀', '😍', '👍', '❤️', '🎉', '👏', '😢', '😮'];

  // ── Attachment actions ────────────────────────────────────────────────────

  static const int _imageMaxSizeBytes = 10 * 1024 * 1024;
  static const int _videoMaxSizeBytes = 200 * 1024 * 1024;

  Future<void> _pickCamera() async {
    Navigator.of(context).pop();
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    await _processFiles([File(file.path)]);
  }

  /// Photos AND videos together, in one gallery browse — every format either
  /// type supports, not just images.
  Future<void> _pickGallery() async {
    Navigator.of(context).pop();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        ...FilePickerUtils.allowedImageExtensions,
        ...FilePickerUtils.allowedVideoExtensions,
      ],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .map((f) => f.path)
        .whereType<String>()
        .map((p) => File(p))
        .toList();
    if (files.isEmpty) return;
    await _processFiles(files);
  }

  Future<void> _pickDocument() async {
    Navigator.of(context).pop();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FilePickerUtils.allowedDocumentExtensions,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .map((f) => f.path)
        .whereType<String>()
        .map((p) => File(p))
        .toList();
    if (files.isEmpty) return;
    await _processFiles(files);
  }

  /// Classifies each file by its own extension (image / video / document)
  /// rather than a single blanket type for the whole batch — [_pickGallery]
  /// can hand back a mix of photos and videos in one call.
  ///
  /// [FileType.custom] + `allowedExtensions` on the OS picker (see
  /// [_pickGallery]/[_pickDocument]) is the FIRST line of defence — it stops
  /// most unsupported files from ever being selectable. It isn't airtight on
  /// every platform/file-provider combination (a known `file_picker`
  /// limitation, most often seen with third-party providers surfaced inside
  /// iOS's Files app, which don't always honour the UTType filter), so this
  /// re-validates every file's extension against the same three allow-lists
  /// before accepting it — anything matching none of them is rejected here
  /// rather than silently uploaded mislabelled as a "document".
  Future<void> _processFiles(List<File> files) async {
    final valid = <ChatAttachment>[];
    // name -> limit that was exceeded, for the rejection message below.
    final oversized = <String, int>{};
    final unsupported = <String>[];
    for (final file in files) {
      final ext = p.extension(file.path).toLowerCase().replaceFirst('.', '');
      final isImage = FilePickerUtils.allowedImageExtensions.contains(ext);
      final isVideo = FilePickerUtils.allowedVideoExtensions.contains(ext);
      final isDocument = FilePickerUtils.allowedDocumentExtensions.contains(
        ext,
      );
      if (!isImage && !isVideo && !isDocument) {
        unsupported.add(p.basename(file.path));
        continue;
      }
      final type = isImage ? 'image' : (isVideo ? 'video' : 'document');

      final size = await file.length();
      final maxSize = isVideo ? _videoMaxSizeBytes : _imageMaxSizeBytes;
      if (size > maxSize) {
        oversized[p.basename(file.path)] = maxSize;
        continue;
      }

      final mime = lookupMimeType(file.path) ??
          FilePickerUtils.getMimeType(ext);
      valid.add(
        ChatAttachment(
          localPath: file.path,
          name: p.basename(file.path),
          type: type,
          sizeBytes: size,
          mimeType: mime,
          remoteUrl: '',
        ),
      );
    }
    // Previously silent: rejected files just vanished and the sheet had
    // already closed, so the user got no feedback at all on why nothing was
    // attached — they'd only notice the message never had their file on it.
    final message = _rejectionMessage(
      oversized: oversized,
      unsupported: unsupported,
    );
    if (message != null) {
      widget.onAttachmentError?.call(message);
    }
    if (valid.isEmpty) return;
    widget.onAttachmentsSelected(valid);
  }

  /// Combines both rejection reasons into one message — e.g. "photo.png
  /// exceeds the 10 MB limit", "archive.zip is not a supported file type",
  /// or, for a mixed batch, "2 files couldn't be attached: 1 exceeds the
  /// size limit, 1 is an unsupported file type". Null when nothing was
  /// rejected.
  String? _rejectionMessage({
    required Map<String, int> oversized,
    required List<String> unsupported,
  }) {
    if (oversized.isEmpty && unsupported.isEmpty) return null;

    if (unsupported.isEmpty) {
      if (oversized.length == 1) {
        final entry = oversized.entries.first;
        return AppStrings.fileExceedsLimit(
          entry.key,
          _readableSize(entry.value),
        );
      }
      final distinctLimits = oversized.values.toSet();
      if (distinctLimits.length == 1) {
        return AppStrings.filesExceedLimit(
          oversized.length,
          _readableSize(distinctLimits.first),
        );
      }
      return AppStrings.filesExceedMixedLimits(
        oversized.length,
        _readableSize(_imageMaxSizeBytes),
        _readableSize(_videoMaxSizeBytes),
      );
    }

    if (oversized.isEmpty) {
      if (unsupported.length == 1) {
        return AppStrings.fileUnsupportedType(unsupported.first);
      }
      return AppStrings.filesUnsupportedType(unsupported.length);
    }

    return AppStrings.filesPartiallyRejected(
      oversized.length + unsupported.length,
      oversized.length,
      unsupported.length,
    );
  }

  String _readableSize(int bytes) =>
      AppStrings.megabytes((bytes / (1024 * 1024)).round());

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
