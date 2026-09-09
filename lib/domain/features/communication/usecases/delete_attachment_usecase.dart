import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class DeleteAttachmentUseCase {
  final CommunicationRepository _repository;

  DeleteAttachmentUseCase(this._repository);

  Future<Either<Failure, void>> call(int attachmentId) {
    return _repository.deleteAttachment(attachmentId);
  }
}
