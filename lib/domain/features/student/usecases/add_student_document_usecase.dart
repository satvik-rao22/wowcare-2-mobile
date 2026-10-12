import 'package:wowcare/core/observability/app_events.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../repositories/student_repository.dart';

class AddStudentDocumentUseCase {
  AddStudentDocumentUseCase(this._repository);

  final StudentRepository _repository;

  Future<Either<Failure, String>> call({
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? assetCode,
    String? uploadedBy,
    String? notes,
  }) async {
    try {
      final message = await AppEvents.track(
        AppEvent.studentDocumentAdd,
        () => _repository.addStudentDocument(
          studentCode: studentCode,
          name: name,
          type: type,
          expiryDate: expiryDate,
          storagePath: storagePath,
          mimeType: mimeType,
          size: size,
          assetCode: assetCode,
          uploadedBy: uploadedBy,
          notes: notes,
        ),
      );
      return Right(message);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}
