import '../entities/staff_member.dart';
import '../entities/staff_document.dart';
import '../entities/staff_documents_page.dart';
import '../entities/staff_profile.dart';
import '../entities/create_school_user_result.dart';

abstract class StaffRepository {
  Future<StaffPage> getStaffPage({
    required String schoolCode,
    int page,
    int size,
    String? status,
    String? designation,
    String? search,
  });

  Future<String> addStaffDocument({
    required String staffCode,
    required StaffDocument document,
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

  Future<String> updateImportantDates({
    required String staffCode,
    required List<Map<String, String>> dates,
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
  Future<StaffPage?> loadCachedStaffPage(String schoolCode);
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(String staffCode);
  Future<StaffProfile?> loadCachedStaffProfile(String staffCode);
}



