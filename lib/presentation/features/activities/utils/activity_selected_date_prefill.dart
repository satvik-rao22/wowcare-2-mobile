import 'package:intl/intl.dart';

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
      } catch (_) {}
    }
  }
  return null;
}

String? formatSelectedDateForDateWidget(DateTime? date) {
  if (date == null) return null;
  return DateFormat('MMM dd, yyyy').format(date);
}
