import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/message_entity_repository.dart';

/// Full per-recipient-per-persona receipts for one message, fetched
/// on-demand for the Message Info dialog. v2-stack counterpart of
/// [GetMessageReceiptsUseCase].
class GetMessageEntityReceiptsUseCase {
  final MessageEntityRepository _repository;

  GetMessageEntityReceiptsUseCase(this._repository);

  Future<Either<Failure, List<ReadReceiptEntity>>> call(String messageCode) {
    return _repository.getMessageReceipts(messageCode);
  }
}
