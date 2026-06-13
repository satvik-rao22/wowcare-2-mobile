import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import '../repositories/conversation_entity_repository.dart';

class CreateConversationEntityUseCase {
  final ConversationEntityRepository _repository;

  CreateConversationEntityUseCase(this._repository);

  Future<Either<Failure, ConversationEntity>> call({
    required ConversationType type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
  }) {
    return _repository.createConversation(
      type: type,
      studentCode: studentCode,
      classroomCode: classroomCode,
      participantCodes: participantCodes,
    );
  }
}
