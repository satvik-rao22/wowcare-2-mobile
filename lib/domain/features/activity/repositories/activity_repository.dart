import '../entities/activity_feed_row.dart';
import '../entities/activity_setting.dart';
import '../entities/activity_type_details.dart';

abstract class ActivityRepository {
  /// Returns enabled activity settings for a classroom via
  /// `GET /api/v1/classrooms/{classroomCode}/activity-settings`.
  Future<List<ActivitySetting>> getClassroomActivitySettings({
    required String classroomCode,
    bool refresh,
  });

  /// Returns activity type details via `GET /api/v1/activity-types/{code}`.
  Future<ActivityTypeDetails> getActivityTypeDetails({
    required String code,
  });

  /// `GET /api/v1/activities/feed/daily`
  Future<ActivityFeedPage> getDailyActivityFeed({
    required String classroomCode,
    required String date,
    String? studentCode,
    String? activityTypeCode,
    int page = 0,
    int size = 100,
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

