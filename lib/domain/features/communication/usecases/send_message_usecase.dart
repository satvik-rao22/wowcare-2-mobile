import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class SendMessageUseCase {
  final CommunicationRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, Message>> call(String threadId, Message message) async {
    return await repository.sendMessage(threadId, message);
  }
}
