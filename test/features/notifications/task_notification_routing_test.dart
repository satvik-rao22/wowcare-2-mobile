import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';

/// Verifies the Task push-payload contract's six `TASK_*` actions land on the
/// right screen, for both channels (push `data` map and in-app item `data`).
void main() {
  PushNotification push(String action, {Map<String, String>? data}) {
    final payload = <String, String>{
      'action': action,
      'type': 'TASK',
      'taskCode': 'TSK_A1B2C3D4',
      'taskTitle': 'Restock the first-aid kit',
      'organizationCode': 'ORG_67F60097-C',
      'schoolCode': 'SCH_74709D20-7',
      ...?data,
    };
    return PushNotification(
      title: null,
      body: null,
      action: action,
      type: 'TASK',
      data: payload,
    );
  }

  group('task notifications → task detail', () {
    // TASK_STATUS_UPDATED / TASK_OVERDUE / TASK_DUE_SOON carry the real
    // assignmentCode in the actual contract — it rides as the `taskCode`
    // query param (the identity TaskDetailScreen matches a card by), while
    // the series still travels as `seriesCode` for the Schedule section.
    const assignmentScopedActions = <String>[
      'TASK_STATUS_UPDATED',
      'TASK_OVERDUE',
      'TASK_DUE_SOON',
    ];

    for (final action in assignmentScopedActions) {
      test('$action opens the task detail screen by its assignmentCode', () {
        final destination = NotificationRouteResolver.resolve(
          push(action, data: {'assignmentCode': 'TSA_1E7A4D9F3C'}),
        );

        expect(destination, isNotNull);
        expect(destination!.path, '/dashboard/tasks/detail');
        expect(destination.queryParameters['taskCode'], 'TSA_1E7A4D9F3C');
        expect(destination.queryParameters['seriesCode'], 'TSK_A1B2C3D4');
      });
    }

    // TASK_ASSIGNED / TASK_UPDATED send only the series taskCode — the screen
    // pairs it with the signed-in user's identity (myAssignmentInSeries) to
    // find their own card, so no `taskCode` param can be produced here.
    for (final action in const ['TASK_ASSIGNED', 'TASK_UPDATED']) {
      test('$action opens the task detail screen by its series, no assignment yet',
          () {
        final destination = NotificationRouteResolver.resolve(push(action));

        expect(destination, isNotNull);
        expect(destination!.path, '/dashboard/tasks/detail');
        expect(destination.queryParameters['seriesCode'], 'TSK_A1B2C3D4');
        expect(destination.queryParameters.containsKey('taskCode'), isFalse);
      });
    }

    test('snake_case task_code is accepted too', () {
      final destination = NotificationRouteResolver.resolve(
        PushNotification(
          title: null,
          body: null,
          action: 'TASK_ASSIGNED',
          type: 'TASK',
          data: const {
            'action': 'TASK_ASSIGNED',
            'task_code': 'TSK_SNAKE',
          },
        ),
      );

      expect(destination!.queryParameters['seriesCode'], 'TSK_SNAKE');
    });

    test('a missing taskCode falls back to the inbox, not an empty screen', () {
      final destination = NotificationRouteResolver.resolve(
        PushNotification(
          title: null,
          body: null,
          action: 'TASK_ASSIGNED',
          type: 'TASK',
          data: const {'action': 'TASK_ASSIGNED'},
        ),
      );

      expect(destination!.path, '/notifications');
    });
  });

  group('TASK_DELETED → task list', () {
    test('opens the task list, since the task is gone', () {
      final destination = NotificationRouteResolver.resolve(
        push('TASK_DELETED'),
      );

      expect(destination!.path, '/dashboard/tasks');
      expect(destination.queryParameters, isEmpty);
    });
  });

  group('legacy action names still route', () {
    test('ASSIGN_TASK is treated as TASK_ASSIGNED', () {
      final destination = NotificationRouteResolver.resolve(
        push('ASSIGN_TASK'),
      );

      expect(destination!.path, '/dashboard/tasks/detail');
      expect(destination.queryParameters['seriesCode'], 'TSK_A1B2C3D4');
    });

    test('TASK_DUE is treated as TASK_DUE_SOON', () {
      final destination = NotificationRouteResolver.resolve(push('TASK_DUE'));

      expect(destination!.path, '/dashboard/tasks/detail');
    });

    test('lower-case / padded actions are normalised', () {
      final destination = NotificationRouteResolver.resolve(
        push(' task_assigned '),
      );

      expect(destination!.path, '/dashboard/tasks/detail');
    });
  });

  group('in-app items resolve through the same table as push', () {
    test('resolveData routes a bell item exactly like its push twin', () {
      const data = <String, String>{
        'action': 'TASK_ASSIGNED',
        'type': 'TASK',
        'taskCode': 'TSK_A1B2C3D4',
      };

      final inApp = NotificationRouteResolver.resolveData(data);
      final viaPush = NotificationRouteResolver.resolve(push('TASK_ASSIGNED'));

      expect(inApp!.location, viaPush!.location);
    });

    test('an item with no action resolves to nothing (tap just marks read)', () {
      expect(NotificationRouteResolver.resolveData(const {}), isNull);
      expect(
        NotificationRouteResolver.resolveData(const {'action': '  '}),
        isNull,
      );
    });

    test('an unknown action resolves to nothing', () {
      expect(
        NotificationRouteResolver.resolveData(
          const {'action': 'TASK_TELEPORTED'},
        ),
        isNull,
      );
    });
  });
}
