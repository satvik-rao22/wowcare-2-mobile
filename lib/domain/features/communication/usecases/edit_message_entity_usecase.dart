import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class EditMessageEntityUseCase {
  final MessageEntityRepository _repository;

  EditMessageEntityUseCase(this._repository);

  Future<Either<Failure, MessageEntity>> call({
    required String messageCode,
    required String newText,
  }) {
    return AppEvents.track(
      AppEvent.communicationMessageEdit,
      () => _repository.editMessage(messageCode: messageCode, newText: newText),
      failureOf: AppEvents.leftFailure,
    );
  }
}
