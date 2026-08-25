import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/util/api_error_handler.dart';
import '../entities/staff_document.dart';
import '../repositories/staff_repository.dart';

class UpdateStaffDocumentUseCase {
  UpdateStaffDocumentUseCase(this._repository);

  final StaffRepository _repository;

  Future<Either<Failure, String>> call({
    required String documentUuid,
    required StaffDocument document,
    required String staffCode,
  }) async {
    try {
      final message = await _repository.updateStaffDocument(
        documentUuid: documentUuid,
        document: document,
        staffCode: staffCode,
      );
      return Right(message);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}
