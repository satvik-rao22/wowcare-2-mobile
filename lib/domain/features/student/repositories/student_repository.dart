import '../entities/student.dart';
import '../entities/student_documents_page.dart';
import '../entities/student_important_dates.dart';

abstract class StudentRepository {
  Future<StudentPage> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    int page,
    int size,
  });

  Future<String> deactivateStudent({
    required String code,
    required String schoolCode,
  });

  Future<String> reactivateStudent({
    required String code,
    required String schoolCode,
  });

  Future<Student> createStudent({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  });

  /// Updates student profile core details via `/api/v1/student/{code}/profile`.
  ///
  /// [fields] should follow the backend PATCH contract for `/api/v1/student/{code}/profile`.
  Future<String> updateStudentProfile({
    required String code,
    required Map<String, dynamic> fields,
  });

  /// Updates the student's address via `/api/v1/student/{studentCode}/address`.
  Future<String> updateStudentAddress({
    required String studentCode,
    required Map<String, dynamic> fields,
  });

  /// Updates the student's siblings via `/api/v1/student/{studentCode}/siblings`.
  Future<String> updateStudentSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  });

  /// Fetches paginated student documents. [studentCode] = ownerId.
  Future<StudentDocumentsPage> getStudentDocuments({
    required String studentCode,
    int page = 0,
    int size = 10,
    bool? expiredOnly,
  });

  /// Adds a student document via POST /api/v1/student-documents.
  Future<String> addStudentDocument({
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? notes,
  });

  /// Updates a student document via PATCH /api/v1/student-documents/{code}`.
  Future<String> updateStudentDocument({
    required String documentUuid,
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? notes,
  });

  /// Deletes a student document via DELETE `/api/v1/student-documents/{code}`.
  Future<String> deleteStudentDocument({
    required String documentUuid,
    required String studentCode,
  });

  /// Fetches important dates for a student via
  /// `GET /api/v1/student/{code}/important-dates`.
  Future<StudentImportantDates> getStudentImportantDates({
    required String studentCode,
  });

  /// Updates important dates for a student via
  /// `PATCH /api/v1/student/{code}/important-dates`.
  Future<String> updateStudentImportantDates({
    required String studentCode,
    required StudentImportantDates dates,
  });

  /// Creates or links a guardian user to a student via `/api/v1/guardian-user`.
  ///
  /// Returns the backend `message` field.
  Future<String> createGuardianUser({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
  });

  /// Fetches all guardians/parents for a school via `GET /api/v1/guardian`.
  ///
  /// Returns a list of display names (e.g. "First Last") suitable for dropdowns.
  Future<List<String>> getGuardianNamesForSchool({
    required String schoolCode,
  });

  /// Fetches all tag names for a school via `GET /api/v1/tags`.
  ///
  /// Returns a list of tag display names (e.g. "5 Days", "Vegetarian") suitable
  /// for dropdowns.
  Future<List<String>> getTagNamesForSchool({
    required String schoolCode,
  });

  /// Returns a mapping from tag display name to tag code for a given school.
  ///
  /// This is useful when filters are selected by tag name in the UI but the
  /// backend expects tagCodes in query parameters.
  Future<Map<String, String>> getTagNameCodeMapForSchool({
    required String schoolCode,
  });

  /// Returns a mapping from guardian display name (as used in filters) to guardian
  /// code for a given school.
  ///
  /// Display names must follow the same rules as `getGuardianNamesForSchool` so
  /// that selected filter values can be resolved back to codes for the API.
  Future<Map<String, String>> getGuardianNameCodeMapForSchool({
    required String schoolCode,
  });

  /// Fetches student counts (active, upcoming, enrolled) for a school.
  ///
  /// The returned map must contain keys: 'activeCount', 'upcomingCount',
  /// and 'enrolledCount'.
  Future<Map<String, int>> getStudentCounts({
    required String schoolCode,
  });

  /// Updates a student's tags via `POST /api/v1/student-tags`.
  ///
  /// [tagCodes] must be backend tag codes (e.g. TAG_...).
  Future<String> updateStudentTags({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  });

  /// Links an existing guardian to a student via `/api/v1/guardian/existing`.
  ///
  /// Returns the backend `message` field.
  Future<String> linkExistingGuardian({
    required String guardianCode,
    required String studentCode,
  });
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StudentRepositoryWithCache {
  Future<StudentPage?> loadCachedStudentPage(
    String schoolCode, {
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    String? code,
    String? firstName,
    String? lastName,
  });

  /// Invalidates the cached first page for the given list query (filters included).
  ///
  /// This is useful after mutations (add/edit/deactivate/reactivate) or when the
  /// user changes filters, to ensure `loadInitial()` doesn't hydrate stale data.
  Future<void> invalidateCachedStudentPage(
    String schoolCode, {
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    String? code,
    String? firstName,
    String? lastName,
  });

  Future<StudentDocumentsPage?> loadCachedStudentDocuments(String studentCode);
}

