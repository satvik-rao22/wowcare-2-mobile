import '../entities/activity_setting.dart';

abstract class ActivityRepository {
  /// Returns enabled activity settings for a classroom via
  /// `GET /api/v1/classrooms/{classroomCode}/activity-settings`.
  Future<List<ActivitySetting>> getClassroomActivitySettings({
    required String classroomCode,
  });
}


