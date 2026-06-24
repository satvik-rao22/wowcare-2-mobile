import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import '../repositories/message_entity_repository.dart';

class SearchMessagesUseCase {
  final MessageEntityRepository _repository;

  SearchMessagesUseCase(this._repository);

  Future<Either<Failure, List<MessageEntity>>> call({
    required String conversationCode,
    required String query,
    int limit = 20,
  }) {
    return _repository.searchMessages(
      conversationCode: conversationCode,
      query: query,
      limit: limit,
    );
  }
}
