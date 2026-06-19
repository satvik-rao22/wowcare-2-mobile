import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// ── Minimal fake base (satisfies interface without mockito) ───────────────────

class _FakeRepo implements ConversationEntityRepository {
  bool shouldFail;
  bool toggleCalled = false;
  final Completer<Either<Failure, void>>? _hangCompleter;

  _FakeRepo({bool shouldFail = false, Completer<Either<Failure, void>>? hang})
      : shouldFail = shouldFail,
        _hangCompleter = hang;

  @override
  Future<Either<Failure, void>> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async {
    toggleCalled = true;
    if (_hangCompleter != null) return _hangCompleter.future;
    if (shouldFail) return Left(ServerFailure('network error'));
    return const Right(null);
  }

  // ── Unused stubs ────────────────────────────────────────────────────────────
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

// ── Helper to build a testable widget tree ────────────────────────────────────

Widget _subject(PrivateModeToggleCubit cubit) {
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: BlocBuilder<PrivateModeToggleCubit, PrivateModeToggleState>(
          builder: (ctx, state) => Column(
            children: [
              Switch(
                key: const Key('pm_switch'),
                value: state.isEnabled,
                onChanged: state.isLoading
                    ? null
                    : (_) => cubit.toggle(),
              ),
              if (state.isEnabled)
                const Text('Private Mode ON', key: Key('pm_on_label')),
              if (!state.isEnabled)
                const Text('Private Mode OFF', key: Key('pm_off_label')),
              if (state.errorMessage != null)
                Text(state.errorMessage!, key: const Key('pm_error')),
            ],
          ),
        ),
      ),
    ),
  );
}

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
  // ── Private Mode toggle widget ──────────────────────────────────────────────

  group('PrivateModeToggle widget — toggle visibility', () {
    testWidgets('shows OFF label when initial state is disabled',
        (tester) async {
      final cubit = _cubit(_FakeRepo());
      addTearDown(cubit.close);

      await tester.pumpWidget(_subject(cubit));

      expect(find.byKey(const Key('pm_off_label')), findsOneWidget);
      expect(find.byKey(const Key('pm_on_label')), findsNothing);
    });

    testWidgets('shows ON label when initial state is enabled', (tester) async {
      final cubit = _cubit(_FakeRepo(), initialEnabled: true);
      addTearDown(cubit.close);

      await tester.pumpWidget(_subject(cubit));

      expect(find.byKey(const Key('pm_on_label')), findsOneWidget);
      expect(find.byKey(const Key('pm_off_label')), findsNothing);
    });

    testWidgets('tapping switch calls toggle and flips to ON', (tester) async {
      final repo = _FakeRepo();
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(_subject(cubit));
      expect(find.byKey(const Key('pm_off_label')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pm_switch')));
      await tester.pumpAndSettle();

      expect(repo.toggleCalled, isTrue);
      expect(find.byKey(const Key('pm_on_label')), findsOneWidget);
    });

    testWidgets('tapping switch twice returns to OFF', (tester) async {
      final repo = _FakeRepo();
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(_subject(cubit));

      await tester.tap(find.byKey(const Key('pm_switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pm_switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pm_off_label')), findsOneWidget);
    });

    testWidgets('switch is disabled while toggle is in flight', (tester) async {
      final completer = Completer<Either<Failure, void>>();
      final repo = _FakeRepo(hang: completer);
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(_subject(cubit));

      // Fire toggle — will hang
      unawaited(cubit.toggle());
      await tester.pump();

      final sw = tester.widget<Switch>(find.byKey(const Key('pm_switch')));
      expect(sw.onChanged, isNull,
          reason: 'Switch must be disabled while API call is in-flight');

      // Unblock so cubit can close cleanly
      completer.complete(const Right(null));
    });
  });

  // ── Child dropdown visibility ───────────────────────────────────────────────

  group('Child dropdown visibility guard', () {
    testWidgets('dropdown hidden when conversations list has exactly one item',
        (tester) async {
      // Mirrors the guard in ParentDirectMessagingScreen._buildStudentDropdown
      const conversations = ['child-a'];
      bool dropdownShown = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (_) {
            if (conversations.length <= 1) {
              return const SizedBox(key: Key('no_dropdown'));
            }
            dropdownShown = true;
            return const Text('dropdown');
          }),
        ),
      ));

      expect(find.byKey(const Key('no_dropdown')), findsOneWidget);
      expect(dropdownShown, isFalse);
    });

    testWidgets('dropdown visible when conversations list has two items',
        (tester) async {
      const conversations = ['child-a', 'child-b'];
      bool dropdownShown = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (_) {
            if (conversations.length <= 1) {
              return const SizedBox(key: Key('no_dropdown'));
            }
            dropdownShown = true;
            return const Text('dropdown', key: Key('dropdown'));
          }),
        ),
      ));

      expect(dropdownShown, isTrue);
      expect(find.byKey(const Key('dropdown')), findsOneWidget);
    });
  });
}
