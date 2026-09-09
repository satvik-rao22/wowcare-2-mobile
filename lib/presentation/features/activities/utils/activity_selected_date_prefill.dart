import 'package:intl/intl.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';

/// Today's calendar date in the school zone as `yyyy-MM-dd`.
/// Matches [ActivityStudentSelection] when the user taps Next with the date chip
/// set to "today" in that zone.
String attendanceDateYyyyMmDdSchoolToday() {
  final tz = SchoolTimezoneResolver.lastKnownTimeZone;
  final d = SchoolZoneDateTime.schoolCalendarTodayOnly(tz);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? resolveSelectedAttendanceDate(List<Map<String, dynamic>> students) {
  for (final student in students) {
    final raw = (student['attendanceDate'] ?? '').toString().trim();
    if (raw.isEmpty) continue;
    try {
      final dt = DateTime.parse(raw);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      try {
        final parsed = DateFormat('yyyy-MM-dd').parseStrict(raw);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (e) {
        AppLogger.d('resolveSelectedAttendanceDate: unparsable date "$raw": $e');
      }
    }
  }
  return null;
}

String? formatSelectedDateForDateWidget(DateTime? date) {
  if (date == null) return null;
  return DateFormat('MMM dd, yyyy').format(date);
}
