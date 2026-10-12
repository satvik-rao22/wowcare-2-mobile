import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class RemoveReactionUseCase {
  final MessageEntityRepository _repository;

  RemoveReactionUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String messageCode,
    required String emoji,
  }) {
    return AppEvents.track(
      AppEvent.communicationReactionRemove,
      () => _repository.removeReaction(messageCode: messageCode, emoji: emoji),
      failureOf: AppEvents.leftFailure,
    );
  }
}
