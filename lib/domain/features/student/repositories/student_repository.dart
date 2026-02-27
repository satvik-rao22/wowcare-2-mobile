import '../entities/student.dart';
import '../entities/student_documents_page.dart';

abstract class StudentRepository {
  Future<StudentPage> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
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
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StudentRepositoryWithCache {
  Future<StudentPage?> loadCachedStudentPage(String schoolCode);
  Future<StudentDocumentsPage?> loadCachedStudentDocuments(String studentCode);
}

