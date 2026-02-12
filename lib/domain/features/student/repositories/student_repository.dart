import '../entities/student.dart';
import '../entities/student_document.dart';
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

  Future<StudentDocumentsPage> getStudentDocuments({
    required String studentCode,
    int page,
    int size,
    String sort,
    String? name,
    String? type,
  });

  // Future<String> addStudentDocument({
  //   required String studentCode,
  //   required StudentDocument document,
  // });
  //
  // Future<String> updateStudentDocument({
  //   required String documentUuid,
  //   required StudentDocument document,
  //   required String studentCode,
  // });
  //
  // Future<String> deleteStudentDocument({
  //   required String documentUuid,
  //   required String studentCode,
  // });

}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StudentRepositoryWithCache {
  Future<StudentPage?> loadCachedStudentPage(String schoolCode);
}

