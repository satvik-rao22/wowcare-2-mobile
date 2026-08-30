import '../entities/student_settings.dart';
import '../repositories/student_repository.dart';

/// Fetches a school's student settings (edit-permission toggles for the
/// guardian/staff personas, etc.).
class GetStudentSettingsUseCase {
  GetStudentSettingsUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentSettings> call({required String schoolCode}) {
    return _repository.getStudentSettings(schoolCode: schoolCode);
  }
}
