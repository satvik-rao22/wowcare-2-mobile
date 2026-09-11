import '../repositories/classroom_repository.dart';

class FinalizeClassroomLogoUseCase {
  FinalizeClassroomLogoUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<void> call({
    required String classroomCode,
    required String assetCode,
  }) {
    return _repository.finalizeClassroomLogo(
      classroomCode: classroomCode,
      assetCode: assetCode,
    );
  }
}
