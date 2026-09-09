import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class GetMessagesUseCase {
  final CommunicationRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<Message>>> call(
    String threadId, {
    String? currentUserId,
    int page = 0,
    int size = 100,
  }) async {
    return await repository.getMessages(
      threadId,
      currentUserId: currentUserId,
      page: page,
      size: size,
    );
  }
}
