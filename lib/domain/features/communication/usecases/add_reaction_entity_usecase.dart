import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class AddReactionEntityUseCase {
  final MessageEntityRepository _repository;

  AddReactionEntityUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String messageCode,
    required String emoji,
  }) {
    return AppEvents.track(
      AppEvent.communicationReactionAdd,
      () => _repository.addReaction(messageCode: messageCode, emoji: emoji),
      failureOf: AppEvents.leftFailure,
    );
  }
}
