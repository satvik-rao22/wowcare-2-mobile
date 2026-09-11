import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class GetCachedConversationsUseCase {
  final CommunicationRepository _repository;

  GetCachedConversationsUseCase(this._repository);

  Future<Either<Failure, List<Conversation>>> call({String? type}) {
    return _repository.loadCachedConversations(type: type);
  }
}
