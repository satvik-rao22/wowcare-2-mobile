import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';

// ── Fake repo ─────────────────────────────────────────────────────────────────

class _FakeRepo implements ConversationEntityRepository {
  String? lastConversationCode;
  bool? lastEnableValue;
  bool shouldFail;

  _FakeRepo({this.shouldFail = false});

  @override
  Future<Either<Failure, void>> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async {
    lastConversationCode = conversationCode;
    lastEnableValue = enable;
    if (shouldFail) return Left(ServerFailure('server error'));
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
  Stream<int> watchTotalUnreadCount() => const Stream.empty();

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    ConversationType? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
    String? designation,
    String? staffStatus,
    String? classroom,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<ConversationEntity>>> getCachedConversations({
    ConversationType? type,
  }) async => const Right([]);

  @override
  Future<Either<Failure, ConversationEntity>> getConversation(
    String code,
  ) async => Left(ServerFailure('stub'));

  @override
  Future<Either<Failure, ConversationEntity?>> getCachedConversation(
    String code,
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
  }) async => Left(ServerFailure('stub'));

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
  Future<Either<Failure, Map<String, int>>> getUnreadAggregates() async =>
      const Right({});

  @override
  Future<Either<Failure, void>> markConversationRead(
    String conversationCode,
  ) async => const Right(null);

  @override
  Future<Either<Failure, List<UnreadEntity>>> syncUnreadCounts() async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> clearConversationsCache() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> markConversationDelivered(
    String conversationCode,
  ) {
    // TODO: implement markConversationDelivered
    throw UnimplementedError();
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TogglePrivateModeUseCase', () {
    test('passes conversationCode and enable=true to repository', () async {
      final repo = _FakeRepo();
      final useCase = TogglePrivateModeUseCase(repo);

      final result = await useCase(conversationCode: 'CONV-123', enable: true);

      expect(result.isRight(), isTrue);
      expect(repo.lastConversationCode, 'CONV-123');
      expect(repo.lastEnableValue, isTrue);
    });

    test('passes conversationCode and enable=false to repository', () async {
      final repo = _FakeRepo();
      final useCase = TogglePrivateModeUseCase(repo);

      await useCase(conversationCode: 'CONV-456', enable: false);

      expect(repo.lastEnableValue, isFalse);
    });

    test('propagates Failure from repository', () async {
      final repo = _FakeRepo(shouldFail: true);
      final useCase = TogglePrivateModeUseCase(repo);

      final result = await useCase(conversationCode: 'CONV-001', enable: true);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });
}
