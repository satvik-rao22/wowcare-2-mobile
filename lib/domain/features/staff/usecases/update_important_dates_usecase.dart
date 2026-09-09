import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../entities/staff_important_date.dart';
import '../repositories/staff_repository.dart';

class UpdateImportantDatesUseCase {
  UpdateImportantDatesUseCase(this._repository);

  final StaffRepository _repository;

  Future<Either<Failure, String>> call({
    required String staffCode,
    required List<StaffImportantDate> dates,
  }) async {
    try {
      final message = await _repository.updateImportantDates(
        staffCode: staffCode,
        dates: dates,
      );
      return Right(message);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}

