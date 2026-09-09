import '../entities/student_classroom_enrolled_count.dart';
import '../repositories/classroom_repository.dart';

class GetStudentClassroomEnrolledCountUseCase {
  GetStudentClassroomEnrolledCountUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<StudentClassroomEnrolledCount> call({
    required String classroomCode,
    String? organizationCode,
    String? schoolCode,
  }) {
    return _repository.getStudentClassroomEnrolledCount(
      classroomCode: classroomCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}
