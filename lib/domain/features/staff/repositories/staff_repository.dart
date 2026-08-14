import '../entities/staff_member.dart';
import '../entities/staff_document.dart';
import '../entities/staff_documents_page.dart';
import '../entities/staff_profile.dart';
import '../entities/create_school_user_result.dart';
import '../entities/staff_count.dart';
import '../entities/school_regular_schedule_day.dart';

abstract class StaffRepository {
  Future<StaffCount> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  });

  Future<StaffPage> getStaffPage({
    required String organizationCode,
    required String schoolCode,
    String? code,
    int page,
    int size,
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  });

  /// Fetches the full staff list (single-page; [size] caps how many records
  /// are returned, default 200) with support for multiple `status` values
  /// sent as repeated query keys (e.g. `status=ACTIVE&status=UPCOMING`).
  /// Intended for the scheduling feature, which needs every active/upcoming
  /// staff member at once.
  Future<List<StaffMember>> getAllStaff({
    required String organizationCode,
    required String schoolCode,
    List<String>? statuses,
    int size = 200,
  });

  Future<String> addStaffDocument({
    required String staffCode,
    required StaffDocument document,
  });

  Future<String> updateStaffDocument({
    required String documentUuid,
    required StaffDocument document,
    required String staffCode, // Required for cache invalidation
  });

  Future<String> deleteStaffDocument({
    required String documentUuid,
    required String staffCode, // Required for cache invalidation
  });

  Future<StaffDocumentsPage> getStaffDocuments({
    required String staffCode,
    int page,
    int size,
    bool? expired,
  });

  /// Fetches profile. When [forEditStaff] is false uses my-profile endpoint (logged-in
  /// user); when true uses `staff/{staffCode}/profile` (edit staff details).
  ///
  /// [forceRefresh] bypasses the cached copy and re-fetches from the server —
  /// use when the caller needs to observe a server-side change (e.g. an
  /// admin just reassigned this staff member's classroom) rather than
  /// whatever was cached up to [StorageKeys.cacheValidDuration] ago.
  Future<StaffProfile> getStaffProfile({
    required String staffCode,
    bool forEditStaff = false,
    bool forceRefresh = false,
  });

  /// Resolves staffCode for a given userCode + organizationCode + schoolCode
  /// using the `/api/v1/staff/code` endpoint.
  Future<String?> getStaffCodeForUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  });

  /// Updates staff profile core details (name, status, phone, designation, jobTag, classrooms, etc.).
  ///
  /// [fields] should follow the backend PATCH contract for `/api/v1/staff/staff/my-profile/{staffCode}`.
  Future<String> updateStaffProfile({
    required String staffCode,
    required Map<String, dynamic> fields,
  });

  /// Updates staff address via `/api/v1/staff-address/{staffCode}`.
  ///
  /// [fields] should include addressStreet, addressLine2, addressCity,
  /// addressState, addressZipCode, addressCountry.
  Future<String> updateStaffAddress({
    required String staffCode,
    required Map<String, dynamic> fields,
  });

  /// Updates a staff member's allowed classrooms via
  /// `PATCH /api/v1/staff-classrooms/{staffCode}/allowed-classrooms`.
  Future<String> updateStaffAllowedClassrooms({
    required String staffCode,
    required List<String> classroomCodes,
  });

  /// Updates a staff member's primary classroom via
  /// `PATCH /api/v1/staff-classrooms/{staffCode}/primary-classroom`.
  Future<String> updateStaffPrimaryClassroom({
    required String staffCode,
    required String classroomCode,
  });

  /// Updates the *logged-in* staff member's basic profile + address via
  /// `PATCH /api/v1/staff/staff/my-profile/{staffCode}`.
  ///
  /// [fields] should match the backend contract:
  /// {
  ///   "firstName": "string",
  ///   "lastName": "string",
  ///   "phoneNumber": "string",
  ///   "addressStreet": "string",
  ///   "addressLine2": "string",
  ///   "addressCity": "string",
  ///   "addressState": "string",
  ///   "addressZipCode": "string",
  ///   "addressCountry": "string"
  /// }
  Future<String> updateMyProfile({
    required String staffCode,
    required Map<String, dynamic> fields,
  });

  /// Changes the login email for a user via
  /// `POST /api/v1/users/{userCode}/email-change`.
  Future<String> changeUserEmail({
    required String userCode,
    required String oldEmail,
    required String newEmail,
    required String organizationCode,
    required String schoolCode,
  });

  /// Fetches the staff sign-in PIN via my-profile pin API.
  Future<String> getStaffSignInPin({required String staffCode});

  /// Fetches staff important dates via `/api/v1/staff-dates/{staffCode}`.
  ///
  /// Returns a list of map entries shaped as:
  /// {
  ///   "importantDateType": "HIRE_DATE",
  ///   "dueDate": "2026-02-06",
  ///   "completedDate": "2026-02-06"
  /// }
  Future<List<Map<String, String>>> getImportantDates({
    required String staffCode,
  });

  Future<String> updateImportantDates({
    required String staffCode,
    required List<Map<String, String>> dates,
  });

  /// Fetches the staff member's work and break schedules from the dedicated
  /// schedule API: `GET /api/v1/staff-schedules/{staffCode}`.
  Future<
    ({
      List<StaffProfileWorkSchedule> workSchedules,
      List<StaffProfileBreakSchedule> breakSchedules,
    })
  >
  getStaffSchedules({required String staffCode});

  /// Updates staff work & break schedules via `/api/v1/staff-schedules/{staffCode}`.
  ///
  /// [workSchedules] and [breakSchedules] should already be shaped according to
  /// the backend contract (see API docs).
  Future<String> updateStaffSchedules({
    required String staffCode,
    required List<Map<String, dynamic>> workSchedules,
    required List<Map<String, dynamic>> breakSchedules,
  });

  /// School operating hours per weekday from school settings
  /// (`GET /api/v1/organization/schools/{schoolCode}`).
  Future<List<SchoolRegularScheduleDay>> getSchoolRegularSchedules({
    required String schoolCode,
  });

  Future<CreateSchoolUserResult> createSchoolAdminUser({
    required String firstName,
    required String lastName,
    required String displayName,
    required String mobile,
    required String email,
    required String organizationCode,
    required String schoolCode,
    required String role,
    required String designation,
    String? userCode,
  });

  Future<CreateSchoolUserResult> createStaffUser({
    required String firstName,
    required String lastName,
    required String displayName,
    required String mobile,
    required String email,
    required String organizationCode,
    required String schoolCode,
    required String role,
    required String designation,
    required String status,
    required String primaryClassroomCode,
    required List<String> allowedClassroomCodes,
    String? userCode,
  });

  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Permanently deletes a school user via `DELETE /api/v1/school-users`.
  Future<String> deleteSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Deactivates an organization admin via
  /// `POST /api/v1/organization-admins/deactivate`.
  Future<String> deactivateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  });

  /// Activates an organization admin via
  /// `POST /api/v1/user/organization-admins/activate`.
  Future<String> activateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  });

  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Clears in-flight / dedupe maps. Disk caches use [StorageService] (cleared by auth logout).
  void clearSessionVolatileCaches();

  Future<({int expiredDocumentCount, int expiringWithinWeekCount})>
  getStaffDocumentExpirySummary({required String schoolCode});

  Future<
    ({
      int overduePhysicalCheckupCount,
      int staffWithoutActivePhysicalCheckupCount,
    })
  >
  getPhysicalCheckupSummary({required String schoolCode});

  /// Updates work break reminder preference via PATCH API.
  ///
  /// Returns true if the reminder was enabled, false if disabled.
  Future<bool> updateWorkBreakReminder({
    required String staffCode,
    required bool enabled,
  });
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StaffRepositoryWithCache {
  Future<StaffPage?> loadCachedStaffPage(
    String schoolCode, {
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  });
  Future<void> invalidateCachedStaffPage(
    String schoolCode, {
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  });
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(String staffCode);
  Future<StaffProfile?> loadCachedStaffProfile(
    String staffCode, {
    bool forEditStaff = false,
  });
  Future<List<Map<String, String>>?> loadCachedImportantDates(String staffCode);
  Future<StaffCount?> loadCachedStaffCount({
    required String organizationCode,
    required String schoolCode,
  });
}
