import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/approve_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/delete_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/reject_activity_usecase.dart';
import 'package:wowcare/presentation/features/activities/cubit/activity_moderation_cubit.dart';

class _LoudRepo implements ActivityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _GatedDelete extends DeleteActivityUseCase {
  _GatedDelete() : super(_LoudRepo());
  int calls = 0;
  final Completer<String> gate = Completer<String>();
  @override
  Future<String> call({required String code}) {
    calls++;
    return gate.future;
  }
}

class _GatedApprove extends ApproveActivityUseCase {
  _GatedApprove() : super(_LoudRepo());
  int calls = 0;
  @override
  Future<String> call({required String code}) async {
    calls++;
    return 'approved';
  }
}

void main() {
  test('two concurrent deletes of the same activity fire ONE underlying delete',
      () async {
    final del = _GatedDelete();
    final cubit = ActivityModerationCubit(
      deleteActivityUseCase: del,
      approveActivityUseCase: _GatedApprove(),
      rejectActivityUseCase: RejectActivityUseCase(_LoudRepo()),
    );

    unawaited(cubit.delete('ACT-1'));
    unawaited(cubit.delete('ACT-1')); // duplicate while first in flight

    await Future<void>.delayed(Duration.zero);
    expect(del.calls, 1);

    del.gate.complete('deleted');
    await Future<void>.delayed(Duration.zero);
    final state = cubit.state;
    expect(state, isA<ActivityModerationSuccess>());
    expect((state as ActivityModerationSuccess).code, 'ACT-1');
    expect(state.action, ActivityModerationAction.delete);

    await cubit.close();
  });

  test('approve is dropped while a delete of the SAME activity is in flight',
      () async {
    final del = _GatedDelete();
    final approve = _GatedApprove();
    final cubit = ActivityModerationCubit(
      deleteActivityUseCase: del,
      approveActivityUseCase: approve,
      rejectActivityUseCase: RejectActivityUseCase(_LoudRepo()),
    );

    unawaited(cubit.delete('ACT-1'));
    await Future<void>.delayed(Duration.zero);
    unawaited(cubit.approve('ACT-1')); // same activity, mutation already running
    await Future<void>.delayed(Duration.zero);

    expect(approve.calls, 0); // racing approve dropped
    expect(del.calls, 1);

    del.gate.complete('deleted');
    await cubit.close();
  });

  test('a different activity can be moderated concurrently', () async {
    final del = _GatedDelete();
    final approve = _GatedApprove();
    final cubit = ActivityModerationCubit(
      deleteActivityUseCase: del,
      approveActivityUseCase: approve,
      rejectActivityUseCase: RejectActivityUseCase(_LoudRepo()),
    );

    unawaited(cubit.delete('ACT-1'));
    await Future<void>.delayed(Duration.zero);
    unawaited(cubit.approve('ACT-2')); // different activity → allowed
    await Future<void>.delayed(Duration.zero);

    expect(approve.calls, 1);
    del.gate.complete('deleted');
    await cubit.close();
  });
}
