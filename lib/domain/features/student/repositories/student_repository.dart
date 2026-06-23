import '../entities/student.dart';
import '../entities/student_documents_page.dart';
import '../entities/student_guardian.dart';
import '../entities/student_health.dart';
import '../entities/student_immunization.dart';
import '../entities/student_important_dates.dart';
import '../entities/student_physical_exam.dart';
import '../entities/student_physician.dart';
import '../entities/student_pickup.dart';
import '../entities/student_profile.dart';
import '../entities/student_regular_schedule.dart';

abstract class StudentRepository {
  /// Fetches a single student profile via `GET /api/v1/student/student/{code}`.
  Future<StudentProfile> getStudentProfile({required String code});

  /// Fetches a student's regular schedule from the dedicated schedule API:
  /// `GET /api/v1/regular-schedules?studentCode={studentCode}`.
  Future<List<StudentRegularScheduleEntry>> getStudentRegularSchedules({
    required String studentCode,
  });
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

  Future<String> deleteStudent({
    required String code,
    required String schoolCode,
  });

  /// [classroom] must be the backend classroom **code**, not the display name.
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

  /// Updates the student's siblings via `PUT /api/v1/student/student/{studentCode}/siblings`.
  Future<String> updateStudentSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  });

  /// Links siblings onto a newly created student via
  /// `POST /api/v1/student/{newStudentCode}/add-sibling` (add-student flow only).
  Future<String> addStudentSibling({
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
    String? assetCode,
    String? uploadedBy,
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
    String? assetCode,
    String? uploadedBy,
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
  /// Returns the backend `message` and the newly created `guardianCode`
  /// (needed to upload the guardian's profile photo right after creation).
  Future<({String message, String? guardianCode})> createGuardianUser({
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
  Future<List<String>> getGuardianNamesForSchool({required String schoolCode});

  /// Fetches all tag names for a school via `GET /api/v1/tags`.
  ///
  /// Returns a list of tag display names (e.g. "5 Days", "Vegetarian") suitable
  /// for dropdowns.
  Future<List<String>> getTagNamesForSchool({required String schoolCode});

  /// Returns a mapping from tag display name to tag code for a given school.
  ///
  /// This is useful when filters are selected by tag name in the UI but the
  /// backend expects tagCodes in query parameters.
  Future<Map<String, String>> getTagNameCodeMapForSchool({
    required String schoolCode,
  });

  /// Students in [classroomCode] matching [tagCodes] for activity feeds.
  ///
  /// `POST /api/v1/student-tags/activity-filter`
  Future<List<String>> getStudentCodesForActivityTagFilter({
    required String schoolCode,
    required String classroomCode,
    required List<String> tagCodes,
  });

  /// Returns a mapping from guardian display name (as used in filters) to guardian
  /// code for a given school.
  ///
  /// Display names must follow the same rules as `getGuardianNamesForSchool` so
  /// that selected filter values can be resolved back to codes for the API.
  Future<Map<String, String>> getGuardianNameCodeMapForSchool({
    required String schoolCode,
  });

  /// Logged-in guardian profile from `GET /api/v1/guardian/profile`.
  ///
  /// Query: [schoolCode], [userCode]. Returns API `data` (includes guardian
  /// `code` and `userCode`).
  Future<Map<String, dynamic>> getGuardianProfile({
    required String schoolCode,
    required String userCode,
  });

  /// Fetches student counts (active, upcoming, enrolled) for a school.
  ///
  /// The returned map must contain keys: 'activeCount', 'upcomingCount',
  /// and 'enrolledCount'.
  Future<Map<String, int>> getStudentCounts({required String schoolCode});

  /// `GET /api/v1/student/student-documents/expiry-count`
  Future<({int expiredDocumentCount, int expiringWithinWeekCount, int totalDocumentsWithExpiry})>
      getStudentDocumentExpiryCount({required String schoolCode});

  /// `GET /api/v1/student/student/physical-checkup-count/{schoolCode}`
  Future<({int overdueExamCount, int studentsWithoutActiveExamCount})>
      getStudentPhysicalCheckupCount({required String schoolCode});

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
    String? relation,
    String? relationDescription,
  });

  /// Updates a guardian via `PATCH /api/v1/guardian/{code}`.
  ///
  /// [fields] should follow the backend PATCH contract.
  Future<String> updateGuardian({
    required String code,
    required String studentCode,
    required Map<String, dynamic> fields,
  });

  /// Deletes a guardian via `DELETE /api/v1/guardian/{code}`.
  Future<String> deleteGuardian({
    required String code,
    required String studentCode,
  });

  /// Fetches a student's pickup contacts.
  ///
  /// [forceRefresh] bypasses the local cache and re-fetches from the network.
  Future<List<StudentPickup>> getStudentPickups({
    required String studentCode,
    bool forceRefresh = false,
  });

  /// Adds a pickup contact for a student. Returns the backend `message` field.
  Future<String> addPickup({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
  });

  /// Updates an existing pickup contact. Returns the backend `message` field.
  Future<String> updatePickup({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? clockPin,
    String? relationshipDescription,
    String? pickupType,
    String? carpoolId,
  });

  /// Deletes a pickup contact. Returns the backend `message` field.
  Future<String> deletePickup({
    required String code,
    required String studentCode,
  });

  /// Raw guardians list for a school (includes email/mobile/code), used by UI
  /// flows that need full guardian details for dropdown selection.
  Future<List<Map<String, dynamic>>> getGuardiansRawForSchool({
    required String schoolCode,
  });

  // --- Physicians ---

  /// Fetches a student's physician contacts.
  Future<List<StudentPhysician>> getStudentPhysicians({
    required String studentCode,
  });

  /// Adds a physician for a student. Returns the created physician.
  Future<StudentPhysician> addPhysician({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  });

  /// Updates a physician. Returns the updated physician.
  Future<StudentPhysician> updatePhysician({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  });

  /// Deletes a physician. Returns the backend `message` field.
  Future<String> deletePhysician({
    required String code,
    required String studentCode,
  });

  // --- Health ---

  /// Fetches a student's health details.
  Future<StudentHealth> getStudentHealth({required String studentCode});

  /// Updates a student's health details. Returns the updated health record.
  Future<StudentHealth> updateStudentHealth({
    required String studentCode,
    required Map<String, dynamic> body,
  });

  // --- Immunizations ---

  /// Fetches a student's immunization (vaccine dose) records.
  Future<List<StudentImmunization>> getStudentImmunizations({
    required String studentCode,
    bool forceRefresh = false,
  });

  /// Updates a single immunization record (due/administered date + status).
  /// Returns the updated record.
  Future<StudentImmunization> updateStudentImmunizationRecord({
    required String studentCode,
    required StudentImmunization record,
    required DateTime date,
    required String status,
    String? exemptionReason,
  });

  // --- Physical exams ---

  /// Fetches a student's physical exam records.
  Future<List<StudentPhysicalExam>> getStudentPhysicalExams({
    required String studentCode,
    bool forceRefresh = false,
  });

  /// Adds a physical exam record. Returns the created record.
  Future<StudentPhysicalExam> addStudentPhysicalExam({
    required String studentCode,
    required DateTime examDate,
    required String status,
    String? notes,
  });

  /// Updates a physical exam record. Returns the updated record.
  Future<StudentPhysicalExam> updateStudentPhysicalExam({
    required String studentCode,
    required String examCode,
    required DateTime examDate,
    required String status,
    String? notes,
  });

  // --- Guardians ---

  /// Fetches a student's guardians/parents.
  ///
  /// [forceRefresh] bypasses the local cache and re-fetches from the network.
  Future<List<StudentGuardian>> getStudentGuardians({
    required String studentCode,
    bool forceRefresh = false,
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
