import '../entities/student_physician.dart';
import '../repositories/student_repository.dart';

class AddPhysicianUseCase {
  AddPhysicianUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentPhysician> call({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) {
    return _repository.addPhysician(
      schoolCode: schoolCode,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      specialty: specialty,
      notes: notes,
    );
  }
}
