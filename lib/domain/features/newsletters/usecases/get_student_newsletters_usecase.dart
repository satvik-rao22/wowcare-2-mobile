import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/newsletters/entities/paginated_newsletters_entity.dart';
import 'package:wowcare/domain/features/newsletters/repositories/student_newsletters_repository.dart';

class GetStudentNewslettersUseCase {
  GetStudentNewslettersUseCase(this._repository);

  final StudentNewslettersRepository _repository;

  Future<Either<Failure, PaginatedNewslettersEntity>> call({
    required String studentCode,
    required int page,
    required int size,
    String status = 'SENT',
  }) {
    return _repository.getStudentNewsletters(
      studentCode: studentCode,
      page: page,
      size: size,
      status: status,
    );
  }
}

