import '../repositories/student_repository.dart';

/// Use case to update a student's address.
class UpdateStudentAddressUseCase {
  UpdateStudentAddressUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required Map<String, dynamic> fields,
  }) {
    return _repository.updateStudentAddress(
      studentCode: studentCode,
      fields: fields,
    );
  }
}
