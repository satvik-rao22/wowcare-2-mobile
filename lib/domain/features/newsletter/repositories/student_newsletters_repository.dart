import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/newsletter/entities/paginated_newsletters_entity.dart';

abstract class StudentNewslettersRepository {
  Future<Either<Failure, PaginatedNewslettersEntity>> getStudentNewsletters({
    required String studentCode,
    required int page,
    required int size,
    String status = 'SENT',
  });
}
