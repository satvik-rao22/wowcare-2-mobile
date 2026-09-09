import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class DeleteMessageUseCase {
  final CommunicationRepository _repository;

  DeleteMessageUseCase(this._repository);

  Future<Either<Failure, void>> call(String messageCode) {
    return _repository.deleteMessage(messageCode);
  }
}
