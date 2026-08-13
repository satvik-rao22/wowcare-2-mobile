import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_local_data_source.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_remote_data_source.dart';
import 'package:wowcare/data/features/communication/realtime/message_realtime_data_source.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/reaction_repository.dart';

class MessageEntityRepositoryImpl implements MessageEntityRepository {
  final MessageEntityRemoteDataSource _remote;
  final MessageEntityLocalDataSource _local;
  final MessageRealtimeDataSource _realtime;
  final StorageService _storage;
  final ReactionRepository _reactionRepository;

  static const _uuid = Uuid();

  MessageEntityRepositoryImpl({
    required MessageEntityRemoteDataSource remoteDataSource,
    required MessageEntityLocalDataSource localDataSource,
    required MessageRealtimeDataSource realtimeDataSource,
    required StorageService storageService,
    required ReactionRepository reactionRepository,
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _realtime = realtimeDataSource,
       _storage = storageService,
       _reactionRepository = reactionRepository;

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

      // The backend's list endpoint omits truly-deleted messages, so a
      // plain replace would drop the "This message has been deleted."
      // placeholder every time the thread is reopened or refreshed —
      // mirrors CommunicationRepositoryImpl.getMessages' preservedDeleted
      // merge for the legacy stack. Only applies to the latest-window fetch
      // (no cursor); an older-history page must not re-inject rows outside
      // that window.
      if (beforeMessageCode != null) {
        return Right(entities);
      }
      final org = await _orgCode;
      final school = await _schoolCode;
      final currentUser = await _currentUserCode;
      final apiCodes = entities.map((e) => e.code).toSet();
      final cachedRows = await _local.getMessages(
        conversationCode: conversationCode,
        organizationCode: org,
        schoolCode: school,
        // High enough to return the full local cache for this conversation.
        limit: 100000,
        currentUserCode: currentUser,
      );
      final preservedDeleted = cachedRows
          .where((c) => c.isDeleted && !apiCodes.contains(c.code))
          .map((c) => c.toEntity())
          .toList();

      return Right([...entities, ...preservedDeleted]);
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
        beforeMessageCode: beforeMessageCode,
        currentUserCode: currentUser,
      );
      if (cached.isNotEmpty) {
        return Right(cached.map((c) => c.toEntity()).toList());
      }
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
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
    List<int> attachmentIds = const [],
    List<AttachmentEntity> attachments = const [],
    String? localTempCode,
    bool isPrivate = false,
    String? privateParentUserCode,
    String? threadParentCode,
  }) async {
    final org = await _orgCode;
    final school = await _schoolCode;
    final currentUser = await _currentUserCode;
    // Reuse the caller's own temp code (already cached via
    // [cacheDraftMessage]) when given, so this updates that SAME Isar row
    // instead of leaving it behind as an orphaned duplicate draft.
    final tempCode = localTempCode ?? _uuid.v4();

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
      sentAt: AppTime.nowUtc(),
      organizationCode: org,
      schoolCode: school,
      isPrivate: isPrivate,
      privateParentUserCode: privateParentUserCode,
      localTempCode: tempCode,
      attachments: attachments,
    );

    // Persist optimistically so the UI shows immediately (idempotent — a
    // no-op re-write when the caller already cached this exact row via
    // [cacheDraftMessage]).
    await _local.saveMessage(optimistic);

    try {
      final dto = await _remote.sendMessage(
        conversationCode: conversationCode,
        text: text,
        attachmentIds: attachmentIds,
        isPrivate: isPrivate,
        privateParentUserCode: privateParentUserCode,
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
          'attachmentIds': attachmentIds,
          'isPrivate': isPrivate,
          if (privateParentUserCode != null)
            'privateParentUserCode': privateParentUserCode,
          if (threadParentCode != null) 'threadParentCode': threadParentCode,
          'localTempCode': tempCode,
        },
      );

      return Left(NetworkFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<void> cacheDraftMessage(MessageEntity message) =>
      _local.saveMessage(message);

  @override
  Future<void> markDraftMessageFailed(String localTempCode) =>
      _local.updateMessageStatus(
        localTempCode: localTempCode,
        confirmedCode: localTempCode,
        status: MessageStatus.failed.toApiString(),
      );

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
      privateParentUserCode: entity.privateParentUserCode,
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
        editedAt: AppTime.nowUtc(),
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
      return Left(NetworkFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageCode) async {
    final cached = await _local.getMessage(messageCode);
    final originalEntity = cached?.toEntity();

    if (originalEntity != null) {
      // Soft-delete locally (matches the legacy stack's deletedAt
      // preservation — see getMessages()) instead of dropping the row: the
      // backend's list endpoint omits truly-deleted messages, so a hard
      // local delete meant the "This message has been deleted." placeholder
      // vanished from the thread entirely on the next reopen/refresh
      // instead of staying in place like Room Chat.
      await _local.saveMessage(
        originalEntity.copyWith(isDeleted: true, deletedAt: AppTime.nowUtc()),
      );
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
      return Left(NetworkFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  // ─── Attachments ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> deleteAttachment({
    required String messageCode,
    required int attachmentId,
  }) async {
    final cached = await _local.getMessage(messageCode);
    final originalEntity = cached?.toEntity();

    if (cached != null) {
      final updated = originalEntity!.copyWith(
        attachments: originalEntity.attachments
            .where((a) => a.attachmentId != attachmentId)
            .toList(),
      );
      await _local.saveMessage(updated);
    }

    try {
      await _remote.deleteAttachment(attachmentId);
      return const Right(null);
    } catch (e) {
      // No sync-queue entry — matches legacy CommunicationRepositoryImpl's
      // exact behaviour for this operation (rollback only, no retry queue).
      if (originalEntity != null) {
        await _local.saveMessage(originalEntity);
      }
      return Left(NetworkFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<ReadReceiptEntity>>> getMessageReceipts(
    String messageCode,
  ) async {
    try {
      final dtos = await _remote.getMessageReceipts(messageCode);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } catch (e) {
      return Left(NetworkFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  // ─── Reactions ───────────────────────────────────────────────────────────────
  // Delegated to the single, shared ReactionRepository implementation so
  // every messaging surface goes through the same optimistic-update +
  // offline-queue logic.

  @override
  Future<Either<Failure, void>> addReaction({
    required String messageCode,
    required String emoji,
  }) {
    return _reactionRepository.addReaction(
      messageCode: messageCode,
      emoji: emoji,
    );
  }

  @override
  Future<Either<Failure, void>> removeReaction({
    required String messageCode,
    required String emoji,
  }) {
    return _reactionRepository.removeReaction(
      messageCode: messageCode,
      emoji: emoji,
    );
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
          .where(
            (m) =>
                !m.isDeleted && m.textPlain.toLowerCase().contains(lowerQuery),
          )
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
  Future<Either<Failure, List<SyncQueueEntity>>>
  getPendingSyncOperations() async {
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
  Future<Either<Failure, int>> cleanupSyncQueue({int olderThanDays = 7}) async {
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
      createdAt: AppTime.nowUtc(),
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
    String? organizationCode,
    String? schoolCode,
  }) async* {
    final org = (organizationCode?.trim().isNotEmpty ?? false)
        ? organizationCode!.trim()
        : await _orgCode;
    final school = (schoolCode?.trim().isNotEmpty ?? false)
        ? schoolCode!.trim()
        : await _schoolCode;
    final user = await _currentUserCode;

    final roleJson = (await _storage.getString(StorageKeys.roles) ?? '')
        .toUpperCase();
    final activeRole =
        (await _storage.getString(StorageKeys.activeSchoolRole) ?? '')
            .toUpperCase();

    final isStaff =
        activeRole == 'STAFF' ||
        activeRole == 'TEACHER' ||
        (activeRole.isEmpty &&
            (roleJson.contains('STAFF') || roleJson.contains('TEACHER')));
    final isAdmin =
        activeRole.contains('ADMIN') ||
        activeRole.contains('DIRECTOR') ||
        (activeRole.isEmpty &&
            (roleJson.contains('ADMIN') || roleJson.contains('DIRECTOR')));

    yield* _realtime.watchMessages(
      organizationCode: org,
      schoolCode: school,
      currentUserCode: user,
      isStaff: isStaff,
      isAdmin: isAdmin,
      conversationCode: conversationCode,
      limit: limit,
    );
  }
}
