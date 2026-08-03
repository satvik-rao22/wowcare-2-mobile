import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/communication/models/message_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/sync_queue_collection.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/core/util/app_time.dart';

abstract class MessageEntityLocalDataSource {
  /// Returns up to [limit] cached messages for [conversationCode], newest
  /// first. When [beforeMessageCode] is provided, only messages strictly
  /// older than that message are returned (cursor-based pagination) —
  /// matching the `beforeMessageCode` cursor used by the remote data source.
  Future<List<MessageEntityCollection>> getMessages({
    required String conversationCode,
    required String organizationCode,
    required String schoolCode,
    int limit,
    String? beforeMessageCode,
    String? currentUserCode,
  });

  Future<MessageEntityCollection?> getMessage(String messageCode);

  Future<void> saveMessages({
    required List<MessageEntity> entities,
    required String conversationCode,
  });

  Future<void> saveMessage(MessageEntity entity);

  Future<void> updateMessageStatus({
    required String localTempCode,
    required String confirmedCode,
    required String status,
  });

  Future<void> deleteMessage(String messageCode);

  Future<void> clearMessages({
    required String conversationCode,
    required String organizationCode,
    required String schoolCode,
  });

  // Sync queue
  Future<List<SyncQueueCollection>> getPendingOperations({
    required String organizationCode,
    required String schoolCode,
  });

  Future<void> queueOperation(SyncQueueEntity entity);

  Future<void> markOperationCompleted(int id);

  Future<void> markOperationFailed({
    required int id,
    required String error,
    required int attempts,
  });

  Future<int> cleanupSyncQueue({
    required String organizationCode,
    required String schoolCode,
    int olderThanDays,
  });
}

class MessageEntityLocalDataSourceImpl
    implements MessageEntityLocalDataSource {
  final CacheService cacheService;

  MessageEntityLocalDataSourceImpl({required this.cacheService});

  @override
  Future<List<MessageEntityCollection>> getMessages({
    required String conversationCode,
    required String organizationCode,
    required String schoolCode,
    int limit = 50,
    String? beforeMessageCode,
    String? currentUserCode,
  }) async {
    final all = await cacheService.getAll<MessageEntityCollection>();
    final matching = all
        .where(
          (m) =>
              m.conversationCode == conversationCode &&
              m.organizationCode == organizationCode &&
              m.schoolCode == schoolCode,
        )
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt)); // newest first

    if (beforeMessageCode == null) {
      // `List.take()` returns a lazy Iterable — it must be materialised with
      // `.toList()`, otherwise the caller receives the full unsliced list
      // and `limit` is silently ignored.
      return matching.take(limit).toList();
    }

    // Cursor-based pagination: only messages strictly older than the cursor.
    final cursorIndex = matching.indexWhere((m) => m.code == beforeMessageCode);
    if (cursorIndex == -1) {
      // Cursor message isn't in the local cache — nothing older to page
      // through locally (caller should rely on the remote fallback/result).
      return const [];
    }
    return matching.skip(cursorIndex + 1).take(limit).toList();
  }

  @override
  Future<MessageEntityCollection?> getMessage(String messageCode) async {
    final all = await cacheService.getAll<MessageEntityCollection>();
    try {
      return all.firstWhere(
        (m) => m.code == messageCode || m.localTempCode == messageCode,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveMessages({
    required List<MessageEntity> entities,
    required String conversationCode,
  }) async {
    final collections =
        entities.map(MessageEntityCollection.fromEntity).toList();
    await cacheService.putAll(collections);
  }

  @override
  Future<void> saveMessage(MessageEntity entity) async {
    await cacheService.put(MessageEntityCollection.fromEntity(entity));
  }

  @override
  Future<void> updateMessageStatus({
    required String localTempCode,
    required String confirmedCode,
    required String status,
  }) async {
    final all = await cacheService.getAll<MessageEntityCollection>();
    final match = all
        .where((m) => m.localTempCode == localTempCode)
        .toList();

    for (final m in match) {
      m.code = confirmedCode;
      m.status = status;
      m.localTempCode = null;
      await cacheService.put(m);
    }
  }

  @override
  Future<void> deleteMessage(String messageCode) async {
    final all = await cacheService.getAll<MessageEntityCollection>();
    final match = all
        .where((m) => m.code == messageCode || m.localTempCode == messageCode)
        .toList();
    for (final m in match) {
      await cacheService.delete<MessageEntityCollection>(m.isarId);
    }
  }

  @override
  Future<void> clearMessages({
    required String conversationCode,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final all = await cacheService.getAll<MessageEntityCollection>();
    final toDelete = all.where(
      (m) =>
          m.conversationCode == conversationCode &&
          m.organizationCode == organizationCode &&
          m.schoolCode == schoolCode,
    );
    for (final m in toDelete) {
      await cacheService.delete<MessageEntityCollection>(m.isarId);
    }
  }

  // ─── Sync Queue ─────────────────────────────────────────────────────────────

  @override
  Future<List<SyncQueueCollection>> getPendingOperations({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final all = await cacheService.getAll<SyncQueueCollection>();
    return all
        .where(
          (op) =>
              op.organizationCode == organizationCode &&
              op.schoolCode == schoolCode &&
              op.status == 'PENDING',
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first
  }

  @override
  Future<void> queueOperation(SyncQueueEntity entity) async {
    await cacheService.put(SyncQueueCollection.fromEntity(entity));
  }

  @override
  Future<void> markOperationCompleted(int id) async {
    final op = await cacheService.get<SyncQueueCollection>(id);
    if (op != null) {
      op.status = 'COMPLETED';
      await cacheService.put(op);
    }
  }

  @override
  Future<void> markOperationFailed({
    required int id,
    required String error,
    required int attempts,
  }) async {
    final op = await cacheService.get<SyncQueueCollection>(id);
    if (op != null) {
      op.status = 'FAILED';
      op.lastError = error;
      op.attempts = attempts;
      op.lastAttemptAt = AppTime.nowUtc();
      await cacheService.put(op);
    }
  }

  @override
  Future<int> cleanupSyncQueue({
    required String organizationCode,
    required String schoolCode,
    int olderThanDays = 7,
  }) async {
    final cutoff = AppTime.nowUtc().subtract(Duration(days: olderThanDays));
    final all = await cacheService.getAll<SyncQueueCollection>();
    final toDelete = all.where(
      (op) =>
          op.organizationCode == organizationCode &&
          op.schoolCode == schoolCode &&
          (op.status == 'COMPLETED' || op.status == 'FAILED') &&
          op.createdAt.isBefore(cutoff),
    );

    var count = 0;
    for (final op in toDelete) {
      await cacheService.delete<SyncQueueCollection>(op.isarId);
      count++;
    }
    return count;
  }
}
