part of 'student_mark_absent_cubit.dart';

/// Immutable form state for [StudentMarkAbsentFormCubit].
class StudentMarkAbsentState extends Equatable {
  const StudentMarkAbsentState({
    required this.students,
    required this.startDate,
    required this.endDate,
    this.schoolIana,
    this.isStaffAdminPersona,
    this.isSubmitting = false,
  });

  factory StudentMarkAbsentState.initial() {
    final now = ServerTimeService.instance.now();
    final today = DateTime(now.year, now.month, now.day);
    return StudentMarkAbsentState(
      students: const <StudentEntity>[],
      startDate: today,
      endDate: today,
    );
  }

  /// Working list of students to mark absent (students can be removed).
  final List<StudentEntity> students;

  /// Absence start date, clamped to the school calendar's "today".
  final DateTime startDate;

  /// Absence end date, never before [startDate] and not after today.
  final DateTime endDate;

  /// Resolved school IANA timezone, or null if it could not be resolved.
  final String? schoolIana;

  /// Whether the signed-in user is an admin persona (gates date editing).
  /// Null until the persona flags finish loading.
  final bool? isStaffAdminPersona;

  /// Whether a submission is currently in flight.
  final bool isSubmitting;

  StudentMarkAbsentState copyWith({
    List<StudentEntity>? students,
    DateTime? startDate,
    DateTime? endDate,
    String? schoolIana,
    bool? isStaffAdminPersona,
    bool? isSubmitting,
  }) {
    return StudentMarkAbsentState(
      students: students ?? this.students,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      schoolIana: schoolIana ?? this.schoolIana,
      isStaffAdminPersona: isStaffAdminPersona ?? this.isStaffAdminPersona,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    students,
    startDate,
    endDate,
    schoolIana,
    isStaffAdminPersona,
    isSubmitting,
  ];
}
