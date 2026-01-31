import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/util/api_error_handler.dart';
import '../repositories/staff_repository.dart';

class UpdateImportantDatesUseCase {
  UpdateImportantDatesUseCase(this._repository);

  final StaffRepository _repository;

  Future<Either<Failure, String>> call({
    required String staffCode,
    required List<Map<String, String>> dates,
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

