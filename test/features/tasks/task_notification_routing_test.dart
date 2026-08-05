import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';

/// The Task push-notification contract, end to end on the client side: the six
/// `TASK_*` actions the backend fires must each resolve to a destination, and
/// the two that carry only the series code must still land on one specific
/// card via `TasksState.myAssignmentInSeries`.
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

  group('resolver — actions carrying the assignment code open that card', () {
    // TASK_STATUS_UPDATED / TASK_OVERDUE / TASK_DUE_SOON all send the real
    // assignmentCode, which names the card outright — it rides as the
    // `taskCode` query param, since that's the identity TaskDetailScreen
    // already matches a card by.
    for (final action in const [
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

  group('resolver — actions carrying only the series code', () {
    for (final action in const ['TASK_ASSIGNED', 'TASK_UPDATED']) {
      test('$action → detail with seriesCode and no taskCode', () {
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

  // The series-only actions (TASK_ASSIGNED / TASK_UPDATED) rely on the client
  // pairing the series with the signed-in user's identity to find the one card.
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
