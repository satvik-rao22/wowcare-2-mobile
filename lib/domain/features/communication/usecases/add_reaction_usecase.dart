import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/communication_repository.dart';

class AddReactionUseCase {
  final CommunicationRepository _repository;

  AddReactionUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String threadId,
    String messageCode,
    String emoji,
  ) {
    return _repository.addReaction(threadId, messageCode, emoji);
  }
}
