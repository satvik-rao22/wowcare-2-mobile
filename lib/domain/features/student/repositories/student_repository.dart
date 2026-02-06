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
  });

  Future<String> reactivateStudent({
    required String code,
  });
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StudentRepositoryWithCache {
  Future<StudentPage?> loadCachedStudentPage(String schoolCode);
}

