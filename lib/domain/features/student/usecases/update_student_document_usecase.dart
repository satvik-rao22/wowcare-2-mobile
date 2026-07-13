import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/util/api_error_handler.dart';
import '../repositories/student_repository.dart';

class UpdateStudentDocumentUseCase {
  UpdateStudentDocumentUseCase(this._repository);

  final StudentRepository _repository;

  Future<Either<Failure, String>> call({
    required String documentUuid,
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
      final message = await _repository.updateStudentDocument(
        documentUuid: documentUuid,
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
      );
      return Right(message);
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(errorMessage));
    }
  }
}

