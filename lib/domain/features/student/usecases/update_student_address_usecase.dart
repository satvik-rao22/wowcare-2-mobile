import '../entities/update_student_address_request.dart';
import '../repositories/student_repository.dart';

/// Use case to update a student's address.
class UpdateStudentAddressUseCase {
  UpdateStudentAddressUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required UpdateStudentAddressRequest request,
  }) {
    return _repository.updateStudentAddress(
      studentCode: studentCode,
      request: request,
    );
  }
}
