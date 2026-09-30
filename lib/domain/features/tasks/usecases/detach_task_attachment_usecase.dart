import '../repositories/task_repository.dart';

/// Removes one attachment from a task series by its attachment code.
class DetachTaskAttachmentUseCase {
  DetachTaskAttachmentUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call({
    required String taskCode,
    required String attachmentCode,
  }) {
    return _repository.detachAttachment(
      taskCode: taskCode,
      attachmentCode: attachmentCode,
    );
  }
}
