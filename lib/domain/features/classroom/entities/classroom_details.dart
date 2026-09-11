import 'package:equatable/equatable.dart';

class ClassroomDetails extends Equatable {
  const ClassroomDetails({
    required this.code,
    required this.name,
    required this.capacity,
    required this.studentsPerTeacher,
    required this.minAgeTotalMonths,
    required this.maxAgeTotalMonths,
    required this.type,
    required this.school,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    this.logoAssetCode = '',
  });

  final String code;
  final String name;
  final int capacity;
  /// Students per teacher (may be fractional, e.g. 4.5).
  final double studentsPerTeacher;
  /// Lower bound from API `minAge` (whole months).
  final int minAgeTotalMonths;
  /// Upper bound from API `maxAge` (whole months).
  final int maxAgeTotalMonths;
  final String type;
  final String school;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final String updatedBy;
  final DateTime? updatedAt;
  /// Asset code for the classroom logo image.
  final String logoAssetCode;

  /// One side of the range, e.g. `1y 2m`; omits `0y` / `0m`; empty if [totalMonths] <= 0.
  static String formatMonthsAsYearMonthParts(int totalMonths) {
    if (totalMonths <= 0) return '';
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    final parts = <String>[];
    if (years > 0) parts.add('${years}y');
    if (months > 0) parts.add('${months}m');
    return parts.join(' ');
  }

  /// Card copy: `1y 2m - 5y 6m`, omitting zero components per side; [No Age Limit] when nothing to show.
  String get ageRangeCompactDisplay {
    final minPart = formatMonthsAsYearMonthParts(minAgeTotalMonths);
    final maxPart = formatMonthsAsYearMonthParts(maxAgeTotalMonths);
    if (minPart.isEmpty && maxPart.isEmpty) return 'No Age Limit';
    if (minPart.isEmpty) return maxPart;
    if (maxPart.isEmpty) return minPart;
    return '$minPart - $maxPart';
  }

  /// Alias for callers that used the older label name.
  String get ageRangeLabel => ageRangeCompactDisplay;

  /// Whole ratios as `N:1`; decimals as nearest reduced fraction (e.g. 4.5 → `9:2`).
  String get studentTeacherRatioDisplay =>
      formatStudentTeacherRatioDisplay(studentsPerTeacher);

  static int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final t = y;
      y = x % y;
      x = t;
    }
    return x == 0 ? 1 : x;
  }

  /// Converts [studentsPerTeacher] to a `students:teachers` label.
  static String formatStudentTeacherRatioDisplay(double studentsPerTeacher) {
    if (studentsPerTeacher <= 0) return '—';

    final rounded = studentsPerTeacher.roundToDouble();
    if ((studentsPerTeacher - rounded).abs() < 1e-9) {
      return '${rounded.toInt()}:1';
    }

    const maxDenominator = 64;
    var bestNumerator = 1;
    var bestDenominator = 1;
    var bestError = double.infinity;

    for (var denominator = 1; denominator <= maxDenominator; denominator++) {
      final numerator = (studentsPerTeacher * denominator).round();
      if (numerator <= 0) continue;
      final error = (studentsPerTeacher - numerator / denominator).abs();
      if (error < bestError) {
        bestError = error;
        bestNumerator = numerator;
        bestDenominator = denominator;
      }
    }

    final divisor = _gcd(bestNumerator, bestDenominator);
    return '${bestNumerator ~/ divisor}:${bestDenominator ~/ divisor}';
  }

  @override
  List<Object?> get props => [
        code,
        name,
        capacity,
        studentsPerTeacher,
        minAgeTotalMonths,
        maxAgeTotalMonths,
        type,
        school,
        status,
        createdBy,
        createdAt,
        updatedBy,
        updatedAt,
        logoAssetCode,
      ];
}
