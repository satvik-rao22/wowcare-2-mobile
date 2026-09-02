import 'package:wowcare/core/util/billing_school_time.dart';

/// Lightweight view models for the billing "Select Students" flow.
///
/// Populated from the real student-overview API (see [SelectStudentsCubit]).
class Tag {
  final int id;
  final String name;

  const Tag({required this.id, required this.name});
}

class Student {
  const Student({
    required this.code,
    required this.fullName,
    this.photoUuid,
    this.photoAssetCode,
    this.roomName,
    this.classroomCode,
    this.dob,
    this.ageLabel = '',
    this.tags = const <Tag>[],
  });

  /// Stable backend student code — used for selection and the invoice payload.
  final String code;
  final String fullName;
  final String? photoUuid;
  final String? photoAssetCode;
  final String? roomName;
  final String? classroomCode;
  final String? dob;

  /// Pre-computed human age (e.g. "2 yrs 3 mos", "5 mos", "3 wks").
  final String ageLabel;
  final List<Tag> tags;

  /// Human age from an ISO `dob` ('yyyy-MM-dd'): years + months for children
  /// ≥ 1yr, months for < 1yr, weeks/days for infants. '' for empty/future dob.
  /// Mirrors the calculation used on the student profile About tab.
  static String ageLabelFromDob(String? dob) {
    if (dob == null || dob.trim().isEmpty) return '';
    final DateTime parsed;
    try {
      parsed = DateTime.parse(dob.trim());
    } catch (_) {
      return '';
    }
    // Age against the SCHOOL calendar day, not the device's.

    final now = billingSchoolToday();
    if (parsed.isAfter(now)) return '';

    int years = now.year - parsed.year;
    int months = now.month - parsed.month;
    if (now.day < parsed.day) months -= 1;
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    String plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';

    if (years >= 1) {
      return months > 0
          ? '${plural(years, 'yr')} ${plural(months, 'mo')}'
          : plural(years, 'yr');
    }
    if (months >= 1) return plural(months, 'mo');

    final days = now.difference(parsed).inDays;
    if (days >= 7) return plural(days ~/ 7, 'wk');
    return plural(days, 'day');
  }
}
