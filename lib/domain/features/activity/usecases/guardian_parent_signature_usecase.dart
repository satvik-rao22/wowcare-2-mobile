import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

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
      return await AppEvents.track(
        AppEvent.activityParentSignature,
        () => _repository.guardianParentSignature(
          code: code,
          parameterCode: parameterCode,
          guardianCode: guardianCode,
          signatureValue: signatureValue,
        ),
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
