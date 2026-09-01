import '../entities/activity_asset_presign.dart';
import '../entities/activity_attachment.dart';
import '../entities/activity_detail.dart';
import '../entities/activity_feed_row.dart';
import '../entities/activity_parameter_value.dart';
import '../entities/activity_setting.dart';
import '../entities/activity_type_details.dart';
import '../entities/activity_type_summary.dart';
import '../entities/activity_upload_session.dart';
import '../../attendance/entities/student_attendance_custom.dart';

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

  /// Returns all active activity types for a school via
  /// `GET /api/v1/activity-types?schoolCode={schoolCode}`.
  Future<List<ActivityTypeSummary>> getActiveActivityTypesForSchool({
    required String schoolCode,
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
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  });

  /// `GET /api/v1/activities/feed/range`
  Future<ActivityFeedPage> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  });

  /// `GET /api/v2/activities/{cardGroupCode}`
  Future<ActivityDetail> getActivity({
    required String code,
  });

  /// `PATCH /api/v2/activities/{cardGroupCode}`
  Future<String> updateActivity({
    required String code,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    List<ActivityParameterValue> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  });

  /// `DELETE /api/v2/activities/{cardGroupCode}`.
  Future<String> deleteActivity({required String code});

  /// `POST /api/v2/admin/activities/{cardGroupCode}/approve`.
  Future<String> approveActivity({required String code});

  /// `POST /api/v2/admin/activities/{cardGroupCode}/reject`.
  Future<String> rejectActivity({required String code});

  /// `POST /api/v2/guardian/activities/{cardGroupCode}/acknowledge`.
  Future<String> acknowledgeActivity({required String code});

  /// `PATCH /api/v2/guardian/activities/{cardGroupCode}/parent-signature`.
  Future<String> guardianParentSignature({
    required String code,
    required String parameterCode,
    required String guardianCode,
    String? signatureValue,
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
    bool? napStart,
    bool? napEnd,
    bool? napReminderEnabled,
    String? napReminderUserCode,
    String? napReminderRole,
    bool? requireAdminApproval,
    List<ActivityParameterValue> parameterValues,
    List<ActivityAttachment> attachments,
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
    bool? requireAdminApproval,
    required List<ActivityAttachment> attachments,
    List<ActivityParameterValue> parameterValues,
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
    required String checksumSha256,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  });

  /// Returns count of pending incident approvals via
  /// `GET /api/v2/activities/admin/activities/pending-incident-count`.
  Future<int> getPendingIncidentCount();

  /// Returns the mark-activity student list for a date/filter selection.
  Future<List<StudentAttendanceCustomItem>> getMarkActivityStudentList({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    int page = 0,
    int size = 200,
    required String selectedClassroomCode,
  });
}

