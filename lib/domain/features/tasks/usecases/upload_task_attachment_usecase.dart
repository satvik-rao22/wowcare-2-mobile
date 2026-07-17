import '../repositories/task_repository.dart';

/// Drives the full task-attachment upload round trip (Tasks API §8/§9) and
/// returns the ready asset code to pass to create/update.
class UploadTaskAttachmentUseCase {
  UploadTaskAttachmentUseCase(this._repository);

  final TaskRepository _repository;

  Future<String> call({
    required String filePath,
    required String fileName,
    required String contentType,
  }) {
    return _repository.uploadAttachment(
      filePath: filePath,
      fileName: fileName,
      contentType: contentType,
    );
  }
}
