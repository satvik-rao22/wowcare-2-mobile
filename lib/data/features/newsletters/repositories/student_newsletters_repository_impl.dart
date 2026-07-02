import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/newsletters/entities/paginated_newsletters_entity.dart';
import 'package:wowcare/domain/features/newsletters/repositories/student_newsletters_repository.dart';

import '../datasources/student_newsletters_remote_datasource.dart';

class StudentNewslettersRepositoryImpl implements StudentNewslettersRepository {
  StudentNewslettersRepositoryImpl({required this.remoteDataSource});

  final StudentNewslettersRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, PaginatedNewslettersEntity>> getStudentNewsletters({
    required String studentCode,
    required int page,
    required int size,
    String status = 'SENT',
  }) async {
    try {
      final model = await remoteDataSource.getStudentNewsletters(
        studentCode: studentCode,
        page: page,
        size: size,
        status: status,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }
}

