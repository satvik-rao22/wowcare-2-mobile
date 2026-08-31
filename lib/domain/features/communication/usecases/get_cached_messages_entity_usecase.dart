import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import '../repositories/message_entity_repository.dart';

/// Reads messages straight from Isar (no network) — used to seed locally-only
/// drafts (never confirmed by the server: interrupted mid-send, or the app
/// was killed before the attachment upload finished) back into the thread on
/// open, so they survive navigating away/back or an app restart instead of
/// silently disappearing until a manual retry recreates them from scratch.
class GetCachedMessagesEntityUseCase {
  final MessageEntityRepository _repository;

  GetCachedMessagesEntityUseCase(this._repository);

  Future<Either<Failure, List<MessageEntity>>> call(
    String conversationCode, {
    String? currentUserCode,
  }) {
    return _repository.getCachedMessages(
      conversationCode,
      currentUserCode: currentUserCode,
    );
  }
}
