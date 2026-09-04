import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/models/notification_module.dart';

/// The filter row on 12a: one chip per module group, with All first.
///
/// A chip is a group rather than a single module, because Attendance covers
/// the three the backend sends separately (`ATTENDANCE`,
/// `STUDENT_ATTENDANCE`, `STAFF_ATTENDANCE`). Selecting one is a server-side
/// filter in the shipped app, so picking a chip refetches from page one.
///
/// 12e: which chips are offered follows the persona, because a module a
/// persona cannot open never produces a notification they could tap.
enum NotificationFilter {
  all('All', <NotificationModule>{}),
  attendance('Attendance', <NotificationModule>{
    NotificationModule.attendance,
    NotificationModule.studentAttendance,
    NotificationModule.staffAttendance,
  }),
  classroom('Classroom', <NotificationModule>{NotificationModule.classroom}),
  student('Student', <NotificationModule>{NotificationModule.student}),
  staff('Staff', <NotificationModule>{NotificationModule.staff}),
  billing('Billing', <NotificationModule>{NotificationModule.billing}),
  scheduling('Scheduling', <NotificationModule>{NotificationModule.scheduling}),
  availability('Availability', <NotificationModule>{
    NotificationModule.availability,
  }),
  activity('Activity', <NotificationModule>{NotificationModule.activity}),
  messaging('Messaging', <NotificationModule>{NotificationModule.messaging}),
  newsletter('Newsletter', <NotificationModule>{NotificationModule.newsletter});

  const NotificationFilter(this.label, this.modules);

  final String label;

  /// The modules this chip keeps. Empty on [all], which keeps everything.
  final Set<NotificationModule> modules;

  bool get isAll => this == NotificationFilter.all;

  bool matches(NotificationModule module) => isAll || modules.contains(module);

  /// The chips 12e draws for each persona.
  ///
  /// A guardian is never shown Classroom, Staff, Scheduling or Availability:
  /// ratio, shifts and staff records are not theirs to see. A staff member is
  /// never shown Billing.
  static List<NotificationFilter> forPersona(Persona persona) =>
      switch (persona) {
        Persona.admin => NotificationFilter.values,
        Persona.staff => <NotificationFilter>[
          for (final filter in NotificationFilter.values)
            if (filter != NotificationFilter.billing) filter,
        ],
        Persona.guardian => const <NotificationFilter>[
          NotificationFilter.all,
          NotificationFilter.attendance,
          NotificationFilter.student,
          NotificationFilter.billing,
          NotificationFilter.activity,
          NotificationFilter.messaging,
          NotificationFilter.newsletter,
        ],
      };
}
