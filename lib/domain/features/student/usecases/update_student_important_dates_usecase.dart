import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../entities/student_important_dates.dart';
import '../repositories/student_repository.dart';

class UpdateStudentImportantDatesUseCase {
  UpdateStudentImportantDatesUseCase(this._repository);

  final StudentRepository _repository;

  Future<Either<Failure, String>> call({
    required String studentCode,
    required StudentImportantDates dates,
  }) async {
    try {
      final message = await _repository.updateStudentImportantDates(
        studentCode: studentCode,
        dates: dates,
      );
      return Right(message);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}

