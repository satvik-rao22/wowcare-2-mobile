import '../repositories/message_entity_repository.dart';

/// Marks a previously-cached draft (by its local temp code) as failed —
/// used when the attachment upload/registration pipeline itself fails,
/// before [SendMessageEntityUseCase] is ever called (so there is no API
/// call to queue for retry, only the local attachment pipeline).
class MarkDraftMessageFailedUseCase {
  final MessageEntityRepository _repository;

  MarkDraftMessageFailedUseCase(this._repository);

  Future<void> call(String localTempCode) =>
      _repository.markDraftMessageFailed(localTempCode);
}
