import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/message_entity_repository.dart';

class DeleteAttachmentEntityUseCase {
  final MessageEntityRepository _repository;

  DeleteAttachmentEntityUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String messageCode,
    required int attachmentId,
  }) {
    return _repository.deleteAttachment(
      messageCode: messageCode,
      attachmentId: attachmentId,
    );
  }
}
