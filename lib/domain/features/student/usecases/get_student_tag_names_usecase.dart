import '../repositories/student_repository.dart';

/// Use case to load a specific student's tag display names.
class GetStudentTagNamesUseCase {
  GetStudentTagNamesUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<String>> call({required String studentCode}) {
    return _repository.getStudentTagNames(studentCode: studentCode);
  }
}
