import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';

/// One-shot status read — the photo screen's background-poll strategy.
class GetActivityUploadAssetStatusesUseCase {
  GetActivityUploadAssetStatusesUseCase(this._repository);

  final ActivityMediaUploadRepository _repository;

  Future<Map<String, String>> call({
    required String sessionCode,
    required List<String> assetCodes,
  }) {
    return _repository.getUploadAssetStatuses(
      sessionCode: sessionCode,
      assetCodes: assetCodes,
    );
  }
}
