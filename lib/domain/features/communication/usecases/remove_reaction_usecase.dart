import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/message_entity_repository.dart';

class RemoveReactionUseCase {
  final MessageEntityRepository _repository;

  RemoveReactionUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String messageCode,
    required String emoji,
  }) {
    return _repository.removeReaction(
      messageCode: messageCode,
      emoji: emoji,
    );
  }
}
