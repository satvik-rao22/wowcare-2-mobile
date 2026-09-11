import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';
import 'package:wowcare/domain/features/activity/repositories/lost_media_repository.dart';

/// Claims a camera capture the OS took from us mid-flight (Android activity
/// death during recording). See [LostMediaRepository.retrieveLostMedia] — the
/// call is destructive and never throws.
class RetrieveLostMediaUseCase {
  RetrieveLostMediaUseCase(this._repository);

  final LostMediaRepository _repository;

  Future<RecoveredMedia> call() => _repository.retrieveLostMedia();
}
