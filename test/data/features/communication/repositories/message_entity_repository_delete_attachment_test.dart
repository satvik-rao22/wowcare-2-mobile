import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_local_data_source.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_remote_data_source.dart';
import 'package:wowcare/data/features/communication/models/message_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/message_entity_dto.dart';
import 'package:wowcare/data/features/communication/models/sync_queue_collection.dart';
import 'package:wowcare/data/features/communication/realtime/message_realtime_data_source.dart';
import 'package:wowcare/data/features/communication/repositories/message_entity_repository_impl.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/reaction_repository.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeLocalDataSource implements MessageEntityLocalDataSource {
  final Map<String, MessageEntityCollection> _store = {};

  void seed(MessageEntity entity) {
    _store[entity.code] = MessageEntityCollection.fromEntity(entity);
  }

  MessageEntityCollection? peek(String code) => _store[code];

  @override
  Future<MessageEntityCollection?> getMessage(String messageCode) async =>
      _store[messageCode];

  @override
  Future<void> saveMessage(MessageEntity entity) async {
    _store[entity.code] = MessageEntityCollection.fromEntity(entity);
  }

  @override
  Future<List<MessageEntityCollection>> getMessages({
    required String conversationCode,
    required String organizationCode,
    required String schoolCode,
    int limit = 50,
    String? beforeMessageCode,
    String? currentUserCode,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveMessages({
    required List<MessageEntity> entities,
    required String conversationCode,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateMessageStatus({
    required String localTempCode,
    required String confirmedCode,
    required String status,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteMessage(String messageCode) async =>
      throw UnimplementedError();

  @override
  Future<void> clearMessages({
    required String conversationCode,
    required String organizationCode,
    required String schoolCode,
  }) async => throw UnimplementedError();

  @override
  Future<List<SyncQueueCollection>> getPendingOperations({
    required String organizationCode,
    required String schoolCode,
  }) async => throw UnimplementedError();

  @override
  Future<void> queueOperation(SyncQueueEntity entity) async =>
      throw UnimplementedError();

  @override
  Future<void> markOperationCompleted(int id) async =>
      throw UnimplementedError();

  @override
  Future<void> markOperationFailed({
    required int id,
    required String error,
    required int attempts,
  }) async => throw UnimplementedError();

  @override
  Future<int> cleanupSyncQueue({
    required String organizationCode,
    required String schoolCode,
    int olderThanDays = 7,
  }) async => throw UnimplementedError();
}

class _FakeRemoteDataSource implements MessageEntityRemoteDataSource {
  bool shouldFail = false;
  int? lastDeletedAttachmentId;

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    lastDeletedAttachmentId = attachmentId;
    if (shouldFail) throw Exception('network error');
  }

  @override
  Future<List<MessageEntityDto>> getMessages({
    required String conversationCode,
    String? beforeMessageCode,
    int size = 50,
  }) async => throw UnimplementedError();

  @override
  Future<MessageEntityDto> sendMessage({
    required String conversationCode,
    required String text,
    List<int> attachmentIds = const [],
    bool isPrivate = false,
    String? privateParentUserCode,
    String? threadParentCode,
  }) async => throw UnimplementedError();

  @override
  Future<MessageEntityDto> editMessage({
    required String messageCode,
    required String newText,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteMessage(String messageCode) async =>
      throw UnimplementedError();

  @override
  Future<void> addReaction({
    required String messageCode,
    required String emoji,
  }) async => throw UnimplementedError();

  @override
  Future<void> removeReaction({
    required String messageCode,
    required String emoji,
  }) async => throw UnimplementedError();

  @override
  Future<void> markMessageRead(String messageCode) async =>
      throw UnimplementedError();

  @override
  Future<List<ReadReceiptEntityDto>> getMessageReceipts(String messageCode) {
    // TODO: implement getMessageReceipts
    throw UnimplementedError();
  }
}

class _FakeRealtimeDataSource implements MessageRealtimeDataSource {
  @override
  Stream<List<MessageEntity>> watchMessages({
    required String organizationCode,
    required String schoolCode,
    required String conversationCode,
    required String currentUserCode,
    required bool isStaff,
    required bool isAdmin,
    int limit = 100,
  }) => const Stream.empty();
}

class _FakeStorageService implements StorageService {
  @override
  Future<String?> getString(String key) async => 'X';

  @override
  Future<void> saveString(String key, String value) async {}

  @override
  Future<int?> getInt(String key) async => null;

  @override
  Future<void> saveInt(String key, int value) async {}

  @override
  Future<bool?> getBool(String key) async => null;

  @override
  Future<void> saveBool(String key, bool value) async {}

  @override
  Future<Map<String, dynamic>?> getJson(String key) async => null;

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {}

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<Set<String>> getKeys() async => {};
}

class _FakeReactionRepository implements ReactionRepository {
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
}

// ── Fixture ────────────────────────────────────────────────────────────────────

MessageEntity _messageWithAttachments(List<AttachmentEntity> attachments) {
  return MessageEntity(
    id: 'MSG-1',
    code: 'MSG-1',
    conversationCode: 'CONV-1',
    senderCode: 'USR-1',
    senderName: 'Sender',
    senderRole: ParticipantRole.staff,
    text: 'hello',
    messageType: MessageType.text,
    status: MessageStatus.sent,
    sentAt: DateTime(2026, 1, 1),
    organizationCode: 'ORG-1',
    schoolCode: 'SCH-1',
    attachments: attachments,
  );
}

AttachmentEntity _attachment({
  required String code,
  required int? attachmentId,
}) {
  return AttachmentEntity(
    code: code,
    messageCode: 'MSG-1',
    conversationCode: 'CONV-1',
    fileName: 'file.jpg',
    fileUrl: 'https://example.com/file.jpg',
    mimeType: 'image/jpeg',
    fileSizeBytes: 100,
    attachmentType: AttachmentType.image,
    uploadedBy: 'USR-1',
    uploadedAt: DateTime(2026, 1, 1),
    attachmentId: attachmentId,
  );
}

void main() {
  late _FakeLocalDataSource local;
  late _FakeRemoteDataSource remote;
  late MessageEntityRepositoryImpl repository;

  setUp(() {
    local = _FakeLocalDataSource();
    remote = _FakeRemoteDataSource();
    repository = MessageEntityRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      realtimeDataSource: _FakeRealtimeDataSource(),
      storageService: _FakeStorageService(),
      reactionRepository: _FakeReactionRepository(),
    );
  });

  group('MessageEntityRepositoryImpl.deleteAttachment', () {
    test('removes only the targeted attachment from the cached message and '
        'calls the remote endpoint with its attachmentId', () async {
      final attachmentA = _attachment(code: 'A', attachmentId: 101);
      final attachmentB = _attachment(code: 'B', attachmentId: 102);
      local.seed(_messageWithAttachments([attachmentA, attachmentB]));

      final result = await repository.deleteAttachment(
        messageCode: 'MSG-1',
        attachmentId: 101,
      );

      expect(result.isRight(), isTrue);
      expect(remote.lastDeletedAttachmentId, 101);

      final cached = local.peek('MSG-1')!.toEntity();
      expect(cached.attachments.map((a) => a.code), ['B']);
    });

    test('rolls back the cache to the original attachment list when the '
        'remote call fails', () async {
      final attachmentA = _attachment(code: 'A', attachmentId: 101);
      final attachmentB = _attachment(code: 'B', attachmentId: 102);
      local.seed(_messageWithAttachments([attachmentA, attachmentB]));
      remote.shouldFail = true;

      final result = await repository.deleteAttachment(
        messageCode: 'MSG-1',
        attachmentId: 101,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('expected a Left'),
      );

      final cached = local.peek('MSG-1')!.toEntity();
      expect(cached.attachments.map((a) => a.code), ['A', 'B']);
    });

    test('is a no-op on the cache (but still calls remote) when the message '
        'is not cached locally', () async {
      final result = await repository.deleteAttachment(
        messageCode: 'NOT-CACHED',
        attachmentId: 999,
      );

      expect(result.isRight(), isTrue);
      expect(remote.lastDeletedAttachmentId, 999);
      expect(local.peek('NOT-CACHED'), isNull);
    });
  });
}
