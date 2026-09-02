import 'attendance_day.dart';
import 'attendance_session.dart';

/// The expanded detail for one day — the sessions and the breaks between them.
/// Loaded on demand (when a day row is expanded) from the detail endpoint.
class DayDetail {
  const DayDetail({required this.sessions, required this.breaks});

  final List<AttendanceSession> sessions;
  final List<AttendanceBreak> breaks;

  bool get isEmpty => sessions.isEmpty;
}
