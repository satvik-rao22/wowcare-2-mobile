import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/repositories/message_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/add_reaction_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_attachment_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/delete_message_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/edit_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/remove_reaction_legacy_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/send_message_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';

typedef _VoidResult = Either<Failure, void>;

/// The `MessageEntityRepository` the thread screen writes through. Every
/// write succeeds, except a send (offline) and an edit (refused).
class _FakeMessageEntityRepository implements MessageEntityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return switch (invocation.memberName) {
      #sendMessage => Future<Either<Failure, MessageEntity>>.value(
        const Left(NetworkFailure('offline')),
      ),
      #editMessage => Future<Either<Failure, MessageEntity>>.value(
        const Left(ServerFailure('refused')),
      ),
      #addReaction ||
      #removeReaction ||
      #deleteMessage ||
      #deleteAttachment => Future<_VoidResult>.value(const Right(null)),
      _ => throw UnimplementedError('${invocation.memberName}'),
    };
  }
}

/// The legacy `CommunicationRepository` behind the staff and parent threads.
class _FakeCommunicationRepository implements CommunicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return switch (invocation.memberName) {
      #sendMessage => Future<Either<Failure, Message>>.value(
        Right(invocation.positionalArguments[1] as Message),
      ),
      #removeReaction ||
      #deleteMessage => Future<_VoidResult>.value(const Right(null)),
      _ => throw UnimplementedError('${invocation.memberName}'),
    };
  }
}

/// Finds no existing thread, then fails to create one.
class _FakeConversationRepository implements ConversationEntityRepository {
  int createCalls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #findStaffDirectConversation:
        return Future<Either<Failure, ConversationEntity?>>.value(
          const Right(null),
        );
      case #createConversation:
        createCalls++;
        return Future<Either<Failure, ConversationEntity>>.value(
          const Left(ServerFailure('500')),
        );
      case #togglePrivateMode:
        return Future<_VoidResult>.value(const Left(ServerFailure('500')));
    }
    throw UnimplementedError('${invocation.memberName}');
  }
}

void main() {
  final logs = <SentryLog>[];

  setUp(() async {
    logs.clear();
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..enableLogs = true
        ..transport = _DiscardingTransport()
        ..beforeSendLog = (log) {
          logs.add(log);
          return log;
        };
    });
  });

  tearDown(() => Sentry.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  ChatAttachment attachment(int id) => ChatAttachment(
    name: 'scan-$id.pdf',
    type: 'file',
    sizeBytes: 1024,
    mimeType: 'application/pdf',
    remoteUrl: 'https://cdn.example.com/scan-$id.pdf',
    code: 'AST-$id',
    attachmentId: id,
  );

  test('a legacy send logs its attachment count and no content', () async {
    final message = Message(
      id: 'temp-1',
      code: 'temp-1',
      text: 'Pickup moved to 4pm',
      isSentByMe: true,
      time: DateTime.utc(2026, 10, 12),
      attachments: [attachment(11), attachment(12)],
    );

    final result = await SendMessageUseCase(_FakeCommunicationRepository())(
      'CNV-1',
      message,
    );
    await settle();

    expect(result.isRight(), isTrue);
    final log = logs.single;
    expect(log.body, 'communication.message_send.succeeded');
    expect(log.attributes['count']!.value, 2);
    _expectNothingFrom(logs, [
      'CNV-1',
      'temp-1',
      'Pickup moved',
      'scan-11',
      'AST-11',
    ]);
  });

  test('an entity send that fails is bucketed from its Left', () async {
    final result =
        await SendMessageEntityUseCase(_FakeMessageEntityRepository())(
          conversationCode: 'CNV-1',
          text: 'Pickup moved to 4pm',
          attachmentIds: const [11, 12, 13],
          localTempCode: 'TMP-1',
          privateParentUserCode: 'USR-9',
          threadParentCode: 'MSG-0',
        );
    await settle();

    expect(result.isLeft(), isTrue);
    final log = logs.single;
    expect(log.body, 'communication.message_send.failed');
    expect(log.attributes['failure']!.value, 'network');
    expect(log.attributes['count']!.value, 3);
    _expectNothingFrom(logs, [
      'CNV-1',
      'Pickup moved',
      'TMP-1',
      'USR-9',
      'MSG-0',
    ]);
  });

  test('message and reaction writes log their outcome only', () async {
    final entityRepository = _FakeMessageEntityRepository();
    final legacyRepository = _FakeCommunicationRepository();

    await AddReactionEntityUseCase(entityRepository)(
      messageCode: 'MSG-1',
      emoji: 'heart',
    );
    await RemoveReactionLegacyUseCase(legacyRepository)(
      messageCode: 'MSG-1',
      emoji: 'heart',
    );
    await DeleteMessageUseCase(legacyRepository)('MSG-2');
    await DeleteAttachmentEntityUseCase(entityRepository)(
      messageCode: 'MSG-3',
      attachmentId: 98765,
    );
    await EditMessageEntityUseCase(entityRepository)(
      messageCode: 'MSG-4',
      newText: 'Corrected text',
    );
    await settle();

    expect(logs.map((log) => log.body), [
      'communication.reaction_add.succeeded',
      'communication.reaction_remove.succeeded',
      'communication.message_delete.succeeded',
      'communication.attachment_delete.succeeded',
      'communication.message_edit.failed',
    ]);
    expect(logs.last.attributes['failure']!.value, 'server');
    expect(logs.every((log) => log.attributes['count'] == null), isTrue);
    _expectNothingFrom(logs, ['MSG-', 'heart', '98765', 'Corrected text']);
  });

  group('conversation open', () {
    test('a find and a create are one event', () async {
      final repository = _FakeConversationRepository();

      await CreateOrOpenConversationUseCase(repository)(
        type: ConversationType.staffDirect,
        studentCode: 'STU-1',
        participantCodes: const ['STF-9'],
        title: 'Room 4 parents',
      );
      await settle();

      expect(repository.createCalls, 1);
      final log = logs.single;
      expect(log.body, 'communication.conversation_open.failed');
      expect(log.attributes['failure']!.value, 'server');
      _expectNothingFrom(logs, ['STU-1', 'STF-9', 'Room 4']);
    });

    test('a request the use case refuses is a validation failure', () async {
      final repository = _FakeConversationRepository();

      final result = await CreateOrOpenConversationUseCase(repository)(
        type: ConversationType.staffDirect,
        studentCode: 'STU-1',
      );
      await settle();

      expect(result.isLeft(), isTrue);
      expect(repository.createCalls, 0);
      expect(logs.single.body, 'communication.conversation_open.failed');
      expect(logs.single.attributes['failure']!.value, 'validation');
    });
  });

  test('a private mode toggle the server refuses is logged failed', () async {
    await TogglePrivateModeUseCase(_FakeConversationRepository())(
      conversationCode: 'CNV-1',
      enable: true,
    );
    await settle();

    expect(logs.single.body, 'communication.private_mode_toggle.failed');
    expect(logs.single.attributes['failure']!.value, 'server');
    _expectNothingFrom(logs, ['CNV-1']);
  });
}

/// Fails when any identifier or text passed in appears in a logged line.
void _expectNothingFrom(List<SentryLog> logs, List<String> passedIn) {
  final logged = [
    for (final log in logs) ...[
      log.body,
      for (final attribute in log.attributes.values) '${attribute.value}',
    ],
  ].join(' ');
  for (final value in passedIn) {
    expect(logged, isNot(contains(value)));
  }
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
