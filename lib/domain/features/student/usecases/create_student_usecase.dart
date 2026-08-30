import '../entities/student.dart';
import '../repositories/student_repository.dart';

/// Creates a student via the add-student wizard.
///
/// [classroom] must be the backend classroom **code**, not the display name.
class CreateStudentUseCase {
  CreateStudentUseCase(this._repository);

  final StudentRepository _repository;

  Future<Student> call({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  }) {
    return _repository.createStudent(
      schoolCode: schoolCode,
      firstName: firstName,
      lastName: lastName,
      status: status,
      classroom: classroom,
      profilePhotoUrl: profilePhotoUrl,
      dob: dob,
      schoolStartDate: schoolStartDate,
    );
  }
}
