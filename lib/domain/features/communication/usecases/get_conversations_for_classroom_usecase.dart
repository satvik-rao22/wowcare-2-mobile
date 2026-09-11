import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class GetConversationsForClassroomUseCase {
  final ConversationEntityRepository _repository;

  GetConversationsForClassroomUseCase(this._repository);

  Future<Either<Failure, List<ConversationEntity>>> call(String classroomCode) {
    return _repository.getConversationsForClassroom(classroomCode);
  }
}
