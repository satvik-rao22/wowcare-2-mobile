import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/communication/models/conversation_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/unread_entity_collection.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';

abstract class ConversationEntityLocalDataSource {
  Future<List<ConversationEntityCollection>> getConversations({
    required String organizationCode,
    required String schoolCode,
    ConversationType? type,
  });

  Future<ConversationEntityCollection?> getConversation(
    String conversationCode,
  );

  Future<List<ConversationEntityCollection>> getConversationsForStudent({
    required String studentCode,
    required String organizationCode,
    required String schoolCode,
  });

  Future<List<ConversationEntityCollection>> getConversationsForClassroom({
    required String classroomCode,
    required String organizationCode,
    required String schoolCode,
  });

  Future<void> saveConversations(List<ConversationEntity> entities);

  Future<void> saveConversation(ConversationEntity entity);

  Future<void> deleteConversation(String conversationCode);

  Future<void> clearConversations({
    required String organizationCode,
    required String schoolCode,
    ConversationType? type,
  });

  // Unread
  Future<List<UnreadEntityCollection>> getUnreadCounts({
    required String organizationCode,
    required String schoolCode,
  });

  Future<void> saveUnreadCounts(List<UnreadEntity> entities);

  Future<void> saveUnreadCount(UnreadEntity entity);
}

class ConversationEntityLocalDataSourceImpl
    implements ConversationEntityLocalDataSource {
  final CacheService cacheService;

  ConversationEntityLocalDataSourceImpl({required this.cacheService});

  // Cast the CacheService to access Isar directly.
  // IsarCacheService exposes the Isar instance through its generic methods.
  // We use putAll / getAll / clear which are available on CacheService.

  @override
  Future<List<ConversationEntityCollection>> getConversations({
    required String organizationCode,
    required String schoolCode,
    ConversationType? type,
  }) async {
    final all =
        await cacheService.getAll<ConversationEntityCollection>();

    return all.where((c) {
      if (c.organizationCode != organizationCode) return false;
      if (c.schoolCode != schoolCode) return false;
      if (type != null && c.type != type.toApiString()) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime); // newest first
      });
  }

  @override
  Future<ConversationEntityCollection?> getConversation(
    String conversationCode,
  ) async {
    final all =
        await cacheService.getAll<ConversationEntityCollection>();
    try {
      return all.firstWhere((c) => c.code == conversationCode);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ConversationEntityCollection>> getConversationsForStudent({
    required String studentCode,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final all =
        await cacheService.getAll<ConversationEntityCollection>();
    return all
        .where(
          (c) =>
              c.studentCode == studentCode &&
              c.organizationCode == organizationCode &&
              c.schoolCode == schoolCode,
        )
        .toList()
      ..sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
  }

  @override
  Future<List<ConversationEntityCollection>> getConversationsForClassroom({
    required String classroomCode,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final all =
        await cacheService.getAll<ConversationEntityCollection>();
    return all
        .where(
          (c) =>
              c.classroomCode == classroomCode &&
              c.organizationCode == organizationCode &&
              c.schoolCode == schoolCode,
        )
        .toList()
      ..sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
  }

  @override
  Future<void> saveConversations(List<ConversationEntity> entities) async {
    final collections =
        entities.map(ConversationEntityCollection.fromEntity).toList();
    await cacheService.putAll(collections);
  }

  @override
  Future<void> saveConversation(ConversationEntity entity) async {
    await cacheService.put(ConversationEntityCollection.fromEntity(entity));
  }

  @override
  Future<void> deleteConversation(String conversationCode) async {
    final all =
        await cacheService.getAll<ConversationEntityCollection>();
    final match = all.where((c) => c.code == conversationCode).toList();
    for (final c in match) {
      await cacheService.delete<ConversationEntityCollection>(c.isarId);
    }
  }

  @override
  Future<void> clearConversations({
    required String organizationCode,
    required String schoolCode,
    ConversationType? type,
  }) async {
    final all =
        await cacheService.getAll<ConversationEntityCollection>();
    final toDelete = all.where(
      (c) =>
          c.organizationCode == organizationCode &&
          c.schoolCode == schoolCode &&
          (type == null || c.type == type.toApiString()),
    );
    for (final c in toDelete) {
      await cacheService.delete<ConversationEntityCollection>(c.isarId);
    }
  }

  // ─── Unread ─────────────────────────────────────────────────────────────────

  @override
  Future<List<UnreadEntityCollection>> getUnreadCounts({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final all = await cacheService.getAll<UnreadEntityCollection>();
    return all
        .where(
          (u) =>
              u.organizationCode == organizationCode &&
              u.schoolCode == schoolCode,
        )
        .toList();
  }

  @override
  Future<void> saveUnreadCounts(List<UnreadEntity> entities) async {
    final collections =
        entities.map(UnreadEntityCollection.fromEntity).toList();
    await cacheService.putAll(collections);
  }

  @override
  Future<void> saveUnreadCount(UnreadEntity entity) async {
    await cacheService.put(UnreadEntityCollection.fromEntity(entity));
  }
}
