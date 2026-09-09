import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class TogglePrivateModeUseCase {
  final ConversationEntityRepository _repository;

  TogglePrivateModeUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String conversationCode,
    required bool enable,
  }) {
    return _repository.togglePrivateMode(
      conversationCode: conversationCode,
      enable: enable,
    );
  }
}
