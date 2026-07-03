import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class GetMessageReceiptsUseCase {
  const GetMessageReceiptsUseCase(this._repository);

  final MessageEntityRepository _repository;

  Future<Either<Failure, List<ReadReceiptEntity>>> call(
    String messageCode,
  ) {
    return _repository.getMessageReceipts(messageCode);
  }
}
