import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/util/api_error_handler.dart';
import '../entities/staff_important_date.dart';
import '../repositories/staff_repository.dart';

class GetImportantDatesUseCase {
  GetImportantDatesUseCase(this._repository);

  final StaffRepository _repository;

  Future<Either<Failure, List<StaffImportantDate>>> call({
    required String staffCode,
  }) async {
    try {
      final dates = await _repository.getImportantDates(
        staffCode: staffCode,
      );
      return Right(dates);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}


