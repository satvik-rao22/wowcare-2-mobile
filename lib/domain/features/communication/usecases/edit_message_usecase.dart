import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class EditMessageUseCase {
  final CommunicationRepository repository;

  EditMessageUseCase(this.repository);

  Future<Either<Failure, Message>> call(String messageCode, String content) async {
    return await repository.editMessage(messageCode, content);
  }
}
