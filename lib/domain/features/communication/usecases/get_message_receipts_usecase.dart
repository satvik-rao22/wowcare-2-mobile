import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

/// Full per-recipient-per-persona receipts for one message, fetched
/// on-demand for the Message Info dialog. Legacy-stack counterpart of
/// [GetMessageEntityReceiptsUseCase].
class GetMessageReceiptsUseCase {
  final CommunicationRepository _repository;

  GetMessageReceiptsUseCase(this._repository);

  Future<
    Either<
      Failure,
      ({List<RecipientStatus> deliveredTo, List<RecipientStatus> readBy})
    >
  >
  call(String messageCode) {
    return _repository.getMessageReceipts(messageCode);
  }
}
