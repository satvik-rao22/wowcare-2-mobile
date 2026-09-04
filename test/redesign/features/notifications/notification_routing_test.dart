import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_action.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/notification_routing.dart';

void main() {
  NotificationItem item({
    required NotificationModule module,
    required String action,
    String? targetCode,
  }) => NotificationItem(
    id: 'n',
    title: 'A notification',
    body: '',
    subjectName: 'Amara Okafor',
    module: module,
    action: action,
    targetCode: targetCode,
    createdAt: DateTime(2026, 8, 20, 9, 12),
  );

  NotificationDestination where(
    NotificationItem notification, {
    Persona persona = Persona.admin,
  }) => NotificationRouting.destinationOf(notification, persona: persona);

  group('12c: where a tap lands', () {
    test('a sign-in opens that student, not the attendance list', () {
      final destination = where(
        item(
          module: NotificationModule.studentAttendance,
          action: NotificationAction.studentSignInOut,
          targetCode: 'amara',
        ),
      );

      expect(destination, NotificationRoute(AppRoutes.student('amara')));
    });

    test('a sign-in with no code falls back to the attendance list', () {
      final destination = where(
        item(
          module: NotificationModule.studentAttendance,
          action: NotificationAction.studentSignInOut,
        ),
      );

      expect(destination, const NotificationRoute(AppRoutes.attendance));
    });

    test('a ratio breach opens the classroom it names', () {
      final destination = where(
        item(
          module: NotificationModule.attendance,
          action: NotificationAction.ratioBreached,
          targetCode: 'bluebell',
        ),
      );

      expect(destination, NotificationRoute(AppRoutes.classroom('bluebell')));
    });

    test('a staff document opens that staff record', () {
      final destination = where(
        item(
          module: NotificationModule.staff,
          action: NotificationAction.staffDocumentExpiry,
          targetCode: 'priya',
        ),
      );

      expect(destination, NotificationRoute(AppRoutes.staffMember('priya')));
    });

    test('a classroom edit opens that classroom', () {
      final destination = where(
        item(
          module: NotificationModule.classroom,
          action: NotificationAction.editClassroom,
          targetCode: 'sunflower',
        ),
      );

      expect(destination, NotificationRoute(AppRoutes.classroom('sunflower')));
    });

    test('an immunization due opens that student', () {
      final destination = where(
        item(
          module: NotificationModule.student,
          action: NotificationAction.studentImmunizationDueOverdue,
          targetCode: 'maya',
        ),
      );

      expect(destination, NotificationRoute(AppRoutes.student('maya')));
    });

    test('a settings change opens the preferences that decide the bell', () {
      final destination = where(
        item(
          module: NotificationModule.other,
          action: NotificationAction.schoolSettingsChanged,
        ),
      );

      expect(
        destination,
        const NotificationRoute(AppRoutes.notificationSettings),
      );
    });

    test('a backend alias resolves to the same place as its canonical', () {
      // The inbox sends `STUDENT_SIGN_IN`; the table is keyed by the combined
      // `STUDENT_SIGN_IN_OUT`.
      final destination = where(
        item(
          module: NotificationModule.studentAttendance,
          action: 'STUDENT_SIGN_IN',
          targetCode: 'amara',
        ),
      );

      expect(destination, NotificationRoute(AppRoutes.student('amara')));
    });

    test('an action nobody knows falls back to its module', () {
      final destination = where(
        item(
          module: NotificationModule.student,
          action: 'SOMETHING_NEW_ENTIRELY',
        ),
      );

      expect(destination, const NotificationRoute(AppRoutes.students));
    });

    test('a module with no home at all lands on the dashboard', () {
      final destination = where(
        item(module: NotificationModule.other, action: 'SOMETHING_NEW'),
      );

      expect(destination, const NotificationRoute(AppRoutes.dashboard));
    });
  });

  group('12c: a module that is not rebuilt yet', () {
    const notBuilt = <NotificationModule, String>{
      NotificationModule.billing: NotificationAction.invoiceGenerated,
      NotificationModule.scheduling: NotificationAction.publishShift,
      NotificationModule.availability: NotificationAction.movementOverdue,
      NotificationModule.activity: NotificationAction.incidentApprovalPending,
      NotificationModule.messaging: NotificationAction.messageToStudent,
      NotificationModule.newsletter: NotificationAction.newsletterSent,
    };

    for (final entry in notBuilt.entries) {
      test('${entry.key.label} says so rather than dead-ending', () {
        expect(
          where(item(module: entry.key, action: entry.value)),
          const NotificationNotBuilt(),
        );
      });
    }
  });

  group('12e: a guardian is routed to what is theirs', () {
    test('their child opens that child', () {
      final destination = where(
        item(
          module: NotificationModule.studentAttendance,
          action: NotificationAction.studentSignInOut,
          targetCode: 'amara',
        ),
        persona: Persona.guardian,
      );

      expect(destination, NotificationRoute(AppRoutes.student('amara')));
    });

    test('a roster they may not read is the dashboard instead', () {
      final destination = where(
        item(
          module: NotificationModule.student,
          action: NotificationAction.addStudent,
        ),
        persona: Persona.guardian,
      );

      expect(destination, const NotificationRoute(AppRoutes.dashboard));
    });

    test('a classroom is never theirs to open', () {
      final destination = where(
        item(
          module: NotificationModule.classroom,
          action: NotificationAction.editClassroom,
          targetCode: 'sunflower',
        ),
        persona: Persona.guardian,
      );

      expect(destination, const NotificationRoute(AppRoutes.dashboard));
    });
  });
}
