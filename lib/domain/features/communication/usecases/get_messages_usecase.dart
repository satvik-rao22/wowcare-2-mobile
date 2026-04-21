import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../../../../domain/features/communication/entities/message.dart';
import '../../../../domain/features/communication/repositories/communication_repository.dart';

class GetMessagesUseCase {
  final CommunicationRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<Message>>> call(
    String threadId, {
    String? currentUserId,
  }) async {
    return await repository.getMessages(threadId, currentUserId: currentUserId);
  }
}
