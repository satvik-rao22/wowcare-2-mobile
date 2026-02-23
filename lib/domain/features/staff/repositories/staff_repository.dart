import '../entities/staff_member.dart';
import '../entities/staff_document.dart';
import '../entities/staff_documents_page.dart';
import '../entities/staff_profile.dart';
import '../entities/create_school_user_result.dart';
import '../entities/staff_count.dart';

abstract class StaffRepository {
  Future<StaffCount> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  });

  Future<StaffPage> getStaffPage({
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

  Future<StaffProfile> getStaffProfile({
    required String staffCode,
  });

  /// Updates staff profile core details (name, status, phone, designation, jobTag, classrooms, etc.).
  ///
  /// [fields] should follow the backend PATCH contract for `/api/v1/staff/{staffCode}/profile`.
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

  /// Updates staff work & break schedules via `/api/v1/staff-schedules/{staffCode}`.
  ///
  /// [workSchedules] and [breakSchedules] should already be shaped according to
  /// the backend contract (see API docs).
  Future<String> updateStaffSchedules({
    required String staffCode,
    required List<Map<String, dynamic>> workSchedules,
    required List<Map<String, dynamic>> breakSchedules,
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

  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
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
  });
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(String staffCode);
  Future<StaffProfile?> loadCachedStaffProfile(String staffCode);
  Future<List<Map<String, String>>?> loadCachedImportantDates(String staffCode);
}



