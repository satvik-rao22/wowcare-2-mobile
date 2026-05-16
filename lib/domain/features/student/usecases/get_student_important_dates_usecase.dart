import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/util/api_error_handler.dart';
import '../entities/student_important_dates.dart';
import '../repositories/student_repository.dart';

class GetStudentImportantDatesUseCase {
  GetStudentImportantDatesUseCase(this._repository);

  final StudentRepository _repository;

  Future<Either<Failure, StudentImportantDates>> call({
    required String studentCode,
  }) async {
    try {
      final dates = await _repository.getStudentImportantDates(
        studentCode: studentCode,
      );
      return Right(dates);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}
