import '../entities/task_attachment.dart';
import '../repositories/task_repository.dart';

/// Drives the full task-attachment upload round trip (Tasks API §8/§9) for a
/// batch of files and returns their ready asset codes, in order, to pass to
/// create/update.
class UploadTaskAttachmentsUseCase {
  UploadTaskAttachmentsUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<String>> call({
    required List<PendingTaskAttachment> files,
    Map<String, String> alreadyUploaded = const {},
    void Function(String filePath, String assetCode)? onAssetUploaded,
    void Function(int index, int percent)? onProgress,
  }) {
    return _repository.uploadAttachments(
      files: files,
      alreadyUploaded: alreadyUploaded,
      onAssetUploaded: onAssetUploaded,
      onProgress: onProgress,
    );
  }
}
