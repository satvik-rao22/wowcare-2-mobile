import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import '../repositories/message_entity_repository.dart';

class SyncPendingOperationsUseCase {
  final MessageEntityRepository _repository;

  SyncPendingOperationsUseCase(this._repository);

  Future<Either<Failure, List<SyncQueueEntity>>> call() {
    return _repository.getPendingSyncOperations();
  }
}
