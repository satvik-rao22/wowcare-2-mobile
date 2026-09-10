import 'package:wowcare/domain/features/activity/entities/staged_media.dart';
import 'package:wowcare/domain/features/activity/repositories/media_staging_repository.dart';

/// Copies a freshly captured/picked file out of cache into persistent storage.
/// Throws [MediaStagingException] if the copy cannot be made.
class StageMediaForUploadUseCase {
  StageMediaForUploadUseCase(this._repository);

  final MediaStagingRepository _repository;

  Future<StagedMedia> call(String sourcePath) => _repository.stage(sourcePath);
}
