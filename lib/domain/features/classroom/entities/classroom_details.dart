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
  });

  final String code;
  final String name;
  final int capacity;
  final int studentsPerTeacher;

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

  String get studentTeacherRatioDisplay =>
      studentsPerTeacher > 0 ? '$studentsPerTeacher:1' : '—';

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
  ];
}
