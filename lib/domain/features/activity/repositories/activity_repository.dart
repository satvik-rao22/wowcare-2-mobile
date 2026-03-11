import '../entities/activity_setting.dart';

abstract class ActivityRepository {
  /// Returns enabled activity settings for a classroom via
  /// `GET /api/v1/classrooms/{classroomCode}/activity-settings`.
  Future<List<ActivitySetting>> getClassroomActivitySettings({
    required String classroomCode,
  });

  /// Creates a new activity via `POST /api/v1/activities`.
  Future<String> createActivity({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    List<Map<String, dynamic>> parameterValues,
    List<Map<String, dynamic>> attachments,
  });
}

