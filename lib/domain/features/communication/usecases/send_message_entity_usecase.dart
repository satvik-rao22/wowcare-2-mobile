import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import '../repositories/message_entity_repository.dart';

class SendMessageEntityUseCase {
  final MessageEntityRepository _repository;

  SendMessageEntityUseCase(this._repository);

  Future<Either<Failure, MessageEntity>> call({
    required String conversationCode,
    required String text,
    List<String> attachmentCodes = const [],
    bool isPrivate = false,
    String? threadParentCode,
  }) {
    return _repository.sendMessage(
      conversationCode: conversationCode,
      text: text,
      attachmentCodes: attachmentCodes,
      isPrivate: isPrivate,
      threadParentCode: threadParentCode,
    );
  }
}
