import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_local_data_source.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_remote_data_source.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/reaction_repository.dart';

/// Single implementation of message reactions, used by every messaging
/// surface (Staff, Parent, Admin) via [MessageEntityRepository]'s delegation.
///
/// Mirrors the optimistic-update / offline-queue-on-failure pattern used
/// throughout [MessageEntityRepositoryImpl] for other message mutations.
class ReactionRepositoryImpl implements ReactionRepository {
  final MessageEntityRemoteDataSource _remote;
  final MessageEntityLocalDataSource _local;
  final StorageService _storage;

  ReactionRepositoryImpl({
    required MessageEntityRemoteDataSource remoteDataSource,
    required MessageEntityLocalDataSource localDataSource,
    required StorageService storageService,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        _storage = storageService;

  Future<String> get _orgCode async =>
      (await _storage.getString(StorageKeys.organizationCode)) ?? '';

  Future<String> get _schoolCode async =>
      (await _storage.getString(StorageKeys.schoolCode)) ?? '';

  Future<String> get _currentUserCode async =>
      (await _storage.getString(StorageKeys.userCode)) ?? '';

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
      await _queueOperation(
        operation: SyncOperationType.addReaction,
        entityCode: messageCode,
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
      await _queueOperation(
        operation: SyncOperationType.removeReaction,
        entityCode: messageCode,
        payload: {'messageCode': messageCode, 'emoji': emoji},
      );
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<void> _queueOperation({
    required SyncOperationType operation,
    required String entityCode,
    required Map<String, dynamic> payload,
  }) async {
    final org = await _orgCode;
    final school = await _schoolCode;
    final entity = SyncQueueEntity(
      id: 0, // Isar auto-increment
      operation: operation,
      entityCode: entityCode,
      status: SyncOperationStatus.pending,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
      organizationCode: org,
      schoolCode: school,
    );
    await _local.queueOperation(entity);
  }
}
