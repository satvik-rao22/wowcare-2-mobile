import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../entities/message.dart';
import '../repositories/communication_repository.dart';

class GetCachedMessagesUseCase {
  final CommunicationRepository _repository;

  GetCachedMessagesUseCase(this._repository);

  Future<Either<Failure, List<Message>>> call(
    String threadId, {
    String? currentUserId,
  }) {
    return _repository.loadCachedMessages(
      threadId,
      currentUserId: currentUserId,
    );
  }
}
