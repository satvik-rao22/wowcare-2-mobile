import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_attachment_thumbnail.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Form control for a task's attachments: the ones already on the server
/// ([existing]) plus any newly picked files ([pending]), each removable, with
/// per-file upload progress once a save is running.
///
/// Purely presentational — it never uploads. It reports picks through
/// [onPendingChanged] and the host form runs the §8/§9 upload from there.
class TaskAttachmentPicker extends StatelessWidget {
  const TaskAttachmentPicker({
    required this.existing,
    required this.pending,
    required this.uploadService,
    required this.onPendingChanged,
    required this.onExistingRemoved,
    this.uploadProgress = const <String, int>{},
    this.uploadedPaths = const <String>{},
    this.isUploading = false,
    this.enabled = true,
    super.key,
  });

  /// Attachments already saved on the task (edit mode).
  final List<TaskAttachment> existing;

  /// Locally picked files not yet uploaded.
  final List<PendingTaskAttachment> pending;

  final ImageUploadService uploadService;

  final ValueChanged<List<PendingTaskAttachment>> onPendingChanged;
  final ValueChanged<TaskAttachment> onExistingRemoved;

  /// file path → 0-100, populated while the host form uploads.
  final Map<String, int> uploadProgress;

  /// Paths already in storage. Distinct from a 100% [uploadProgress] entry: it
  /// stays true across a failed save so the row doesn't claim to be re-queued.
  final Set<String> uploadedPaths;

  final bool isUploading;

  /// False while a save is in flight, or when the user can't edit this task.
  final bool enabled;

  int get _total => existing.length + pending.length;

  bool get _canAddMore => _total < TaskAttachmentUtils.maxAttachmentCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (enabled && _canAddMore) _addTile(context),
        if (enabled && !_canAddMore)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              'Maximum ${TaskAttachmentUtils.maxAttachmentCount} attachments '
              'reached.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
            ),
          ),
        if (_total > 0) ...[
          const SizedBox(height: 10),
          for (final attachment in existing)
            _row(
              context: context,
              key: ValueKey('existing-${attachment.code}-${attachment.assetCode}'),
              thumbnail: TaskAttachmentThumbnail(
                attachment: attachment,
                uploadService: uploadService,
                size: 44,
              ),
              title: attachment.fileName.isEmpty
                  ? 'Attachment'
                  : attachment.fileName,
              subtitle: attachment.displaySize.isEmpty
                  ? 'Attached'
                  : attachment.displaySize,
              onOpen: () => TaskAttachmentUtils.open(
                context: context,
                attachment: attachment,
                service: uploadService,
              ),
              onRemove: enabled ? () => onExistingRemoved(attachment) : null,
            ),
          for (final attachment in pending)
            _row(
              context: context,
              key: ValueKey('pending-${attachment.filePath}'),
              thumbnail: PendingAttachmentThumbnail(
                attachment: attachment,
                size: 44,
              ),
              title: attachment.fileName,
              subtitle: _pendingSubtitle(attachment),
              progress: uploadProgress[attachment.filePath],
              onOpen: () => TaskAttachmentUtils.openLocal(
                context: context,
                attachment: attachment,
              ),
              onRemove: enabled && !isUploading
                  ? () => _removePending(attachment)
                  : null,
            ),
        ],
      ],
    );
  }

  String _pendingSubtitle(PendingTaskAttachment attachment) {
    if (uploadedPaths.contains(attachment.filePath)) {
      return '${attachment.displaySize} • uploaded';
    }
    final progress = uploadProgress[attachment.filePath];
    if (progress == null) return '${attachment.displaySize} • waiting to upload';
    if (progress >= 100) return '${attachment.displaySize} • uploaded';
    return '${attachment.displaySize} • uploading $progress%';
  }

  Widget _addTile(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : () => _pickFiles(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0x66573353)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.upload_file_outlined,
              size: 20,
              color: AppColors.themeColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _total == 0 ? 'Add attachments' : 'Add more attachments',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TaskAttachmentUtils.limitsLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required BuildContext context,
    required Key key,
    required Widget thumbnail,
    required String title,
    required String subtitle,
    required VoidCallback onOpen,
    VoidCallback? onRemove,
    int? progress,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0x33573353)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            GestureDetector(onTap: onOpen, child: thumbnail),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                  if (progress != null && progress < 100) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 3,
                        backgroundColor: const Color(0xFFE9EAF0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.themeColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  void _removePending(PendingTaskAttachment attachment) {
    onPendingChanged(
      pending.where((p) => p.filePath != attachment.filePath).toList(),
    );
  }

  /// Picks one or more files, validating extension, size and count. Each
  /// rejection is reported individually so a user who selects five files and
  /// hits the limit on one still gets the other four.
  Future<void> _pickFiles(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: TaskAttachmentUtils.allowedExtensions,
      allowMultiple: true,
    );
    if (!context.mounted) return;
    if (result == null || result.files.isEmpty) return;

    final existingPaths = pending.map((p) => p.filePath).toSet();
    final accepted = <PendingTaskAttachment>[];
    var remaining = TaskAttachmentUtils.maxAttachmentCount - _total;
    var skippedForSize = 0;
    var skippedForType = 0;
    var skippedForCount = 0;

    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.trim().isEmpty) continue;
      if (existingPaths.contains(path)) continue;

      final extension =
          (file.extension ?? '').toLowerCase().replaceAll('.', '');
      if (!TaskAttachmentUtils.allowedExtensions.contains(extension)) {
        skippedForType++;
        continue;
      }

      // `PlatformFile.size` can be 0 for some providers; fall back to the file.
      var size = file.size;
      if (size <= 0) {
        try {
          size = await File(path).length();
        } catch (_) {
          size = 0;
        }
      }
      if (size > TaskAttachmentUtils.maxAttachmentBytes) {
        skippedForSize++;
        continue;
      }
      if (remaining <= 0) {
        skippedForCount++;
        continue;
      }

      remaining--;
      accepted.add(
        PendingTaskAttachment(
          filePath: path,
          fileName: file.name,
          contentType: FilePickerUtils.getMimeType(extension),
          sizeBytes: size,
        ),
      );
    }

    if (accepted.isNotEmpty) {
      onPendingChanged([...pending, ...accepted]);
    }

    if (!context.mounted) return;
    final complaints = <String>[
      if (skippedForType > 0)
        '$skippedForType file${skippedForType == 1 ? '' : 's'} skipped '
            '(unsupported type)',
      if (skippedForSize > 0)
        '$skippedForSize file${skippedForSize == 1 ? '' : 's'} skipped '
            '(over 10MB)',
      if (skippedForCount > 0)
        '$skippedForCount file${skippedForCount == 1 ? '' : 's'} skipped '
            '(max ${TaskAttachmentUtils.maxAttachmentCount})',
    ];
    if (complaints.isNotEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: complaints.join(' · '),
        isWarning: true,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
