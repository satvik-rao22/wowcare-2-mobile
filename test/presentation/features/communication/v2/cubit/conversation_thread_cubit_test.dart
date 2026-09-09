import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';
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
import 'package:wowcare/domain/features/communication/usecases/mark_draft_message_failed_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/remove_reaction_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_messages_usecase.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_attachment_uploader.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_thread_cubit.dart';
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

  /// Draft codes handed to [cacheDraftMessage], in order. `sendMessage` writes
  /// an optimistic draft before the network call, so these must record rather
  /// than throw — they were unimplemented stubs, which is what made every
  /// `sendMessage` case in this file fail.
  final List<MessageEntity> cachedDrafts = <MessageEntity>[];
  final List<String> failedDraftCodes = <String>[];

  @override
  Future<void> cacheDraftMessage(MessageEntity message) async {
    cachedDrafts.add(message);
  }

  @override
  Future<void> markDraftMessageFailed(String localTempCode) async {
    failedDraftCodes.add(localTempCode);
  }

  @override
  Future<Either<Failure, List<ReadReceiptEntity>>> getMessageReceipts(
    String messageCode,
  ) {
    // TODO: implement getMessageReceipts
    throw UnimplementedError();
  }
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

  @override
  Future<ChatAttachment> upload({
    required String conversationCode,
    required ChatAttachment attachment,
  }) async {
    if (attachment.isUploaded) return attachment;
    if (shouldFail) throw Exception('upload failed: ${attachment.name}');
    uploadedAttachmentNames.add(attachment.name);
    return attachment.copyWith(
      code: 'asset-${attachment.name}',
      attachmentId: attachment.name.hashCode,
    );
  }

  /// Held open by a test that wants to observe the optimistic state while the
  /// upload is still in flight.
  Completer<void>? uploadGate;

  /// `sendMessage` batches the whole selection through `uploadAll` (one upload
  /// session for the lot), not one `upload` per file. Only `upload` was faked,
  /// so the REAL `uploadAll` ran against a dummy-base-URL ImageUploadService:
  /// nothing was recorded and no attachmentIds came back.
  @override
  Future<List<ChatAttachment>> uploadAll({
    required String conversationCode,
    required List<ChatAttachment> attachments,
  }) async {
    final gate = uploadGate;
    if (gate != null) await gate.future;
    final result = <ChatAttachment>[];
    for (final attachment in attachments) {
      result.add(
        await upload(
          conversationCode: conversationCode,
          attachment: attachment,
        ),
      );
    }
    return result;
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
  // ConversationThreadCubit's mark-read path reads
  // `WidgetsBinding.instance.lifecycleState` (it must not stamp a message read
  // while the app is backgrounded). These are plain `test`s, not
  // `testWidgets`, so without this the binding getter throws
  // "Binding has not yet been initialized" and every case in this file fails.
  TestWidgetsFlutterBinding.ensureInitialized();

  // `sendMessage` copies picked files into permanent app storage before
  // sending (PendingAttachmentStorage.persistLocally), which asks
  // path_provider for the app-support directory. There is no plugin
  // implementation under `flutter test`, so the raw MethodChannel threw
  // MissingPluginException and every attachment case failed. Point it at a
  // real temp directory instead.
  late Directory appSupportDir;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    appSupportDir = Directory.systemTemp.createTempSync(
      'conversation_thread_cubit_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (call) async => appSupportDir.path,
        );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (appSupportDir.existsSync()) {
      appSupportDir.deleteSync(recursive: true);
    }
  });

  late _FakeMessageEntityRepository messageRepo;
  late _FakeConversationEntityRepository conversationRepo;
  late _FakeChatAttachmentUploader attachmentUploader;
  late ConversationThreadCubit cubit;

  setUp(() {
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

    test('shows the optimistic message with local attachment previews '
        'before upload or the network round-trip resolve', () async {
      // Hold the upload open, so what we observe below is unambiguously the
      // OPTIMISTIC bubble rather than the settled result.
      final gate = Completer<void>();
      attachmentUploader.uploadGate = gate;

      final sendFuture = cubit.sendMessage(
        text: 'hi',
        senderCode: 'USR-1',
        senderName: 'Me',
        senderRole: ParticipantRole.staff,
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
        attachments: [pendingAttachment('photo.jpg')],
      );

      // Not synchronous any more: `sendMessage` first awaits
      // PendingAttachmentStorage.persistLocally, which copies the picked
      // files into permanent app storage so a preview survives a restart.
      // The emit still precedes the upload and the network call, which is
      // what this test is actually about.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final optimistic = cubit.state.messages.single;
      expect(optimistic.attachments.single.fileName, 'photo.jpg');
      // The source file doesn't exist here, so persistLocally keeps the
      // original path (its documented fallback).
      expect(optimistic.attachments.single.localFilePath, '/tmp/photo.jpg');
      expect(optimistic.status, MessageStatus.pending);
      expect(cubit.state.isSending, isTrue);
      expect(
        attachmentUploader.uploadedAttachmentNames,
        isEmpty,
        reason: 'upload must not have run yet',
      );

      gate.complete();
      await sendFuture;
    });

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
