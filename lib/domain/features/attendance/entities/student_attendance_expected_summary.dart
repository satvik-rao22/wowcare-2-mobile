import 'package:equatable/equatable.dart';

class StudentAttendanceExpectedSummary extends Equatable {
  const StudentAttendanceExpectedSummary({
    required this.expected,
    required this.present,
    required this.absent,
    required this.signOut,
    required this.notMarked,
  });

  final int expected;
  final int present;
  final int absent;
  final int signOut;
  final int notMarked;

  @override
  List<Object?> get props => [expected, present, absent, signOut, notMarked];
}
