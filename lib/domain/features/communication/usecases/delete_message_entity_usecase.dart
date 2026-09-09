import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class DeleteMessageEntityUseCase {
  final MessageEntityRepository _repository;

  DeleteMessageEntityUseCase(this._repository);

  Future<Either<Failure, void>> call(String messageCode) {
    return _repository.deleteMessage(messageCode);
  }
}
