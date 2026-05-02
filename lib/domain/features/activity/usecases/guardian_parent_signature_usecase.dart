import 'package:wowcare/core/util/api_error_handler.dart';

import '../repositories/activity_repository.dart';

class GuardianParentSignatureUseCase {
  GuardianParentSignatureUseCase(this._repository);

  final ActivityRepository _repository;

  Future<String> call({
    required String code,
    required String parameterCode,
    required String guardianCode,
    String? signatureValue,
  }) async {
    try {
      return await _repository.guardianParentSignature(
        code: code,
        parameterCode: parameterCode,
        guardianCode: guardianCode,
        signatureValue: signatureValue,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
