import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../repositories/student_repository.dart';

class DeleteStudentDocumentUseCase {
  DeleteStudentDocumentUseCase(this._repository);

  final StudentRepository _repository;

  Future<Either<Failure, String>> call({
    required String documentUuid,
    required String studentCode,
  }) async {
    try {
      final message = await AppEvents.track(
        AppEvent.studentDocumentDelete,
        () => _repository.deleteStudentDocument(
          documentUuid: documentUuid,
          studentCode: studentCode,
        ),
      );
      return Right(message);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}

