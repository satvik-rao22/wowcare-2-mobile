import '../repositories/student_repository.dart';

/// Sets a guardian's clock PIN to an operator-supplied value.
class ChangeGuardianPinUseCase {
  ChangeGuardianPinUseCase(this._repository);

  final StudentRepository _repository;

  Future<({String message, String newClockPin})> call({
    required String guardianCode,
    required String pin,
    required String studentCode,
  }) {
    return _repository.changeGuardianPin(
      guardianCode: guardianCode,
      pin: pin,
      studentCode: studentCode,
    );
  }
}
