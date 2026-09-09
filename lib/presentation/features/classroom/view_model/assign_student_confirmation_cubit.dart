import 'package:bloc/bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student_classroom/usecases/assign_students_to_classroom_usecase.dart';
import '../utils/classroom_age_range.dart';
import 'assign_student_confirmation_state.dart';

/// Drives the review/submit step of the "Assign students to classroom" flow,
/// including the target classroom's age-range warning.
class AssignStudentConfirmationCubit
    extends Cubit<AssignStudentConfirmationState> {
  AssignStudentConfirmationCubit({
    required AssignStudentsToClassroomUseCase assignStudentsToClassroomUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StorageService storageService,
  }) : _assignStudentsToClassroomUseCase = assignStudentsToClassroomUseCase,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _storageService = storageService,
       super(const AssignStudentConfirmationState());

  final AssignStudentsToClassroomUseCase _assignStudentsToClassroomUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StorageService _storageService;

  /// Sets the initial selection and resolves the target classroom's age
  /// bounds (self-contained — doesn't depend on a ClassroomCubit being in
  /// scope).
  Future<void> init({
    required Set<Student> initialSelection,
    required String classroomCode,
  }) async {
    emit(state.copyWith(selectedStudents: Set.of(initialSelection)));

    try {
      final schoolCode = (await _storageService.getString(
        StorageKeys.schoolCode,
      ))?.trim();
      if (schoolCode == null || schoolCode.isEmpty) return;
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
      );
      if (isClosed) return;
      for (final c in classrooms) {
        if (c.code.trim() == classroomCode.trim()) {
          emit(state.copyWith(targetClassroom: c));
          return;
        }
      }
    } catch (_) {
      // Bounds unknown -> the warning is skipped (never blocks the assign).
    }
  }

  void removeStudent(Student student) {
    final updated = Set<Student>.from(state.selectedStudents)..remove(student);
    emit(state.copyWith(selectedStudents: updated));
  }

  /// Names of currently-selected students whose age falls outside
  /// [AssignStudentConfirmationState.targetClassroom]'s range. Empty when
  /// the bounds are unknown or nobody is outside.
  List<String> outsideAgeRangeNames() {
    final classroom = state.targetClassroom;
    if (classroom == null) return const [];
    return studentsOutsideAgeRange(
      classroom: classroom,
      students: state.selectedStudents
          .map((s) => (name: s.fullName.trim(), dob: _parseDob(s.dob)))
          .toList(),
    );
  }

  /// Parses the raw DOB string; null when empty / unparseable (skip the
  /// check).
  DateTime? _parseDob(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }

  /// Returns a user-facing success message, or throws a user-facing error
  /// message string.
  Future<String> submit({required String classroomCode}) async {
    if (state.selectedStudents.isEmpty) {
      throw 'Please select at least one student';
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final schoolCode = await _storageService.getString(
        StorageKeys.schoolCode,
      );
      if (schoolCode == null || schoolCode.trim().isEmpty) {
        throw 'Missing schoolCode. Please sign in / select a school again.';
      }

      final studentCodes = state.selectedStudents
          .map((s) => s.code.trim())
          .where((code) => code.isNotEmpty)
          .toList();

      final message = await _assignStudentsToClassroomUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode.trim(),
        studentCodes: studentCodes,
      );
      return message.isEmpty ? 'Assigned successfully' : message;
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }
}
