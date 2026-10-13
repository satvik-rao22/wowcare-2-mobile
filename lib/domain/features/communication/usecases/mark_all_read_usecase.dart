import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class MarkAllReadUseCase {
  final ConversationEntityRepository _repository;

  MarkAllReadUseCase(this._repository);

  Future<Either<Failure, int>> call() => _repository.markAllRead();
}
