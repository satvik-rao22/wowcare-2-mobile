import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/reaction_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/drain_sync_queue_usecase.dart';

class _FakeMessageEntityRepository implements MessageEntityRepository {
  List<SyncQueueEntity> pending = [];
  bool retryShouldFail = false;
  bool editShouldFail = false;
  bool deleteShouldFail = false;
  final completedIds = <int>[];
  final failedIds = <int>[];

  @override
  Future<Either<Failure, List<SyncQueueEntity>>>
  getPendingSyncOperations() async => Right(pending);

  @override
  Future<Either<Failure, MessageEntity>> retryFailedMessage(
    String localTempCode,
  ) async {
    if (retryShouldFail) return Left(NetworkFailure('still offline'));
    return Right(
      MessageEntity(
        id: 'SERVER-1',
        code: 'SERVER-1',
        conversationCode: 'CONV-1',
        senderCode: 'USR-1',
        senderName: 'Sender',
        senderRole: ParticipantRole.staff,
        text: 'hi',
        messageType: MessageType.text,
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 1, 1),
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
      ),
    );
  }

  @override
  Future<Either<Failure, MessageEntity>> editMessage({
    required String messageCode,
    required String newText,
  }) async {
    if (editShouldFail) return Left(NetworkFailure('offline'));
    return Right(
      MessageEntity(
        id: messageCode,
        code: messageCode,
        conversationCode: 'CONV-1',
        senderCode: 'USR-1',
        senderName: 'Sender',
        senderRole: ParticipantRole.staff,
        text: newText,
        messageType: MessageType.text,
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 1, 1),
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
      ),
    );
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageCode) async {
    if (deleteShouldFail) return Left(NetworkFailure('offline'));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markSyncOperationCompleted(int id) async {
    completedIds.add(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markSyncOperationFailed({
    required int id,
    required String error,
    required int attempts,
  }) async {
    failedIds.add(id);
    return const Right(null);
  }

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
  Future<Either<Failure, int>> cleanupSyncQueue({int olderThanDays = 7}) async =>
      const Right(0);

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
  bool addShouldFail = false;
  bool removeShouldFail = false;

  @override
  Future<Either<Failure, void>> addReaction({
    required String messageCode,
    required String emoji,
  }) async {
    if (addShouldFail) return Left(NetworkFailure('offline'));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeReaction({
    required String messageCode,
    required String emoji,
  }) async {
    if (removeShouldFail) return Left(NetworkFailure('offline'));
    return const Right(null);
  }
}

SyncQueueEntity _op({
  required int id,
  required SyncOperationType operation,
  required String payload,
  int attempts = 0,
}) => SyncQueueEntity(
  id: id,
  operation: operation,
  entityCode: 'ENTITY-$id',
  status: SyncOperationStatus.pending,
  payload: payload,
  attempts: attempts,
  createdAt: DateTime(2026, 1, 1),
  organizationCode: 'ORG-1',
  schoolCode: 'SCH-1',
);

void main() {
  late _FakeMessageEntityRepository messageRepo;
  late _FakeReactionRepository reactionRepo;
  late DrainSyncQueueUseCase useCase;

  setUp(() {
    messageRepo = _FakeMessageEntityRepository();
    reactionRepo = _FakeReactionRepository();
    useCase = DrainSyncQueueUseCase(
      messageRepository: messageRepo,
      reactionRepository: reactionRepo,
    );
  });

  test('returns 0 and does nothing when the queue is empty', () async {
    messageRepo.pending = [];

    final count = await useCase();

    expect(count, 0);
    expect(messageRepo.completedIds, isEmpty);
  });

  test('replays a pending sendMessage op and marks it completed on success',
      () async {
    messageRepo.pending = [
      _op(
        id: 1,
        operation: SyncOperationType.sendMessage,
        payload: '{"localTempCode":"temp-1"}',
      ),
    ];

    final count = await useCase();

    expect(count, 1);
    expect(messageRepo.completedIds, [1]);
    expect(messageRepo.failedIds, isEmpty);
  });

  test('replays a pending editMessage op using messageCode/newText from payload',
      () async {
    messageRepo.pending = [
      _op(
        id: 2,
        operation: SyncOperationType.editMessage,
        payload: '{"messageCode":"MSG-1","newText":"edited"}',
      ),
    ];

    final count = await useCase();

    expect(count, 1);
    expect(messageRepo.completedIds, [2]);
  });

  test('replays addReaction/removeReaction via the reaction repository',
      () async {
    messageRepo.pending = [
      _op(
        id: 3,
        operation: SyncOperationType.addReaction,
        payload: '{"messageCode":"MSG-1","emoji":"👍"}',
      ),
      _op(
        id: 4,
        operation: SyncOperationType.removeReaction,
        payload: '{"messageCode":"MSG-1","emoji":"👎"}',
      ),
    ];

    final count = await useCase();

    expect(count, 2);
    expect(messageRepo.completedIds, containsAll([3, 4]));
  });

  test(
      'leaves a still-failing op PENDING (no markSyncOperationFailed call) below the attempt ceiling',
      () async {
    messageRepo.retryShouldFail = true;
    messageRepo.pending = [
      _op(
        id: 5,
        operation: SyncOperationType.sendMessage,
        payload: '{"localTempCode":"temp-5"}',
        attempts: 1,
      ),
    ];

    final count = await useCase();

    expect(count, 0);
    expect(messageRepo.completedIds, isEmpty);
    expect(messageRepo.failedIds, isEmpty);
  });

  test('marks a failing op FAILED once it reaches the attempt ceiling',
      () async {
    messageRepo.retryShouldFail = true;
    messageRepo.pending = [
      _op(
        id: 6,
        operation: SyncOperationType.sendMessage,
        payload: '{"localTempCode":"temp-6"}',
        attempts: 3, // next attempt (4) hits the ceiling
      ),
    ];

    final count = await useCase();

    expect(count, 0);
    expect(messageRepo.failedIds, [6]);
  });

  test('never throws on a malformed payload — treated as a failed attempt',
      () async {
    messageRepo.pending = [
      _op(
        id: 7,
        operation: SyncOperationType.editMessage,
        payload: 'not valid json',
      ),
    ];

    await expectLater(useCase(), completes);
  });
}
