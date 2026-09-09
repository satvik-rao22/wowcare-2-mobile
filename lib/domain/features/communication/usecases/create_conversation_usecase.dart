import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/data/features/communication/models/create_conversation_request.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

class CreateConversationUseCase {
  final CommunicationRepository _repository;

  CreateConversationUseCase(this._repository);

  Future<Either<Failure, Conversation>> call(
    CreateConversationRequest request,
  ) {
    return _repository.createConversation(request);
  }
}
