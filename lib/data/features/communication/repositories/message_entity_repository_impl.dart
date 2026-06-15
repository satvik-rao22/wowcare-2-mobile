import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_local_data_source.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_remote_data_source.dart';
import 'package:wowcare/data/features/communication/realtime/message_realtime_data_source.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';

class MessageEntityRepositoryImpl implements MessageEntityRepository {
  final MessageEntityRemoteDataSource _remote;
  final MessageEntityLocalDataSource _local;
  final MessageRealtimeDataSource _realtime;
  final StorageService _storage;

  static const _uuid = Uuid();

  MessageEntityRepositoryImpl({
    required MessageEntityRemoteDataSource remoteDataSource,
    required MessageEntityLocalDataSource localDataSource,
    required MessageRealtimeDataSource realtimeDataSource,
    required StorageService storageService,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        _realtime = realtimeDataSource,
        _storage = storageService;

  // ─── Tenancy helpers ────────────────────────────────────────────────────────

  Future<String> get _orgCode async =>
      (await _storage.getString(StorageKeys.organizationCode)) ?? '';

  Future<String> get _schoolCode async =>
      (await _storage.getString(StorageKeys.schoolCode)) ?? '';

  Future<String> get _currentUserCode async =>
      (await _storage.getString(StorageKeys.userCode)) ?? '';

  // ─── Queries ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String conversationCode,
    String? beforeMessageCode,
    int size = 50,
  }) async {
    try {
      final dtos = await _remote.getMessages(
        conversationCode: conversationCode,
        beforeMessageCode: beforeMessageCode,
        size: size,
      );
      final entities = dtos.map((d) => d.toEntity()).toList();

      // Merge into Isar — prepend older messages, replace newer ones
      await _local.saveMessages(
        entities: entities,
        conversationCode: conversationCode,
      );

      return Right(entities);
    } catch (e) {
      // Network failed — return Isar cache
      final org = await _orgCode;
      final school = await _schoolCode;
      final currentUser = await _currentUserCode;
      final cached = await _local.getMessages(
        conversationCode: conversationCode,
        organizationCode: org,
        schoolCode: school,
        limit: size,
        currentUserCode: currentUser,
      );
      if (cached.isNotEmpty) {
        return Right(cached.map((c) => c.toEntity()).toList());
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getCachedMessages(
    String conversationCode, {
    String? currentUserCode,
  }) async {
    try {
      final org = await _orgCode;
      final school = await _schoolCode;
      final user = currentUserCode ?? await _currentUserCode;
      final cached = await _local.getMessages(
        conversationCode: conversationCode,
        organizationCode: org,
        schoolCode: school,
        currentUserCode: user,
      );
      return Right(cached.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Send ────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationCode,
    required String text,
    List<String> attachmentCodes = const [],
    bool isPrivate = false,
    String? threadParentCode,
  }) async {
    final org = await _orgCode;
    final school = await _schoolCode;
    final currentUser = await _currentUserCode;
    final tempCode = _uuid.v4();

    // Optimistic local entity
    final optimistic = MessageEntity(
      id: tempCode,
      code: tempCode,
      conversationCode: conversationCode,
      senderCode: currentUser,
      senderName: '',
      senderRole: ParticipantRole.staff,
      text: text,
      messageType: MessageType.text,
      status: MessageStatus.pending,
      sentAt: DateTime.now(),
      organizationCode: org,
      schoolCode: school,
      isPrivate: isPrivate,
      localTempCode: tempCode,
    );

    // Persist optimistically so the UI shows immediately
    await _local.saveMessage(optimistic);

    try {
      final dto = await _remote.sendMessage(
        conversationCode: conversationCode,
        text: text,
        attachmentCodes: attachmentCodes,
        isPrivate: isPrivate,
        threadParentCode: threadParentCode,
      );
      final confirmed = dto.toEntity();

      // Replace temp entry with server-confirmed entry
      await _local.updateMessageStatus(
        localTempCode: tempCode,
        confirmedCode: confirmed.code,
        status: MessageStatus.sent.toApiString(),
      );

      return Right(confirmed);
    } catch (e) {
      // Mark as failed in cache
      await _local.updateMessageStatus(
        localTempCode: tempCode,
        confirmedCode: tempCode,
        status: MessageStatus.failed.toApiString(),
      );

      // Queue for retry
      await _queueOperation(
        operation: SyncOperationType.sendMessage,
        entityCode: tempCode,
        organizationCode: org,
        schoolCode: school,
        payload: {
          'conversationCode': conversationCode,
          'text': text,
          'attachmentCodes': attachmentCodes,
          'isPrivate': isPrivate,
          if (threadParentCode != null) 'threadParentCode': threadParentCode,
          'localTempCode': tempCode,
        },
      );

      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> retryFailedMessage(
    String localTempCode,
  ) async {
    final cached = await _local.getMessage(localTempCode);
    if (cached == null) {
      return Left(const CacheFailure('Message not found in cache'));
    }

    final entity = cached.toEntity();
    return sendMessage(
      conversationCode: entity.conversationCode,
      text: entity.text,
      isPrivate: entity.isPrivate,
      threadParentCode: entity.threadParentCode,
    );
  }

  // ─── Edit / Delete ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, MessageEntity>> editMessage({
    required String messageCode,
    required String newText,
  }) async {
    final cached = await _local.getMessage(messageCode);
    final originalEntity = cached?.toEntity();

    if (cached != null) {
      final updatedLocal = cached.toEntity().copyWith(
            text: newText,
            isEdited: true,
            editedAt: DateTime.now(),
          );
      await _local.saveMessage(updatedLocal);
    }

    try {
      final dto = await _remote.editMessage(
        messageCode: messageCode,
        newText: newText,
      );
      final updated = dto.toEntity();
      await _local.saveMessage(updated);
      return Right(updated);
    } catch (e) {
      if (originalEntity != null) {
        await _local.saveMessage(originalEntity);
      }
      // Queue for offline retry
      final org = await _orgCode;
      final school = await _schoolCode;
      await _queueOperation(
        operation: SyncOperationType.editMessage,
        entityCode: messageCode,
        organizationCode: org,
        schoolCode: school,
        payload: {'messageCode': messageCode, 'newText': newText},
      );
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageCode) async {
    final cached = await _local.getMessage(messageCode);
    final originalEntity = cached?.toEntity();

    if (cached != null) {
      await _local.deleteMessage(messageCode);
    }

    try {
      await _remote.deleteMessage(messageCode);
      return const Right(null);
    } catch (e) {
      if (originalEntity != null) {
        await _local.saveMessage(originalEntity);
      }
      final org = await _orgCode;
      final school = await _schoolCode;
      await _queueOperation(
        operation: SyncOperationType.deleteMessage,
        entityCode: messageCode,
        organizationCode: org,
        schoolCode: school,
        payload: {'messageCode': messageCode},
      );
      return Left(NetworkFailure(e.toString()));
    }
  }

  // ─── Reactions ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> addReaction({
    required String messageCode,
    required String emoji,
  }) async {
    final cached = await _local.getMessage(messageCode);
    final originalEntity = cached?.toEntity();
    final currentUser = await _currentUserCode;

    if (cached != null) {
      final entity = cached.toEntity();
      final updatedReactions = Map<String, String>.from(entity.reactions);
      updatedReactions[currentUser] = emoji;
      await _local.saveMessage(entity.copyWith(reactions: updatedReactions));
    }

    try {
      await _remote.addReaction(messageCode: messageCode, emoji: emoji);
      return const Right(null);
    } catch (e) {
      if (originalEntity != null) {
        await _local.saveMessage(originalEntity);
      }
      final org = await _orgCode;
      final school = await _schoolCode;
      await _queueOperation(
        operation: SyncOperationType.addReaction,
        entityCode: messageCode,
        organizationCode: org,
        schoolCode: school,
        payload: {'messageCode': messageCode, 'emoji': emoji},
      );
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction({
    required String messageCode,
    required String emoji,
  }) async {
    final cached = await _local.getMessage(messageCode);
    final originalEntity = cached?.toEntity();
    final currentUser = await _currentUserCode;

    if (cached != null) {
      final entity = cached.toEntity();
      final updatedReactions = Map<String, String>.from(entity.reactions);
      updatedReactions.remove(currentUser);
      await _local.saveMessage(entity.copyWith(reactions: updatedReactions));
    }

    try {
      await _remote.removeReaction(messageCode: messageCode, emoji: emoji);
      return const Right(null);
    } catch (e) {
      if (originalEntity != null) {
        await _local.saveMessage(originalEntity);
      }
      final org = await _orgCode;
      final school = await _schoolCode;
      await _queueOperation(
        operation: SyncOperationType.removeReaction,
        entityCode: messageCode,
        organizationCode: org,
        schoolCode: school,
        payload: {'messageCode': messageCode, 'emoji': emoji},
      );
      return Left(NetworkFailure(e.toString()));
    }
  }

  // ─── Read receipt ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> markMessageRead(String messageCode) async {
    try {
      await _remote.markMessageRead(messageCode);
      return const Right(null);
    } catch (_) {
      // Read receipts are fire-and-forget — silently ignore offline failures.
      return const Right(null);
    }
  }

  // ─── Search ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String conversationCode,
    required String query,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return const Right([]);

    try {
      final org = await _orgCode;
      final school = await _schoolCode;
      final all = await _local.getMessages(
        conversationCode: conversationCode,
        organizationCode: org,
        schoolCode: school,
        limit: 500,
      );

      final lowerQuery = query.toLowerCase();
      final results = all
          .where((m) => m.textPlain.toLowerCase().contains(lowerQuery))
          .take(limit)
          .map((m) => m.toEntity())
          .toList();

      return Right(results);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Sync queue ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<SyncQueueEntity>>> getPendingSyncOperations() async {
    try {
      final org = await _orgCode;
      final school = await _schoolCode;
      final ops = await _local.getPendingOperations(
        organizationCode: org,
        schoolCode: school,
      );
      return Right(ops.map((o) => o.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> cleanupSyncQueue({
    int olderThanDays = 7,
  }) async {
    try {
      final org = await _orgCode;
      final school = await _schoolCode;
      final count = await _local.cleanupSyncQueue(
        organizationCode: org,
        schoolCode: school,
        olderThanDays: olderThanDays,
      );
      return Right(count);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearMessagesCache(
    String conversationCode,
  ) async {
    try {
      final org = await _orgCode;
      final school = await _schoolCode;
      await _local.clearMessages(
        conversationCode: conversationCode,
        organizationCode: org,
        schoolCode: school,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _queueOperation({
    required SyncOperationType operation,
    required String entityCode,
    required String organizationCode,
    required String schoolCode,
    required Map<String, dynamic> payload,
  }) async {
    final entity = SyncQueueEntity(
      id: 0, // Isar auto-increment
      operation: operation,
      entityCode: entityCode,
      status: SyncOperationStatus.pending,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
    await _local.queueOperation(entity);
  }

  // ─── Realtime streams (Firestore) ────────────────────────────────────────────

  @override
  Stream<List<MessageEntity>> watchMessages({
    required String conversationCode,
    int limit = 100,
  }) async* {
    final org = await _orgCode;
    final school = await _schoolCode;

    yield* _realtime.watchMessages(
      organizationCode: org,
      schoolCode: school,
      conversationCode: conversationCode,
      limit: limit,
    );
  }
}
