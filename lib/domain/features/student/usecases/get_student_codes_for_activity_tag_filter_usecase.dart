import '../repositories/student_repository.dart';

/// Resolves student codes for activity feed tag filtering via
/// `POST /api/v1/student-tags/activity-filter`.
class GetStudentCodesForActivityTagFilterUseCase {
  GetStudentCodesForActivityTagFilterUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<String>> call({
    required String schoolCode,
    required String classroomCode,
    required List<String> tagCodes,
  }) {
    return _repository.getStudentCodesForActivityTagFilter(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      tagCodes: tagCodes,
    );
  }
}
