import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import '../repositories/conversation_entity_repository.dart';

class GetCachedConversationsEntityUseCase {
  final ConversationEntityRepository _repository;

  GetCachedConversationsEntityUseCase(this._repository);

  Future<Either<Failure, List<ConversationEntity>>> call({
    ConversationType? type,
  }) {
    return _repository.getCachedConversations(type: type);
  }
}
