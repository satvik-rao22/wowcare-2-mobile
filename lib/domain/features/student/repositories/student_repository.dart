import '../entities/student.dart';

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
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StudentRepositoryWithCache {
  Future<StudentPage?> loadCachedStudentPage(String schoolCode);
}

