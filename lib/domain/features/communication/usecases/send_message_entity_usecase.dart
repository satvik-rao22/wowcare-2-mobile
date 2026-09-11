import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class SendMessageEntityUseCase {
  final MessageEntityRepository _repository;

  SendMessageEntityUseCase(this._repository);

  Future<Either<Failure, MessageEntity>> call({
    required String conversationCode,
    required String text,
    List<int> attachmentIds = const [],
    List<AttachmentEntity> attachments = const [],
    String? localTempCode,
    bool isPrivate = false,
    String? privateParentUserCode,
    String? threadParentCode,
  }) {
    return _repository.sendMessage(
      conversationCode: conversationCode,
      text: text,
      attachmentIds: attachmentIds,
      attachments: attachments,
      localTempCode: localTempCode,
      isPrivate: isPrivate,
      privateParentUserCode: privateParentUserCode,
      threadParentCode: threadParentCode,
    );
  }
}
