/// Integration-level tests for the private-mode toggle flow.
///
/// These tests exercise PrivateModeToggleCubit + TogglePrivateModeUseCase
/// together against a controlled fake repository to verify end-to-end
/// state transitions without requiring a real network.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/private_mode_toggle_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/private_mode_toggle_state.dart';

// ── Controllable fake repository ──────────────────────────────────────────────

class _ControllableRepo implements ConversationEntityRepository {
  // Mutable list of calls so tests can inspect the sequence of operations.
  final List<({String conversationCode, bool enable})> calls = [];
  bool shouldFail;

  _ControllableRepo({this.shouldFail = false});

  @override
  Future<Either<Failure, void>> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async {
    calls.add((conversationCode: conversationCode, enable: enable));
    if (shouldFail) return Left(ServerFailure('network error'));
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

// ── Helper ────────────────────────────────────────────────────────────────────

PrivateModeToggleCubit _build(
  _ControllableRepo repo, {
  bool initialEnabled = false,
}) => PrivateModeToggleCubit(
  togglePrivateModeUseCase: TogglePrivateModeUseCase(repo),
  conversationCode: 'CONV-INT-001',
  initialEnabled: initialEnabled,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('Private mode end-to-end flow', () {
    test('parent enables private mode — correct API call emitted', () async {
      final repo = _ControllableRepo();
      final cubit = _build(repo);
      addTearDown(cubit.close);

      await cubit.toggle();

      expect(repo.calls, hasLength(1));
      expect(repo.calls.first.conversationCode, 'CONV-INT-001');
      expect(repo.calls.first.enable, isTrue);
      expect(cubit.state.isEnabled, isTrue);
    });

    test('parent disables private mode — correct API call emitted', () async {
      final repo = _ControllableRepo();
      final cubit = _build(repo, initialEnabled: true);
      addTearDown(cubit.close);

      await cubit.toggle();

      expect(repo.calls.first.enable, isFalse);
      expect(cubit.state.isEnabled, isFalse);
    });

    test('toggle → fail → retry succeeds — final state is enabled', () async {
      final repo = _ControllableRepo(shouldFail: true);
      final cubit = _build(repo);
      addTearDown(cubit.close);

      // First attempt fails
      await cubit.toggle();
      expect(cubit.state.isEnabled, isFalse);
      expect(cubit.state.errorMessage, isNotNull);

      // Simulate connectivity restored
      repo.shouldFail = false;
      await cubit.toggle();

      expect(cubit.state.isEnabled, isTrue);
      expect(cubit.state.errorMessage, isNull);
      expect(repo.calls, hasLength(2));
    });

    test('full on→off→on round-trip results in two API calls', () async {
      final repo = _ControllableRepo();
      final cubit = _build(repo);
      addTearDown(cubit.close);

      await cubit.toggle(); // on
      await cubit.toggle(); // off
      await cubit.toggle(); // on

      expect(repo.calls, hasLength(3));
      expect(repo.calls[0].enable, isTrue);
      expect(repo.calls[1].enable, isFalse);
      expect(repo.calls[2].enable, isTrue);
      expect(cubit.state.isEnabled, isTrue);
      expect(cubit.state.isLoading, isFalse);
    });

    test(
      'state stream sequence is correct during a single successful toggle',
      () async {
        final repo = _ControllableRepo();
        final cubit = _build(repo);
        addTearDown(cubit.close);

        final emitted = <PrivateModeToggleState>[];
        final sub = cubit.stream.listen(emitted.add);

        await cubit.toggle();
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(emitted, hasLength(2));
        // Optimistic emission
        expect(emitted[0].isEnabled, isTrue);
        expect(emitted[0].isLoading, isTrue);
        // Settled emission
        expect(emitted[1].isEnabled, isTrue);
        expect(emitted[1].isLoading, isFalse);
        expect(emitted[1].errorMessage, isNull);
      },
    );
  });
}
