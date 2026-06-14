import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import '../repositories/conversation_entity_repository.dart';

class GetConversationsEntityUseCase {
  final ConversationEntityRepository _repository;

  GetConversationsEntityUseCase(this._repository);

  Future<Either<Failure, List<ConversationEntity>>> call({
    ConversationType? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) {
    return _repository.getConversations(
      type: type,
      status: status,
      page: page,
      size: size,
    );
  }
}
