import 'dart:convert';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/reaction_repository.dart';

/// Replays [SyncQueueEntity] rows queued by [MessageEntityRepositoryImpl] /
/// [ReactionRepositoryImpl] when a send/edit/delete/reaction call failed
/// offline.
///
/// Additive: the queue has always been written to on failure (see the
/// `_queueOperation` calls in those repositories) — this use case is what
/// was previously missing to actually drain it, whether triggered from a
/// WorkManager background task or from a foreground "back online" signal.
/// It does not change the existing manual-retry button, which continues to
/// call [MessageEntityRepository.retryFailedMessage] directly and is
/// entirely independent of this class.
class DrainSyncQueueUseCase {
  DrainSyncQueueUseCase({
    required MessageEntityRepository messageRepository,
    required ReactionRepository reactionRepository,
  }) : _messageRepository = messageRepository,
       _reactionRepository = reactionRepository;

  final MessageEntityRepository _messageRepository;
  final ReactionRepository _reactionRepository;

  /// Above this many attempts, a still-failing operation is marked FAILED
  /// (terminal) instead of left to accumulate indefinitely; matches the
  /// 4-retry ceiling already used by the Firestore reconnect backoff
  /// elsewhere in this module.
  static const int _maxAttempts = 4;

  /// Drains every PENDING operation for the current org/school, oldest
  /// first. Returns the count successfully replayed.
  Future<int> call() async {
    final pendingResult = await _messageRepository.getPendingSyncOperations();
    final pending = pendingResult.fold((_) => <SyncQueueEntity>[], (r) => r);
    if (pending.isEmpty) return 0;

    var succeeded = 0;
    for (final op in pending) {
      final ok = await _replay(op);
      if (ok) {
        succeeded++;
        await _messageRepository.markSyncOperationCompleted(op.id);
      } else if (op.attempts + 1 >= _maxAttempts) {
        await _messageRepository.markSyncOperationFailed(
          id: op.id,
          error: op.lastError ?? 'Retry attempts exhausted',
          attempts: op.attempts + 1,
        );
      }
      // else: leave PENDING — the next drain pass will retry it. The retry
      // call itself (e.g. retryFailedMessage) already re-queues a fresh
      // PENDING entry on failure, so nothing else needs to happen here.
    }
    return succeeded;
  }

  Future<bool> _replay(SyncQueueEntity op) async {
    try {
      final payload = jsonDecode(op.payload) as Map<String, dynamic>;
      switch (op.operation) {
        case SyncOperationType.sendMessage:
          final localTempCode =
              payload['localTempCode'] as String? ?? op.entityCode;
          final result = await _messageRepository.retryFailedMessage(
            localTempCode,
          );
          return result.isRight();
        case SyncOperationType.editMessage:
          final result = await _messageRepository.editMessage(
            messageCode: payload['messageCode'] as String? ?? op.entityCode,
            newText: payload['newText'] as String? ?? '',
          );
          return result.isRight();
        case SyncOperationType.deleteMessage:
          final result = await _messageRepository.deleteMessage(
            payload['messageCode'] as String? ?? op.entityCode,
          );
          return result.isRight();
        case SyncOperationType.addReaction:
          final result = await _reactionRepository.addReaction(
            messageCode: payload['messageCode'] as String? ?? op.entityCode,
            emoji: payload['emoji'] as String? ?? '',
          );
          return result.isRight();
        case SyncOperationType.removeReaction:
          final result = await _reactionRepository.removeReaction(
            messageCode: payload['messageCode'] as String? ?? op.entityCode,
            emoji: payload['emoji'] as String? ?? '',
          );
          return result.isRight();
        case SyncOperationType.markRead:
        case SyncOperationType.togglePrivateMode:
          // Not currently queued by any repository (no _queueOperation call
          // site uses these types) — nothing to replay yet; treat as a
          // no-op success so a stray/legacy row doesn't block the drain.
          return true;
      }
    } catch (_) {
      // Malformed payload (corrupt JSON, unexpected shape) — never crash the
      // drain loop over one bad row.
      return false;
    }
  }
}
