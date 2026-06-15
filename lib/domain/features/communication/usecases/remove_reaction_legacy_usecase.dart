import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/communication_repository.dart';

class RemoveReactionLegacyUseCase {
  final CommunicationRepository _repository;

  RemoveReactionLegacyUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String messageCode,
    required String emoji,
  }) {
    return _repository.removeReaction(messageCode, emoji);
  }
}
