import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class AddReactionUseCase {
  final CommunicationRepository _repository;

  AddReactionUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String threadId,
    String messageCode,
    String emoji,
  ) {
    return AppEvents.track(
      AppEvent.communicationReactionAdd,
      () => _repository.addReaction(threadId, messageCode, emoji),
      failureOf: AppEvents.leftFailure,
    );
  }
}
