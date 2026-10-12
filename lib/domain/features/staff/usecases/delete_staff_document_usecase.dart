import 'package:wowcare/core/observability/app_events.dart';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../repositories/staff_repository.dart';

class DeleteStaffDocumentUseCase {
  DeleteStaffDocumentUseCase(this._repository);

  final StaffRepository _repository;

  Future<Either<Failure, String>> call({
    required String documentUuid,
    required String staffCode,
  }) async {
    try {
      final message = await AppEvents.track(
        AppEvent.staffDocumentDelete,
        () => _repository.deleteStaffDocument(
          documentUuid: documentUuid,
          staffCode: staffCode,
        ),
      );
      return Right(message);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}

