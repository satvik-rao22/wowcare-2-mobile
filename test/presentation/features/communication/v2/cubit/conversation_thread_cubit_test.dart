import 'dart:async';

import 'package:dartz/dartz.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/add_reaction_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/cache_draft_message_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_attachment_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/edit_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_messages_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_message_entity_receipts_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_messages_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/mark_conversation_read_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_classroom_roster_present_user_codes_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/mark_draft_message_failed_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/remove_reaction_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_messages_usecase.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_attachment_uploader.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_thread_state.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeMessageEntityRepository implements MessageEntityRepository {
  final _messagesController = StreamController<List<MessageEntity>>.broadcast();

  @override
  Stream<List<MessageEntity>> watchMessages({
    String? organizationCode,
    String? schoolCode,
    required String conversationCode,
    int limit = 100,
  }) => _messagesController.stream;

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

  bool sendMessageShouldFail = false;
  List<int>? lastSendAttachmentIds;
  int sendMessageCallCount = 0;

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationCode,
    required String text,
    List<int> attachmentIds = const [],
    List<AttachmentEntity> attachments = const [],
    bool isPrivate = false,
    String? privateParentUserCode,
    String? threadParentCode,
    String? localTempCode,
  }) async {
    sendMessageCallCount++;
    lastSendAttachmentIds = attachmentIds;
    if (sendMessageShouldFail) {
      return Left(NetworkFailure('send failed'));
    }
    return Right(
      MessageEntity(
        id: 'SERVER-1',
        code: 'SERVER-1',
        conversationCode: conversationCode,
        senderCode: 'USR-1',
        senderName: 'Sender',
        senderRole: ParticipantRole.staff,
        text: text,
        messageType: MessageType.text,
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 1, 1),
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
        // Mirrors the real backend: the create-message response doesn't
        // echo back resolved attachment objects yet.
        attachments: const [],
      ),
    );
  }

  @override
  Future<Either<Failure, MessageEntity>> editMessage({
    required String messageCode,
    required String newText,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteMessage(String messageCode) async =>
      throw UnimplementedError();

  bool deleteAttachmentShouldFail = false;
  String? lastDeleteAttachmentMessageCode;
  int? lastDeleteAttachmentId;

  @override
  Future<Either<Failure, void>> deleteAttachment({
    required String messageCode,
    required int attachmentId,
  }) async {
    lastDeleteAttachmentMessageCode = messageCode;
    lastDeleteAttachmentId = attachmentId;
    if (deleteAttachmentShouldFail) {
      return Left(NetworkFailure('network error'));
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, MessageEntity>> retryFailedMessage(
    String localTempCode,
  ) async => throw UnimplementedError();

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
  Future<Either<Failure, List<SyncQueueEntity>>>
  getPendingSyncOperations() async => const Right([]);

  @override
  Future<Either<Failure, int>> cleanupSyncQueue({
    int olderThanDays = 7,
  }) async => const Right(0);

  @override
  Future<Either<Failure, void>> clearMessagesCache(
    String conversationCode,
  ) async => const Right(null);

  void emit(List<MessageEntity> messages) => _messagesController.add(messages);

  Future<void> dispose() => _messagesController.close();

  int cacheDraftMessageCallCount = 0;
  int markDraftMessageFailedCallCount = 0;

  @override
  Future<void> cacheDraftMessage(MessageEntity message) async {
    cacheDraftMessageCallCount++;
  }

  @override
  Future<void> markDraftMessageFailed(String localTempCode) async {
    markDraftMessageFailedCallCount++;
  }

  @override
  Future<Either<Failure, List<ReadReceiptEntity>>> getMessageReceipts(
    String messageCode,
  ) async => const Right(<ReadReceiptEntity>[]);
}

class _FakeConversationEntityRepository
    implements ConversationEntityRepository {
  int markConversationReadCallCount = 0;

  @override
  Future<Either<Failure, void>> markConversationRead(
    String conversationCode,
  ) async {
    markConversationReadCallCount++;
    return const Right(null);
  }

  @override
  Stream<List<ConversationEntity>> watchConversations({
    ConversationType? type,
  }) => const Stream.empty();

  @override
  Stream<int> watchUnreadCountForType(ConversationType type) =>
      const Stream.empty();

  @override
  Stream<int> watchUnreadCountForConversation(String conversationCode) =>
      const Stream.empty();

  @override
  Stream<int> watchTotalUnreadCount() => const Stream.empty();

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    ConversationType? type,
    String? status,
    int page = 0,
    int size = 20,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
    bool? unreadOnly,
    bool includeRestUnreadCounts = true,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<ConversationEntity>>> getCachedConversations({
    ConversationType? type,
  }) async => const Right([]);

  @override
  Future<Either<Failure, ConversationEntity>> getConversation(
    String conversationCode,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, ConversationEntity?>> getCachedConversation(
    String conversationCode,
  ) async => const Right(null);

  @override
  Future<Either<Failure, ConversationEntity?>> findStaffDirectConversation(
    String recipientUserCode,
  ) async => const Right(null);

  @override
  Future<Either<Failure, ConversationEntity?>> findRoomChatConversation({
    required String studentCode,
    String? classroomCode,
  }) async => const Right(null);

  @override
  Future<Either<Failure, ConversationEntity?>> findAdminChatConversation({
    required String studentCode,
  }) async => const Right(null);

  @override
  Future<Either<Failure, List<MessagingStaffResult>>> searchStaffForMessaging({
    required String query,
    required String organizationCode,
    required String schoolCode,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversationsForStudent(
    String studentCode,
  ) async => const Right([]);

  @override
  Future<Either<Failure, List<ConversationEntity>>>
  getConversationsForClassroom(String classroomCode) async => const Right([]);

  @override
  Future<Either<Failure, ConversationEntity>> createConversation({
    required ConversationType type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
    String title = '',
    String description = '',
    String avatarUrl = '',
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<ParticipantEntity>>> addParticipants({
    required String conversationCode,
    required List<String> userCodes,
  }) async => const Right([]);

  @override
  Future<Either<Failure, void>> removeParticipants({
    required String conversationCode,
    required List<String> userCodes,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async => const Right(null);

  @override
  Future<Either<Failure, Map<String, int>>> getUnreadAggregates() async =>
      const Right({});

  @override
  Future<Either<Failure, List<UnreadEntity>>> syncUnreadCounts() async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> clearConversationsCache() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> markConversationDelivered(
    String conversationCode,
  ) async => const Right(null);

  @override
  Future<Either<Failure, Unit>> reconcileClassroomChat(
    String classroomCode, {
    String? classroomName,
  }) {
    // TODO: implement reconcileClassroomChat
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Map<String, int>>> getUnreadCountsPerConversation() {
    // TODO: implement getUnreadCountsPerConversation
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Set<String>>> getClassroomRosterPresentUserCodes(
    String classroomCode,
  ) {
    // TODO: implement getClassroomRosterPresentUserCodes
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Map<String, int>>> getUnreadCountsByType() {
    // TODO: implement getUnreadCountsByType
    throw UnimplementedError();
  }
}

/// Overrides `upload()` entirely, so the real `ImageUploadService`/
/// `StorageService` it's constructed with are never actually invoked — they
/// only exist to satisfy [ChatAttachmentUploader]'s constructor.
class _FakeChatAttachmentUploader extends ChatAttachmentUploader {
  _FakeChatAttachmentUploader()
    : super(
        ImageUploadService(ApiClient(baseUrl: 'http://unused')),
        _UnusedStorageService(),
      );

  bool shouldFail = false;
  final List<String> uploadedAttachmentNames = [];

  // The cubit's send flow calls uploadAll (batch); override that rather than
  // the `upload` convenience wrapper (which the base delegates through it).
  @override
  Future<List<ChatAttachment>> uploadAll({
    required String conversationCode,
    required List<ChatAttachment> attachments,
  }) async {
    final out = <ChatAttachment>[];
    for (final attachment in attachments) {
      if (attachment.isUploaded) {
        out.add(attachment);
        continue;
      }
      if (shouldFail) throw Exception('upload failed: ${attachment.name}');
      uploadedAttachmentNames.add(attachment.name);
      out.add(
        attachment.copyWith(
          code: 'asset-${attachment.name}',
          attachmentId: attachment.name.hashCode,
        ),
      );
    }
    return out;
  }
}

class _UnusedStorageService implements StorageService {
  @override
  Future<String?> getString(String key) async => null;
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

MessageEntity _message(
  String code, {
  List<AttachmentEntity> attachments = const [],
}) => MessageEntity(
  id: code,
  code: code,
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

AttachmentEntity _attachment({
  required String code,
  required int attachmentId,
}) => AttachmentEntity(
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

void main() {
  // ConversationThreadCubit._markRead reads WidgetsBinding.instance
  // .lifecycleState (it must NOT mark-read while backgrounded). A pure unit
  // test has no widget binding, so initialize one and put the app in the
  // foreground (`resumed`) — the state a user reading a thread is actually in.
  TestWidgetsFlutterBinding.ensureInitialized();

  // sendMessage persists picked attachments to getApplicationSupportDirectory
  // (PendingAttachmentStorage) for durability. path_provider has no plugin in a
  // unit test, so stub its channel to a real temp dir.
  final tmpDir = Directory.systemTemp.createTempSync('conv_thread_test');
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tmpDir.path,
      );

  late _FakeMessageEntityRepository messageRepo;
  late _FakeConversationEntityRepository conversationRepo;
  late _FakeChatAttachmentUploader attachmentUploader;
  late ConversationThreadCubit cubit;

  setUp(() {
    TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    messageRepo = _FakeMessageEntityRepository();
    conversationRepo = _FakeConversationEntityRepository();
    attachmentUploader = _FakeChatAttachmentUploader();
    cubit = ConversationThreadCubit(
      conversationCode: 'CONV-1',
      currentUserCode: 'USR-1',
      watchMessagesUseCase: WatchMessagesUseCase(messageRepo),
      getMessagesUseCase: GetMessagesEntityUseCase(messageRepo),
      sendMessageUseCase: SendMessageEntityUseCase(messageRepo),
      editMessageUseCase: EditMessageEntityUseCase(messageRepo),
      deleteMessageUseCase: DeleteMessageEntityUseCase(messageRepo),
      deleteAttachmentUseCase: DeleteAttachmentEntityUseCase(messageRepo),
      addReactionUseCase: AddReactionEntityUseCase(messageRepo),
      removeReactionUseCase: RemoveReactionUseCase(messageRepo),
      markConversationReadUseCase: MarkConversationReadUseCase(
        conversationRepo,
      ),
      attachmentUploader: attachmentUploader,
      // Short duration so the test doesn't wait 2 real seconds.
      markReadDebounceDuration: const Duration(milliseconds: 20),
      cacheDraftMessageUseCase: CacheDraftMessageUseCase(messageRepo),
      markDraftMessageFailedUseCase: MarkDraftMessageFailedUseCase(messageRepo),
      getCachedMessagesEntityUseCase: GetCachedMessagesEntityUseCase(
        messageRepo,
      ),
      getMessageReceiptsUseCase: GetMessageEntityReceiptsUseCase(messageRepo),
      storageService: _UnusedStorageService(),
      conversationRepository: conversationRepo,
      getClassroomRosterUseCase: GetClassroomRosterPresentUserCodesUseCase(
        conversationRepo,
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
    await messageRepo.dispose();
  });

  group('markConversationRead debounce', () {
    test('a burst of Firestore snapshot emissions collapses into a single '
        'markConversationRead call', () async {
      cubit.startWatchingMessages();

      // Simulate 5 rapid snapshot emissions (e.g. several reactions/edits
      // landing in quick succession) — all well within the debounce window.
      for (var i = 0; i < 5; i++) {
        messageRepo.emit([_message('MSG-$i')]);
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      expect(conversationRepo.markConversationReadCallCount, 0);

      // Let the debounce window elapse.
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(conversationRepo.markConversationReadCallCount, 1);
    });

    test(
      'a second burst after the window elapses triggers a second call',
      () async {
        cubit.startWatchingMessages();

        messageRepo.emit([_message('MSG-0')]);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(conversationRepo.markConversationReadCallCount, 1);

        messageRepo.emit([_message('MSG-1')]);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(conversationRepo.markConversationReadCallCount, 2);
      },
    );

    test('closing the cubit mid-debounce flushes the pending mark-read instead '
        'of dropping it', () async {
      cubit.startWatchingMessages();
      messageRepo.emit([_message('MSG-0')]);

      // Close well before the 20ms debounce window would have elapsed.
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cubit.close();

      // The flush fires the repository call without awaiting it from
      // inside close(); give the microtask queue a tick to run it.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(conversationRepo.markConversationReadCallCount, 1);
    });
  });

  group('deleteAttachment', () {
    test('optimistically removes only the targeted attachment and calls the '
        'use case with the messageCode/attachmentId pair', () async {
      cubit.startWatchingMessages();
      final attachmentA = _attachment(code: 'A', attachmentId: 101);
      final attachmentB = _attachment(code: 'B', attachmentId: 102);
      messageRepo.emit([
        _message('MSG-1', attachments: [attachmentA, attachmentB]),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await cubit.deleteAttachment(messageCode: 'MSG-1', attachmentId: 101);

      expect(messageRepo.lastDeleteAttachmentMessageCode, 'MSG-1');
      expect(messageRepo.lastDeleteAttachmentId, 101);
      final updated = cubit.state.messages.single;
      expect(updated.attachments.map((a) => a.code), ['B']);
    });

    test(
      'rolls back to the original attachments list when the use case fails',
      () async {
        cubit.startWatchingMessages();
        final attachmentA = _attachment(code: 'A', attachmentId: 101);
        final attachmentB = _attachment(code: 'B', attachmentId: 102);
        messageRepo.emit([
          _message('MSG-1', attachments: [attachmentA, attachmentB]),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        messageRepo.deleteAttachmentShouldFail = true;

        await cubit.deleteAttachment(messageCode: 'MSG-1', attachmentId: 101);

        final restored = cubit.state.messages.single;
        expect(restored.attachments.map((a) => a.code), ['A', 'B']);
        expect(cubit.state.errorMessage, isNotNull);
      },
    );

    test('leaves other messages in the thread untouched', () async {
      cubit.startWatchingMessages();
      final attachmentA = _attachment(code: 'A', attachmentId: 101);
      messageRepo.emit([
        _message('MSG-0'),
        _message('MSG-1', attachments: [attachmentA]),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await cubit.deleteAttachment(messageCode: 'MSG-1', attachmentId: 101);

      final untouched = cubit.state.messages.firstWhere(
        (m) => m.code == 'MSG-0',
      );
      expect(untouched.attachments, isEmpty);
      final edited = cubit.state.messages.firstWhere((m) => m.code == 'MSG-1');
      expect(edited.attachments, isEmpty);
    });
  });

  group('sendMessage with attachments', () {
    ChatAttachment pendingAttachment(String name) => ChatAttachment(
      name: name,
      type: 'image',
      sizeBytes: 100,
      mimeType: 'image/jpeg',
      remoteUrl: '',
      localPath: '/tmp/$name',
    );

    test(
      'shows the optimistic message with local attachment previews '
      'immediately, before upload or the network round-trip resolve',
      () async {
        // The optimistic bubble is emitted (status `pending`, with the local
        // attachment preview) after the local-persist step but before the
        // upload/network round-trip resolves. With everything faked, that whole
        // sequence completes almost instantly, so rather than race a fixed
        // delay, record the emitted states and assert a pending optimistic
        // bubble WAS shown before the message settled to `sent`. (The persist
        // copy of the test-only non-existent source path fails gracefully and
        // keeps the original localPath.)
        final emitted = <ConversationThreadState>[];
        final sub = cubit.stream.listen(emitted.add);

        await cubit.sendMessage(
          text: 'hi',
          senderCode: 'USR-1',
          senderName: 'Me',
          senderRole: ParticipantRole.staff,
          organizationCode: 'ORG-1',
          schoolCode: 'SCH-1',
          attachments: [pendingAttachment('photo.jpg')],
        );
        await sub.cancel();

        final optimisticStates = emitted.where(
          (s) => s.messages.any(
            (m) =>
                m.status == MessageStatus.pending &&
                m.attachments.length == 1 &&
                m.attachments.single.fileName == 'photo.jpg' &&
                m.attachments.single.localFilePath == '/tmp/photo.jpg',
          ),
        );
        expect(
          optimisticStates,
          isNotEmpty,
          reason:
              'a pending optimistic bubble with the local preview should '
              'have been emitted before upload/send resolved',
        );
        // And it ultimately settled to sent.
        expect(cubit.state.messages.single.status, MessageStatus.sent);
      },
    );

    test(
      'uploads each attachment and sends the resulting attachmentIds',
      () async {
        await cubit.sendMessage(
          text: 'hi',
          senderCode: 'USR-1',
          senderName: 'Me',
          senderRole: ParticipantRole.staff,
          organizationCode: 'ORG-1',
          schoolCode: 'SCH-1',
          attachments: [pendingAttachment('a.jpg'), pendingAttachment('b.pdf')],
        );

        expect(attachmentUploader.uploadedAttachmentNames, ['a.jpg', 'b.pdf']);
        expect(messageRepo.sendMessageCallCount, 1);
        expect(messageRepo.lastSendAttachmentIds, [
          'a.jpg'.hashCode,
          'b.pdf'.hashCode,
        ]);
      },
    );

    test('aborts the send entirely when an attachment fails to upload — no '
        'text-only message is sent', () async {
      attachmentUploader.shouldFail = true;

      await cubit.sendMessage(
        text: 'hi',
        senderCode: 'USR-1',
        senderName: 'Me',
        senderRole: ParticipantRole.staff,
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
        attachments: [pendingAttachment('a.jpg')],
      );

      expect(messageRepo.sendMessageCallCount, 0);
      expect(cubit.state.sendError, isNotNull);
      final failed = cubit.state.messages.single;
      expect(failed.status, MessageStatus.failed);
      // The local attachment is preserved on the failed bubble.
      expect(failed.attachments.single.fileName, 'a.jpg');
    });

    test('keeps the uploaded attachment data on the bubble when the network '
        'send fails after a successful upload', () async {
      messageRepo.sendMessageShouldFail = true;

      await cubit.sendMessage(
        text: 'hi',
        senderCode: 'USR-1',
        senderName: 'Me',
        senderRole: ParticipantRole.staff,
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
        attachments: [pendingAttachment('a.jpg')],
      );

      expect(attachmentUploader.uploadedAttachmentNames, ['a.jpg']);
      final failed = cubit.state.messages.single;
      expect(failed.status, MessageStatus.failed);
      expect(failed.attachments.single.fileName, 'a.jpg');
      expect(cubit.state.sendError, isNotNull);
    });

    test('sends a text-only message without touching the uploader', () async {
      await cubit.sendMessage(
        text: 'hi',
        senderCode: 'USR-1',
        senderName: 'Me',
        senderRole: ParticipantRole.staff,
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
      );

      expect(attachmentUploader.uploadedAttachmentNames, isEmpty);
      expect(messageRepo.lastSendAttachmentIds, isEmpty);
      expect(cubit.state.messages.single.status, MessageStatus.sent);
    });
  });
}
