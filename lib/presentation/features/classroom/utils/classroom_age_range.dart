import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';

/// Shared age-vs-classroom-range rules.
///
/// Deliberately identical to the web client so the two platforms never disagree
/// about who is "out of range":
///  * age is measured in COMPLETED months,
///  * bounds are INCLUSIVE (out of range only when `age < min` or `age > max`),
///  * a bound of 0 means unset and is not enforced,
///  * "today" is the SCHOOL's calendar day, not the device's.
///
/// This is a WARNING signal only. Nothing here should ever gate a save — an
/// out-of-range placement is a legitimate decision for staff to make (a child
/// held back with their peer group, a room change mid-birthday, and so on), so
/// the user is told and then allowed to proceed.

/// Completed months between [birthDate] and [reference] (school-today when
/// omitted). Mirrors the web helper, including the day-of-month adjustment.
int ageInCompletedMonths(DateTime birthDate, {DateTime? reference}) {
  final ref = reference ?? attendanceSchoolToday();
  var months = (ref.year - birthDate.year) * 12 + (ref.month - birthDate.month);
  // The birthday's day-of-month hasn't been reached yet this month.
  if (ref.day < birthDate.day) months -= 1;
  return months < 0 ? 0 : months;
}

/// Human-readable `1y 2m` for a month count; `0m` when zero.
String formatMonthsAsYearMonth(int totalMonths) {
  if (totalMonths <= 0) return '0m';
  final years = totalMonths ~/ 12;
  final months = totalMonths % 12;
  final parts = <String>[];
  if (years > 0) parts.add('${years}y');
  if (months > 0) parts.add('${months}m');
  return parts.join(' ');
}

/// The classroom's allowed range as `1y - 3y`, or '' when neither side is set.
String formatClassroomAgeRange(Classroom classroom) {
  final min = classroom.minAgeMonths;
  final max = classroom.maxAgeMonths;
  if (min <= 0 && max <= 0) return '';
  if (min > 0 && max > 0) {
    return '${formatMonthsAsYearMonth(min)} - ${formatMonthsAsYearMonth(max)}';
  }
  if (min > 0) return 'from ${formatMonthsAsYearMonth(min)}';
  return 'up to ${formatMonthsAsYearMonth(max)}';
}

/// Warning copy when [birthDate] falls outside [classroom]'s range, else null.
///
/// Returns null when there's nothing to check (no DOB, or the room has no
/// bounds), so callers can treat null as "no warning".
String? classroomAgeRangeWarning({
  required Classroom classroom,
  required DateTime? birthDate,
  String? studentName,
  DateTime? reference,
}) {
  if (birthDate == null) return null;
  if (classroom.minAgeMonths <= 0 && classroom.maxAgeMonths <= 0) return null;

  final months = ageInCompletedMonths(birthDate, reference: reference);
  if (!classroom.isAgeOutsideRange(months)) return null;

  final who = (studentName ?? '').trim().isEmpty
      ? 'This student'
      : studentName!.trim();
  final range = formatClassroomAgeRange(classroom);
  return '$who is ${formatMonthsAsYearMonth(months)} old, which is outside '
      "${classroom.name}'s age range ($range). You can still continue.";
}

/// Names of [students] (as `(name, dob)` pairs) that fall outside [classroom].
List<String> studentsOutsideAgeRange({
  required Classroom classroom,
  required List<({String name, DateTime? dob})> students,
  DateTime? reference,
}) {
  if (classroom.minAgeMonths <= 0 && classroom.maxAgeMonths <= 0) {
    return const <String>[];
  }
  final out = <String>[];
  for (final s in students) {
    final dob = s.dob;
    if (dob == null) continue; // unknown DOB — nothing to assert
    final months = ageInCompletedMonths(dob, reference: reference);
    if (classroom.isAgeOutsideRange(months)) out.add(s.name);
  }
  return out;
}
