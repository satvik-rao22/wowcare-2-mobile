part of 'student_mark_absent_cubit.dart';

/// UI-only student entity used by the attendance mark-absent form. Equality is
/// by [studentCode] so list removal / selection works by identity of student.
class StudentEntity {
  final int id;
  final String studentCode;
  final String fullName;
  final int roomId;
  final String roomName;
  final String classroomCode;
  final String photoUuid;
  final List<TagEntity> tags;

  StudentEntity({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    required this.classroomCode,
    this.photoUuid = '',
    this.tags = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEntity &&
          runtimeType == other.runtimeType &&
          studentCode == other.studentCode;

  @override
  int get hashCode => studentCode.hashCode;
}

/// UI-only tag entity used by the attendance mark-absent form.
class TagEntity {
  final String name;

  TagEntity({required this.name});
}

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
