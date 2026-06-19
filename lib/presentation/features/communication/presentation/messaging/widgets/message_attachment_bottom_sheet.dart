import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
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
      backgroundColor: Colors.transparent,
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
  final _picker = ImagePicker();

  static const _emojis = ['😀', '😍', '👍', '❤️', '🎉', '👏', '😢', '😮'];

  // ── Attachment actions ────────────────────────────────────────────────────

  Future<void> _pickCamera() async {
    Navigator.of(context).pop();
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    await _processFiles([File(file.path)], isPhoto: true);
  }

  Future<void> _pickGallery() async {
    Navigator.of(context).pop();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FilePickerUtils.allowedImageExtensions,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .map((f) => f.path)
        .whereType<String>()
        .map(File.new)
        .toList();
    await _processFiles(files, isPhoto: true);
  }

  Future<void> _pickDocument() async {
    Navigator.of(context).pop();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FilePickerUtils.allowedDocumentExtensions,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await _processFiles([File(path)], isPhoto: false);
  }

  // ignore: unused_element
  Future<void> _pickVideo() async {
    Navigator.of(context).pop();
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _processFiles([File(file.path)], isPhoto: false);
  }

  // ignore: unused_element
  Future<void> _notImplemented(String feature) async {
    Navigator.of(context).pop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _processFiles(List<File> files, {required bool isPhoto}) async {
    final valid = <ChatAttachment>[];
    for (final file in files) {
      final size = await file.length();
      if (size > 10 * 1024 * 1024) continue;
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
      valid.add(
        ChatAttachment(
          localPath: file.path,
          name: p.basename(file.path),
          type: isPhoto ? 'image' : 'document',
          sizeBytes: size,
          mimeType: mime,
          remoteUrl: '',
        ),
      );
    }
    if (valid.isEmpty) return;
    widget.onAttachmentsSelected(valid);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDFE6E9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Quick reactions ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Reactions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final emoji = _emojis[i];
                return Tooltip(
                  message: 'Quick Reactions',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onEmojiSelected(emoji);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F3F5)),
          const SizedBox(height: 8),

          // ── Attachment grid ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _AttachmentGridItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: const Color(0xFF6366F1),
                  onTap: _pickCamera,
                ),
                _AttachmentGridItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF10B981),
                  onTap: _pickGallery,
                ),
                _AttachmentGridItem(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: const Color(0xFFF59E0B),
                  onTap: _pickDocument,
                ),
                // _AttachmentGridItem(
                //   icon: Icons.videocam_rounded,
                //   label: 'Video',
                //   color: const Color(0xFFEC4899),
                //   onTap: _pickVideo,
                // ),
                // _AttachmentGridItem(
                //   icon: Icons.audiotrack_rounded,
                //   label: 'Audio',
                //   color: const Color(0xFF8B5CF6),
                //   onTap: () => _notImplemented('Audio'),
                // ),
                // _AttachmentGridItem(
                //   icon: Icons.location_on_rounded,
                //   label: 'Location',
                //   color: const Color(0xFF14B8A6),
                //   onTap: () => _notImplemented('Location'),
                // ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F3F5)),

          // ── View Participants ───────────────────────────────────────
          if (widget.onViewParticipants != null)
            Tooltip(
              message: 'View Participants',
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onViewParticipants!();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
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
                      const Expanded(
                        child: Text(
                          'View Participants',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
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

          const SizedBox(height: 8),
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
              style: TextStyle(
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
