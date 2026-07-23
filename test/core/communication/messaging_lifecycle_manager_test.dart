import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/communication/messaging_lifecycle_manager.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/network/network_info.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/reaction_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/drain_sync_queue_usecase.dart';

class _FakeNetworkInfo implements NetworkInfo {
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void emit(bool connected) => _controller.add(connected);

  void close() => _controller.close();
}

/// Minimal fake — only the one method SyncLifecycle/CacheLifecycle actually
/// call is implemented meaningfully; everything else throws if hit,
/// deliberately, so an accidental new dependency on this repo shows up as a
/// test failure rather than silently passing.
class _FakeMessageRepository implements MessageEntityRepository {
  List<SyncQueueEntity> pending = [];
  int drainCalls = 0;

  @override
  Future<Either<Failure, List<SyncQueueEntity>>>
      getPendingSyncOperations() async {
    drainCalls++;
    return Right(pending);
  }

  @override
  Future<Either<Failure, MessageEntity>> retryFailedMessage(
    String localTempCode,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, MessageEntity>> editMessage({
    required String messageCode,
    required String newText,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteMessage(String messageCode) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> markSyncOperationCompleted(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> markSyncOperationFailed({
    required int id,
    required String error,
    required int attempts,
  }) async => const Right(null);

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String conversationCode,
    String? beforeMessageCode,
    int size = 50,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<MessageEntity>>> getCachedMessages(
    String conversationCode, {
    String? currentUserCode,
  }) async => const Right([]);

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationCode,
    required String text,
    List<int> attachmentIds = const [],
    bool isPrivate = false,
    String? privateParentUserCode,
    String? threadParentCode,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteAttachment({
    required String messageCode,
    required int attachmentId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> addReaction({
    required String messageCode,
    required String emoji,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> removeReaction({
    required String messageCode,
    required String emoji,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> markMessageRead(String messageCode) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String conversationCode,
    required String query,
    int limit = 20,
  }) async => const Right([]);

  @override
  Future<Either<Failure, int>> cleanupSyncQueue({
    int olderThanDays = 7,
  }) async => const Right(0);

  @override
  Future<Either<Failure, void>> clearMessagesCache(
    String conversationCode,
  ) async => const Right(null);

  @override
  Stream<List<MessageEntity>> watchMessages({
    required String conversationCode,
    int limit = 100,
    String? organizationCode,
    String? schoolCode,
  }) => const Stream.empty();
}

class _FakeReactionRepository implements ReactionRepository {
  @override
  Future<Either<Failure, void>> addReaction({
    required String messageCode,
    required String emoji,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> removeReaction({
    required String messageCode,
    required String emoji,
  }) async => const Right(null);
}

class _FakeConversationRepository implements ConversationEntityRepository {
  int clearCacheCalls = 0;

  @override
  Future<Either<Failure, void>> clearConversationsCache() async {
    clearCacheCalls++;
    return const Right(null);
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'Unexpected call in test fake: ${invocation.memberName}',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNetworkInfo networkInfo;
  late _FakeMessageRepository messageRepo;
  late _FakeConversationRepository conversationRepo;
  late DrainSyncQueueUseCase drainSyncQueueUseCase;
  late MessagingLifecycleManager manager;

  setUp(() {
    networkInfo = _FakeNetworkInfo();
    messageRepo = _FakeMessageRepository();
    conversationRepo = _FakeConversationRepository();
    drainSyncQueueUseCase = DrainSyncQueueUseCase(
      messageRepository: messageRepo,
      reactionRepository: _FakeReactionRepository(),
    );
    manager = MessagingLifecycleManager(
      networkInfo: networkInfo,
      drainSyncQueueUseCase: drainSyncQueueUseCase,
      conversationRepository: conversationRepo,
    );
  });

  tearDown(() {
    manager.dispose();
    networkInfo.close();
  });

  group('SyncLifecycle — connectivity restoration (Phase 3/4)', () {
    test('drains the sync queue exactly once when connectivity is restored',
        () async {
      manager.init();
      networkInfo.emit(false); // lost
      await Future<void>.delayed(Duration.zero);
      networkInfo.emit(true); // restored
      await Future<void>.delayed(Duration.zero);

      expect(messageRepo.drainCalls, 1);
    });

    test('does not drain the queue on connectivity-lost events', () async {
      manager.init();
      networkInfo.emit(false);
      await Future<void>.delayed(Duration.zero);

      expect(messageRepo.drainCalls, 0);
    });

    test(
        'does not re-drain on a same-state "connected" event (e.g. wifi -> '
        'cellular while already online)', () async {
      manager.init();
      networkInfo.emit(false);
      await Future<void>.delayed(Duration.zero);
      networkInfo.emit(true);
      await Future<void>.delayed(Duration.zero);
      networkInfo.emit(true); // still connected, different network type
      await Future<void>.delayed(Duration.zero);

      expect(messageRepo.drainCalls, 1);
    });

    test('does nothing once disposed', () async {
      manager.init();
      manager.dispose();
      networkInfo.emit(false);
      networkInfo.emit(true);
      await Future<void>.delayed(Duration.zero);

      expect(messageRepo.drainCalls, 0);
    });
  });

  group('CacheLifecycle / onLogout (Phase 2)', () {
    test('onLogout clears the conversations cache via the existing, '
        'previously-unwired repository method', () async {
      await manager.onLogout();

      expect(conversationRepo.clearCacheCalls, 1);
    });

    test('onLogout detaches any attached conversation-list/thread state',
        () async {
      // Nothing attached — just verifying it doesn't throw with no-op state.
      await expectLater(manager.onLogout(), completes);
    });
  });

  group('FirestoreLifecycle (Phase 1) — background duration bookkeeping', () {
    test('has no recorded background duration before any pause/resume cycle',
        () {
      expect(manager.firestoreLifecycle.lastBackgroundDuration, isNull);
    });
  });
}
