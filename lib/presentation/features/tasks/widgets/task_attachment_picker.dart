// SUPERSEDED — replaced by `AttachmentPickerField`
// (lib/shared/common/widgets/attachment_picker_field.dart), the same widget the
// event form uses. Tasks and events now share one picker UI, one picker service
// (FilePickerUtils) and one upload pipeline (AttachmentUploadManager); the only
// difference is which service the resulting asset codes are sent to.
//
// This widget also drove upload-on-pick, which the shared flow replaces with a
// single upload on submit — so nothing is uploaded for an abandoned form.
//
// Full source in git at c4dcfa6d.
//
// import 'package:flutter/material.dart';
// import 'package:wowcare/core/theme/app_colors.dart';
// import 'package:wowcare/core/utils/file_picker_utils.dart';
// import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
// import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';
// import 'package:wowcare/presentation/features/tasks/widgets/task_attachment_thumbnail.dart';
// import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
//
// /// Form control for a task's attachments: the ones already on the server
// /// ([existing]) plus any newly picked files ([pending]), each removable, with
// /// per-file upload progress once a save is running.
// ///
// /// Purely presentational — it never uploads. It reports picks through
// /// [onPendingChanged] and the host form runs the §8/§9 upload from there.
// class TaskAttachmentPicker extends StatelessWidget {
//   const TaskAttachmentPicker({
//     required this.existing,
//     required this.pending,
//     required this.uploadService,
//     required this.onPendingChanged,
//     required this.onExistingRemoved,
//     this.uploadProgress = const <String, int>{},
//     this.uploadedPaths = const <String>{},
//     this.isUploading = false,
//     this.enabled = true,
//     super.key,
//   });
//
//   /// Attachments already saved on the task (edit mode).
//   final List<TaskAttachment> existing;
//
//   /// Locally picked files not yet uploaded.
//   final List<PickedFile> pending;
//
//   final ImageUploadService uploadService;
//
//   final ValueChanged<List<PickedFile>> onPendingChanged;
//   final ValueChanged<TaskAttachment> onExistingRemoved;
//
//   /// file path → 0-100, populated while the host form uploads.
//   final Map<String, int> uploadProgress;
//
//   /// Paths already in storage. Distinct from a 100% [uploadProgress] entry: it
//   /// stays true across a failed save so the row doesn't claim to be re-queued.
//   final Set<String> uploadedPaths;
//
//   final bool isUploading;
//
//   /// False while a save is in flight, or when the user can't edit this task.
//   final bool enabled;
//
//   int get _total => existing.length + pending.length;
//
//   bool get _canAddMore => _total < TaskAttachmentUtils.maxAttachmentCount;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (enabled && _canAddMore) _addTile(context),
//         if (enabled && !_canAddMore)
//           Padding(
//             padding: const EdgeInsets.only(top: 2, bottom: 4),
//             child: Text(
//               'Maximum ${TaskAttachmentUtils.maxAttachmentCount} attachments '
//               'reached.',
//               style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
//             ),
//           ),
//         if (_total > 0) ...[
//           const SizedBox(height: 10),
//           for (final attachment in existing)
//             _row(
//               context: context,
//               key: ValueKey('existing-${attachment.code}-${attachment.assetCode}'),
//               thumbnail: TaskAttachmentThumbnail(
//                 attachment: attachment,
//                 uploadService: uploadService,
//                 size: 44,
//               ),
//               title: attachment.fileName.isEmpty
//                   ? 'Attachment'
//                   : attachment.fileName,
//               subtitle: attachment.displaySize.isEmpty
//                   ? 'Attached'
//                   : attachment.displaySize,
//               onOpen: () => TaskAttachmentUtils.open(
//                 context: context,
//                 attachment: attachment,
//                 service: uploadService,
//               ),
//               onRemove: enabled ? () => onExistingRemoved(attachment) : null,
//             ),
//           for (final attachment in pending)
//             _row(
//               context: context,
//               key: ValueKey('pending-${attachment.path}'),
//               thumbnail: PendingAttachmentThumbnail(
//                 attachment: attachment,
//                 size: 44,
//               ),
//               title: attachment.name,
//               subtitle: _pendingSubtitle(attachment),
//               progress: uploadProgress[attachment.path],
//               onOpen: () => TaskAttachmentUtils.openLocal(
//                 context: context,
//                 attachment: attachment,
//               ),
//               onRemove: enabled && !isUploading
//                   ? () => _removePending(attachment)
//                   : null,
//             ),
//         ],
//       ],
//     );
//   }
//
//   String _pendingSubtitle(PickedFile attachment) {
//     if (uploadedPaths.contains(attachment.path)) {
//       return '${attachment.readableSize} • uploaded';
//     }
//     final progress = uploadProgress[attachment.path];
//     if (progress == null) return '${attachment.readableSize} • waiting to upload';
//     if (progress >= 100) return '${attachment.readableSize} • uploaded';
//     return '${attachment.readableSize} • uploading $progress%';
//   }
//
//   Widget _addTile(BuildContext context) {
//     return InkWell(
//       onTap: isUploading ? null : () => _pickFiles(context),
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: const Color(0x66573353)),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             const Icon(
//               Icons.upload_file_outlined,
//               size: 20,
//               color: AppColors.themeColor,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _total == 0 ? 'Add attachments' : 'Add more attachments',
//                     style: const TextStyle(fontSize: 13, color: Colors.black87),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     TaskAttachmentUtils.limitsLabel,
//                     style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _row({
//     required BuildContext context,
//     required Key key,
//     required Widget thumbnail,
//     required String title,
//     required String subtitle,
//     required VoidCallback onOpen,
//     VoidCallback? onRemove,
//     int? progress,
//   }) {
//     return Padding(
//       key: key,
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: const Color(0x33573353)),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             GestureDetector(onTap: onOpen, child: thumbnail),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 13,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
//                   ),
//                   if (progress != null && progress < 100) ...[
//                     const SizedBox(height: 6),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(3),
//                       child: LinearProgressIndicator(
//                         value: progress / 100,
//                         minHeight: 3,
//                         backgroundColor: const Color(0xFFE9EAF0),
//                         valueColor: const AlwaysStoppedAnimation<Color>(
//                           AppColors.themeColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             if (onRemove != null)
//               IconButton(
//                 tooltip: 'Remove',
//                 visualDensity: VisualDensity.compact,
//                 onPressed: onRemove,
//                 icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _removePending(PickedFile attachment) {
//     onPendingChanged(
//       pending.where((p) => p.path != attachment.path).toList(),
//     );
//   }
//
//   /// Picks files through the shared picker service.
//   ///
//   /// Extension, size, count and duplicate-path checks — plus the "N files
//   /// skipped" message — all live in [FilePickerUtils.pickMultipleFiles], which
//   /// replaced ~80 lines of the same validation hand-rolled here.
//   Future<void> _pickFiles(BuildContext context) async {
//     final result = await FilePickerUtils.pickMultipleFiles(
//       allowedExtensions: TaskAttachmentUtils.allowedExtensions,
//       maxSizeBytes: TaskAttachmentUtils.maxAttachmentBytes,
//       // Saved attachments occupy slots too, so the cap is measured against the
//       // combined total rather than just what was picked in this session.
//       maxFiles: TaskAttachmentUtils.maxAttachmentCount - existing.length,
//       existing: pending,
//       context: context,
//     );
//     if (result.files.isEmpty) return;
//     onPendingChanged([...pending, ...result.files]);
//   }
// }
