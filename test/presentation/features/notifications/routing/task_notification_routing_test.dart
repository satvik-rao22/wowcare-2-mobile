import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';
import 'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart';

/// The Task push-notification contract, end to end on the client side: the six
/// `TASK_*` actions the backend fires must each resolve to a destination.
/// Every action except `TASK_DELETED` now carries the real `assignmentCode`
/// (backend added it to `TASK_ASSIGNED`/`TASK_UPDATED` 2026-08-07 — they used
/// to send only the series), so the resolver opens the exact card directly;
/// `TasksState.myAssignmentInSeries` is exercised separately below as the
/// fallback for a degraded/legacy payload that still omits it.
void main() {
  // The contract's own sample codes, so a failure here reads against the doc.
  const org = 'ORG_67F60097-C';
  const school = 'SCH_74709D20-7';
  const series = 'TSK_A1B2C3D4';
  const assignment = 'TSA_1E7A4D9F3C';
  const staff = 'STF_7E922B33';

  PushNotification push(String action, Map<String, String> extra) =>
      PushNotification(
        title: null,
        body: null,
        action: action,
        type: 'TASK',
        data: <String, String>{
          'action': action,
          'type': 'TASK',
          'organizationCode': org,
          'schoolCode': school,
          ...extra,
        },
      );

  group('resolver — every non-deleted action carries the assignment code', () {
    // All five open the exact card — no series/identity pairing needed. The
    // resolver reads whichever code is present without branching on the
    // action, so TASK_ASSIGNED / TASK_UPDATED joining the other three needed
    // no resolver change, only this test to lock the contract in.
    for (final action in const [
      'TASK_ASSIGNED',
      'TASK_UPDATED',
      'TASK_STATUS_UPDATED',
      'TASK_OVERDUE',
      'TASK_DUE_SOON',
    ]) {
      test('$action → detail with assignmentCode as taskCode', () {
        final dest = NotificationRouteResolver.resolve(push(action, {
          'assignmentCode': assignment,
          'taskCode': series,
          'taskTitle': 'Restock the first-aid kit',
          'staffCode': staff,
        }));

        expect(dest, isNotNull);
        expect(dest!.path, '/dashboard/tasks/detail');
        expect(dest.queryParameters['taskCode'], assignment);
        // The series travels too, so the Schedule section can load without
        // waiting for the card to resolve.
        expect(dest.queryParameters['seriesCode'], series);
      });
    }
  });

  group('resolver — degraded payload carrying only the series code', () {
    // A legacy/degraded TASK_ASSIGNED or TASK_UPDATED that still omits
    // assignmentCode falls back to seriesCode + myAssignmentInSeries — see the
    // group below. Not the normal case per the current contract, but the
    // resolver must not break on it.
    for (final action in const ['TASK_ASSIGNED', 'TASK_UPDATED']) {
      test('$action without assignmentCode → detail with seriesCode only', () {
        final dest = NotificationRouteResolver.resolve(push(action, {
          'taskCode': series,
          'taskTitle': 'Restock the first-aid kit',
          'staffCode': staff,
        }));

        expect(dest, isNotNull);
        expect(dest!.path, '/dashboard/tasks/detail');
        expect(dest.queryParameters['seriesCode'], series);
        expect(dest.queryParameters.containsKey('taskCode'), isFalse);
      });
    }
  });

  test('TASK_DELETED → the task list, since the card no longer exists', () {
    final dest = NotificationRouteResolver.resolve(push('TASK_DELETED', {
      'taskCode': series,
      'taskTitle': 'Restock the first-aid kit',
    }));

    expect(dest, isNotNull);
    expect(dest!.path, '/dashboard/tasks');
  });

  test('a task push with neither code falls back to the inbox, not an empty card',
      () {
    final dest = NotificationRouteResolver.resolve(
      push('TASK_ASSIGNED', {'taskTitle': 'Restock the first-aid kit'}),
    );

    expect(dest, isNotNull);
    expect(dest!.path, '/notifications');
  });

  test('snake_case code keys resolve as well as camelCase', () {
    final dest = NotificationRouteResolver.resolve(push('TASK_OVERDUE', {
      'assignment_code': assignment,
      'task_code': series,
    }));

    expect(dest!.queryParameters['taskCode'], assignment);
    expect(dest.queryParameters['seriesCode'], series);
  });

  // Exercised directly (independent of the resolver) as the fallback a
  // degraded/legacy TASK_ASSIGNED / TASK_UPDATED payload — one still missing
  // assignmentCode — falls back to: pairing the series with the signed-in
  // user's identity to find the one card.
  group('myAssignmentInSeries — series code + identity → one card', () {
    Task task({
      required String code,
      required String seriesCode,
      required String assigneeCode,
      required DateTime dueDate,
    }) =>
        Task(
          code: code,
          taskCode: seriesCode,
          title: 'Restock the first-aid kit',
          assigneeCode: assigneeCode,
          startDate: dueDate,
          dueDate: dueDate,
          createdAt: dueDate,
          updatedAt: dueDate,
        );

    TasksState stateWith(List<Task> tasks, {String staffCode = staff}) =>
        const TasksState.initial()
            .copyWith(tasks: tasks, currentStaffCode: staffCode);

    test('picks the current user\'s assignment, not a colleague\'s', () {
      final mine = task(
        code: assignment,
        seriesCode: series,
        assigneeCode: staff,
        dueDate: DateTime(2026, 9, 12),
      );
      final theirs = task(
        code: 'TSA_SOMEONE_ELSE',
        seriesCode: series,
        assigneeCode: 'STF_OTHER',
        dueDate: DateTime(2026, 9, 12),
      );

      final resolved = stateWith([theirs, mine]).myAssignmentInSeries(series);

      expect(resolved?.code, assignment);
    });

    test('on a recurring series, picks the soonest-due of my occurrences', () {
      final later = task(
        code: 'TSA_LATER',
        seriesCode: series,
        assigneeCode: staff,
        dueDate: DateTime(2026, 10, 1),
      );
      final sooner = task(
        code: 'TSA_SOONER',
        seriesCode: series,
        assigneeCode: staff,
        dueDate: DateTime(2026, 9, 12),
      );

      final resolved = stateWith([later, sooner]).myAssignmentInSeries(series);

      expect(resolved?.code, 'TSA_SOONER');
    });

    test('ignores assignments belonging to a different series', () {
      final otherSeries = task(
        code: 'TSA_OTHER_SERIES',
        seriesCode: 'TSK_UNRELATED',
        assigneeCode: staff,
        dueDate: DateTime(2026, 9, 12),
      );

      expect(
        stateWith([otherSeries]).myAssignmentInSeries(series),
        isNull,
      );
    });

    test('fails closed while the identity is unresolved', () {
      // No staff/user code yet: opening "my card in this series" must not fall
      // through to whichever assignment happens to be first.
      final mine = task(
        code: assignment,
        seriesCode: series,
        assigneeCode: staff,
        dueDate: DateTime(2026, 9, 12),
      );

      expect(
        stateWith([mine], staffCode: '').myAssignmentInSeries(series),
        isNull,
      );
    });

    test('an empty series code resolves to nothing', () {
      final mine = task(
        code: assignment,
        seriesCode: series,
        assigneeCode: staff,
        dueDate: DateTime(2026, 9, 12),
      );

      expect(stateWith([mine]).myAssignmentInSeries(''), isNull);
    });
  });
}
