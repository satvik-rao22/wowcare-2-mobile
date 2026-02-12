import '../../../../domain/features/student/entities/student_documents_page.dart';
import '../../../../domain/features/student/repositories/student_repository.dart';

class GetStudentDocumentsUseCase {
  GetStudentDocumentsUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentDocumentsPage> call({
    required String studentCode,
    int page = 0,
    int size = 10,
    String sort = 'name,asc',
    String? name,
    String? type,
  }) {
    return _repository.getStudentDocuments(
      studentCode: studentCode,
      page: page,
      size: size,
      sort: sort,
      name: name,
      type: type,
    );
  }
}
