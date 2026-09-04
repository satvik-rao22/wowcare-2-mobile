/// What a notification is about, and therefore what colour it carries.
///
/// Colour here says what the data is about, never who is looking: teal for a
/// student, sun for staff, green for money, pink for something somebody wrote.
/// It is the design's own module map (`n12ModStyle`), and it is the same map
/// the shipped `notification_category_style.dart` draws from.
enum NotificationTone {
  /// Students: attendance, the roster, activities, movements.
  student,

  /// Staff: their attendance, their shifts.
  staff,

  /// Money.
  money,

  /// Something a person wrote: a message, a newsletter.
  message,

  /// Everything else, including a module this build does not know.
  neutral,
}

/// The backend's `module` value on an inbox item, as the design's filter row
/// names it.
///
/// [apiValue] is the string the notification service sends and the inbox's
/// `module` query parameter takes, so Phase 5 binds this without a lookup
/// table of its own.
enum NotificationModule {
  attendance('ATTENDANCE', 'Attendance', NotificationTone.student),
  studentAttendance(
    'STUDENT_ATTENDANCE',
    'Student Attendance',
    NotificationTone.student,
  ),
  staffAttendance(
    'STAFF_ATTENDANCE',
    'Staff Attendance',
    NotificationTone.staff,
  ),
  classroom('CLASSROOM', 'Classroom', NotificationTone.neutral),
  student('STUDENT', 'Student', NotificationTone.student),
  staff('STAFF', 'Staff', NotificationTone.staff),
  billing('BILLING', 'Billing', NotificationTone.money),
  scheduling('SCHEDULING', 'Scheduling', NotificationTone.staff),
  availability('AVAILABILITY', 'Availability', NotificationTone.student),
  activity('ACTIVITY', 'Activity', NotificationTone.student),
  messaging('MESSAGING', 'Messaging', NotificationTone.message),
  newsletter('NEWSLETTER', 'Newsletter', NotificationTone.message),

  /// A module this build has no chip for. The item still arrives, still reads
  /// and still lands somewhere; it is only never filtered to.
  other('', 'Update', NotificationTone.neutral);

  const NotificationModule(this.apiValue, this.label, this.tone);

  /// The backend string. Empty for [other], which is not a real module.
  final String apiValue;

  /// The tag on a row, and the chip in the filter row.
  final String label;

  final NotificationTone tone;

  /// Maps a backend value onto a module, falling back to [other] so an item
  /// the app does not recognize is still shown rather than dropped.
  static NotificationModule fromApi(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final module in NotificationModule.values) {
      if (module != other && module.apiValue == normalized) return module;
    }
    return other;
  }
}
