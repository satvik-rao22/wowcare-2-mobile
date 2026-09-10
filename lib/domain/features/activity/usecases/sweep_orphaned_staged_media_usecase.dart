import 'package:wowcare/domain/features/activity/repositories/media_staging_repository.dart';

/// Deletes staged copies left behind by previous runs.
///
/// [maxAge] defaults to 7 days. That is deliberately far longer than any
/// plausible in-flight upload: the app has no per-file record of which staged
/// copies belong to a live upload (see the note on
/// `MediaStagingRepository.sweepOrphans`), so age is the only safe
/// discriminator and it is set well beyond the point where a file could still
/// be in use.
class SweepOrphanedStagedMediaUseCase {
  SweepOrphanedStagedMediaUseCase(this._repository);

  final MediaStagingRepository _repository;

  Future<int> call({Duration maxAge = const Duration(days: 7)}) =>
      _repository.sweepOrphans(maxAge: maxAge);
}
