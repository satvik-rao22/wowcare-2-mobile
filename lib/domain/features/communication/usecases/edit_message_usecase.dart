import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class EditMessageUseCase {
  final CommunicationRepository repository;

  EditMessageUseCase(this.repository);

  Future<Either<Failure, Message>> call(String messageCode, String content) async {
    return await AppEvents.track(
      AppEvent.communicationMessageEdit,
      () => repository.editMessage(messageCode, content),
      failureOf: AppEvents.leftFailure,
    );
  }
}
