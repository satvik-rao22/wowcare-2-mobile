import '../repositories/activity_repository.dart';

class GetNapStartStudentsUseCase {
  GetNapStartStudentsUseCase(this._repository);

  final ActivityRepository _repository;

  Future<List<String>> call({required String classroomCode}) {
    return _repository.getNapStartStudents(classroomCode: classroomCode);
  }
}
