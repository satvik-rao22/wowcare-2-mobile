import '../entities/task_attachment.dart';
import '../repositories/task_repository.dart';

/// Current attachments on a task series. Yields an empty list rather than
/// throwing when the backend exposes no attachments endpoint.
class GetTaskAttachmentsUseCase {
  GetTaskAttachmentsUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<TaskAttachment>> call(String taskCode) =>
      _repository.getAttachments(taskCode);
}
