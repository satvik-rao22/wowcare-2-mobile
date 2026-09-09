import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';

/// Blocking readiness poll — the shared util's strategy.
class WaitActivityAssetsReadyUseCase {
  WaitActivityAssetsReadyUseCase(this._repository);

  final ActivityMediaUploadRepository _repository;

  Future<void> call({
    required String sessionCode,
    required List<String> assetCodes,
  }) {
    return _repository.waitUntilAssetsReady(
      sessionCode: sessionCode,
      assetCodes: assetCodes,
    );
  }
}
