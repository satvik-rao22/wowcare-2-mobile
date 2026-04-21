import '../entities/activity_asset_presign.dart';
import '../entities/activity_detail.dart';
import '../entities/activity_feed_row.dart';
import '../entities/activity_setting.dart';
import '../entities/activity_type_details.dart';
import '../entities/activity_upload_session.dart';

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

  /// Returns currently napping student codes for a classroom via
  /// `GET /api/v1/activities/{classroomCode}/nap-start-students`.
  Future<List<String>> getNapStartStudents({
    required String classroomCode,
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

  /// `GET /api/v1/activities/feed/range`
  Future<ActivityFeedPage> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  });

  /// `GET /api/v1/activities/code/{code}`
  Future<ActivityDetail> getActivity({required String code});

  /// `PATCH /api/v2/activities/{cardGroupCode}`
  Future<String> updateActivity({
    required String code,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    List<Map<String, dynamic>> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  });

  /// `DELETE /api/v2/activities/{cardGroupCode}`.
  Future<String> deleteActivity({required String code});

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
    bool? napStart,
    bool? napEnd,
    List<Map<String, dynamic>> parameterValues,
    List<Map<String, dynamic>> attachments,
  });

  /// Creates shared activity cards via `POST /api/v2/shared-activities`.
  ///
  /// Returns `data` list (each entry contains at least `cardCode`).
  Future<List<Map<String, dynamic>>> createSharedActivities({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    required List<Map<String, dynamic>> attachments,
  });

  /// Creates upload sessions via `POST /api/v2/activities/upload-sessions`.
  Future<ActivityUploadSession> createActivityUploadSessions({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
  });

  /// Creates a presigned asset slot for an upload session.
  Future<ActivityAssetPresign> createActivityAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  });
}

