import '../entities/classroom_logo_upload_session.dart';
import '../repositories/classroom_repository.dart';

class CreateClassroomLogoUploadSessionUseCase {
  CreateClassroomLogoUploadSessionUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<ClassroomLogoUploadSession> call({
    required String classroomCode,
    required String organizationCode,
    required String schoolCode,
  }) {
    return _repository.createClassroomLogoUploadSession(
      classroomCode: classroomCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}
