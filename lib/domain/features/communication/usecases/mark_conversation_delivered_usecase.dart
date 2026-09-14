import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class MarkConversationDeliveredUseCase {
  final CommunicationRepository _repository;

  MarkConversationDeliveredUseCase(this._repository);

  Future<Either<Failure, void>> call(String threadId) {
    return _repository.markAllAsDelivered(threadId);
  }
}
