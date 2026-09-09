import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class GetConversationsForStudentUseCase {
  final ConversationEntityRepository _repository;

  GetConversationsForStudentUseCase(this._repository);

  Future<Either<Failure, List<ConversationEntity>>> call(String studentCode) {
    return _repository.getConversationsForStudent(studentCode);
  }
}
