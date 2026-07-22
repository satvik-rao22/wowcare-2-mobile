import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';

/// Shared age-vs-classroom-range rules.
///
/// The `GET /classroom/classroom/all` bounds are whole YEARS (`minAge: 2` =
/// 2 years). Rules:
///  * age is measured in COMPLETED years,
///  * bounds are INCLUSIVE (out of range only when `age < min` or `age > max`),
///  * a bound of 0 means unset and is not enforced,
///  * "today" is the SCHOOL's calendar day, not the device's.
///
/// This is a WARNING signal only. Nothing here should ever gate a save — an
/// out-of-range placement is a legitimate decision for staff to make (a child
/// held back with their peer group, a room change mid-birthday, and so on), so
/// the user is told and then allowed to proceed.

/// Completed years between [birthDate] and [reference] (school-today when
/// omitted). Subtracts one when this year's birthday hasn't occurred yet.
int ageInCompletedYears(DateTime birthDate, {DateTime? reference}) {
  final ref = reference ?? attendanceSchoolToday();
  var years = ref.year - birthDate.year;
  final hadBirthdayThisYear = ref.month > birthDate.month ||
      (ref.month == birthDate.month && ref.day >= birthDate.day);
  if (!hadBirthdayThisYear) years -= 1;
  return years < 0 ? 0 : years;
}

/// Human-readable `2y` for a year count.
String _formatYears(int years) => '${years}y';

/// The classroom's allowed range as `2y - 4y`, or '' when neither side is set.
String formatClassroomAgeRange(Classroom classroom) {
  final min = classroom.minAgeYears;
  final max = classroom.maxAgeYears;
  if (min <= 0 && max <= 0) return '';
  if (min > 0 && max > 0) return '${_formatYears(min)} - ${_formatYears(max)}';
  if (min > 0) return 'from ${_formatYears(min)}';
  return 'up to ${_formatYears(max)}';
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
  if (classroom.minAgeYears <= 0 && classroom.maxAgeYears <= 0) return null;

  final years = ageInCompletedYears(birthDate, reference: reference);
  if (!classroom.isAgeOutsideRange(years)) return null;

  final who = (studentName ?? '').trim().isEmpty
      ? 'This student'
      : studentName!.trim();
  final range = formatClassroomAgeRange(classroom);
  return '$who is ${_formatYears(years)} old, which is outside '
      "${classroom.name}'s age range ($range). You can still continue.";
}

/// Names of [students] (as `(name, dob)` pairs) that fall outside [classroom].
List<String> studentsOutsideAgeRange({
  required Classroom classroom,
  required List<({String name, DateTime? dob})> students,
  DateTime? reference,
}) {
  if (classroom.minAgeYears <= 0 && classroom.maxAgeYears <= 0) {
    return const <String>[];
  }
  final out = <String>[];
  for (final s in students) {
    final dob = s.dob;
    if (dob == null) continue; // unknown DOB — nothing to assert
    final years = ageInCompletedYears(dob, reference: reference);
    if (classroom.isAgeOutsideRange(years)) out.add(s.name);
  }
  return out;
}
