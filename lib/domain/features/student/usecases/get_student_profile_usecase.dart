import '../entities/student_profile.dart';
import '../repositories/student_repository.dart';

class GetStudentProfileUseCase {
  GetStudentProfileUseCase(this.repository);

  final StudentRepository repository;

  Future<StudentProfile> call({required String code}) {
    return repository.getStudentProfile(code: code);
  }
}
