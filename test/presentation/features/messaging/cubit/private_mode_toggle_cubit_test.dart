import 'dart:async';

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

// ── Fake repo ─────────────────────────────────────────────────────────────────

class _FakeRepo implements ConversationEntityRepository {
  bool shouldFail;
  int callCount = 0;
  Completer<Either<Failure, void>>? _hang;

  _FakeRepo({this.shouldFail = false, Completer<Either<Failure, void>>? hang})
      : _hang = hang;

  @override
  Future<Either<Failure, void>> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async {
    callCount++;
    if (_hang != null) return _hang!.future;
    if (shouldFail) return Left(ServerFailure('network error'));
    return const Right(null);
  }

  @override
  Stream<List<ConversationEntity>> watchConversations({ConversationType? type}) =>
      const Stream.empty();

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
  Future<Either<Failure, ConversationEntity>> getConversation(String code) async =>
      Left(ServerFailure('stub'));

  @override
  Future<Either<Failure, ConversationEntity?>> getCachedConversation(
    String code,
  ) async => const Right(null);

  @override
  Future<Either<Failure, ConversationEntity?>> findStaffDirectConversation(
    String recipientUserCode,
  ) async => const Right(null);

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
      getConversationsForClassroom(String classroomCode) async =>
          const Right([]);

  @override
  Future<Either<Failure, ConversationEntity>> createConversation({
    required ConversationType type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
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
}

// ── Helper ────────────────────────────────────────────────────────────────────

PrivateModeToggleCubit _cubit(
  _FakeRepo repo, {
  bool initialEnabled = false,
}) =>
    PrivateModeToggleCubit(
      togglePrivateModeUseCase: TogglePrivateModeUseCase(repo),
      conversationCode: 'CONV-001',
      initialEnabled: initialEnabled,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('PrivateModeToggleCubit', () {
    test('initial state reflects initialEnabled=false', () {
      final cubit = _cubit(_FakeRepo());
      addTearDown(cubit.close);
      expect(cubit.state,
          equals(const PrivateModeToggleState(isEnabled: false)));
    });

    test('initial state reflects initialEnabled=true', () {
      final cubit = _cubit(_FakeRepo(), initialEnabled: true);
      addTearDown(cubit.close);
      expect(cubit.state.isEnabled, isTrue);
    });

    test('toggle emits loading then success and flips isEnabled', () async {
      final repo = _FakeRepo();
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      final states = <PrivateModeToggleState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.toggle();
      // Give the event loop a tick so the settled emission is delivered.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states.length, 2);
      expect(states[0].isEnabled, isTrue);
      expect(states[0].isLoading, isTrue);
      expect(states[1].isEnabled, isTrue);
      expect(states[1].isLoading, isFalse);
      expect(states[1].errorMessage, isNull);
      expect(repo.callCount, 1);
    });

    test('toggle rolls back and sets errorMessage on failure', () async {
      final repo = _FakeRepo(shouldFail: true);
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      await cubit.toggle();

      // Check settled state directly — rollback is synchronous after fold.
      expect(cubit.state.isEnabled, isFalse, reason: 'should roll back');
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('concurrent toggle calls are ignored while in-flight', () async {
      final completer = Completer<Either<Failure, void>>();
      final repo = _FakeRepo(hang: completer);
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      unawaited(cubit.toggle());
      await Future<void>.delayed(Duration.zero);

      // Second call while first is in flight — should be a no-op
      await cubit.toggle();
      completer.complete(const Right(null));
      await Future<void>.delayed(Duration.zero);

      expect(repo.callCount, 1, reason: 'second call must be dropped');
    });

    test('toggling twice returns to original state', () async {
      final repo = _FakeRepo();
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      await cubit.toggle();
      await cubit.toggle();

      expect(cubit.state.isEnabled, isFalse);
      expect(cubit.state.isLoading, isFalse);
      expect(repo.callCount, 2);
    });

    test('error is cleared on subsequent successful toggle', () async {
      final repo = _FakeRepo(shouldFail: true);
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      await cubit.toggle();
      expect(cubit.state.errorMessage, isNotNull);

      repo.shouldFail = false;
      await cubit.toggle();

      expect(cubit.state.errorMessage, isNull);
    });
  });
}
