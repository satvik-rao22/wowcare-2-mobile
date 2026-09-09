import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class WatchMessagesUseCase {
  const WatchMessagesUseCase(this._repository);

  final MessageEntityRepository _repository;

  Stream<List<MessageEntity>> call({
    required String conversationCode,
    int limit = 100,
    String? organizationCode,
    String? schoolCode,
  }) {
    return _repository.watchMessages(
      conversationCode: conversationCode,
      limit: limit,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}
