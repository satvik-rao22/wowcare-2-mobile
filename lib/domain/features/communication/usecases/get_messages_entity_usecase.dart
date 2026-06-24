import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import '../repositories/message_entity_repository.dart';

class GetMessagesEntityUseCase {
  final MessageEntityRepository _repository;

  GetMessagesEntityUseCase(this._repository);

  Future<Either<Failure, List<MessageEntity>>> call({
    required String conversationCode,
    String? beforeMessageCode,
    int size = 50,
  }) {
    return _repository.getMessages(
      conversationCode: conversationCode,
      beforeMessageCode: beforeMessageCode,
      size: size,
    );
  }
}
