import 'package:wowcare/domain/features/activity/repositories/media_staging_repository.dart';

/// Deletes one staged copy, once the server has confirmed its upload or the
/// user has explicitly discarded it. Never throws.
class DiscardStagedMediaUseCase {
  DiscardStagedMediaUseCase(this._repository);

  final MediaStagingRepository _repository;

  Future<void> call(String stagedPath) => _repository.discard(stagedPath);
}
