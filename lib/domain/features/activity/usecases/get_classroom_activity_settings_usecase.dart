import '../entities/activity_setting.dart';
import '../repositories/activity_repository.dart';

class GetClassroomActivitySettingsUseCase {
  GetClassroomActivitySettingsUseCase(this._repository);

  final ActivityRepository _repository;

  Future<List<ActivitySetting>> call({
    required String classroomCode,
    bool refresh = false,
  }) {
    return _repository.getClassroomActivitySettings(
      classroomCode: classroomCode,
      refresh: refresh,
    );
  }
}
