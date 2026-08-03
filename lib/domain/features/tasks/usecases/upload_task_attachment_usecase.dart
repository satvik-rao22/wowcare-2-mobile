// SUPERSEDED — replaced by `upload_task_attachments_usecase.dart`, which drives
// the shared `AttachmentUploadManager` instead of a per-file loop inside the
// repository.
//
// This declared a class with the SAME name (`UploadTaskAttachmentsUseCase`) as
// the surviving file, so both being live made every import of it ambiguous —
// that was the root of the post-merge error cascade in di.dart, tasks_cubit and
// the task tests.
//
// What the replacement does better, for the same job:
//   * one batched presign for the whole set, not one presign per file;
//   * bounded-parallel transfers that stream from disk instead of buffering
//     each file in memory;
//   * per-file success/failure, so one bad file no longer fails the batch;
//   * treats a `complete` response of `UPLOADED` as final, which is what the
//     EVENT domain returns forever (waiting for `READY` hung event saves).
//
// The callback shape the task form consumes is preserved by
// `TasksCubit.uploadAttachments`, which adapts the manager's state stream back
// to `onProgress(index, percent)` / `onAssetUploaded(path, code)`.
//
// Original (full context in git at c4dcfa6d):
//
// import '../entities/task_attachment.dart';
// import '../repositories/task_repository.dart';
//
// /// Drives the full task-attachment upload round trip (Tasks API §8/§9) for a
// /// batch of files and returns their ready asset codes, in order, to pass to
// /// create/update.
// class UploadTaskAttachmentsUseCase {
//   UploadTaskAttachmentsUseCase(this._repository);
//
//   final TaskRepository _repository;
//
//   Future<List<String>> call({
//     required List<PendingTaskAttachment> files,
//     Map<String, String> alreadyUploaded = const {},
//     void Function(String filePath, String assetCode)? onAssetUploaded,
//     void Function(int index, int percent)? onProgress,
//   }) {
//     return _repository.uploadAttachments(
//       files: files,
//       alreadyUploaded: alreadyUploaded,
//       onAssetUploaded: onAssetUploaded,
//       onProgress: onProgress,
//     );
//   }
// }
