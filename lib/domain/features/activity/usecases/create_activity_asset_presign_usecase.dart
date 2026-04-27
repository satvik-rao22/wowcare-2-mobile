import '../repositories/activity_repository.dart';
import '../entities/activity_asset_presign.dart';

class CreateActivityAssetPresignUseCase {
  CreateActivityAssetPresignUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityAssetPresign> call({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    required String checksumSha256,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  }) {
    return _repository.createActivityAssetPresign(
      sessionCode: sessionCode,
      documentApiBasePath: documentApiBasePath,
      fileName: fileName,
      contentType: contentType,
      contentLengthBytes: contentLengthBytes,
      checksumSha256: checksumSha256,
      mediaType: mediaType,
      ownerType: ownerType,
      ownerCode: ownerCode,
    );
  }
}

