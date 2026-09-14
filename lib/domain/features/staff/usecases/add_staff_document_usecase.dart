import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../entities/staff_document.dart';
import '../repositories/staff_repository.dart';

class AddStaffDocumentUseCase {
  AddStaffDocumentUseCase(this._repository);

  final StaffRepository _repository;

  Future<Either<Failure, String>> call({
    required String staffCode,
    required StaffDocument document,
  }) async {
    try {
      final message = await _repository.addStaffDocument(
        staffCode: staffCode,
        document: document,
      );
      return Right(message);
    } catch (e) {
      // Extract error message from API response using common utility
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}

