import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';
import 'package:wowcare/domain/features/activity/repositories/lost_media_repository.dart';

/// Claims a camera capture the OS took from us mid-flight (Android activity
/// death during recording). See [LostMediaRepository.retrieveLostMedia] — the
/// call is destructive and never throws.
///
/// Logs [AppEvent.activityMediaRecover] only when something was pending: this
/// runs on every editor open and resume, and "nothing to recover" is the
/// normal answer, not an outcome worth a line.
class RetrieveLostMediaUseCase {
  RetrieveLostMediaUseCase(this._repository);

  final LostMediaRepository _repository;

  Future<RecoveredMedia> call() async {
    final stopwatch = Stopwatch()..start();
    final recovered = await _repository.retrieveLostMedia();
    if (recovered.isNotEmpty) {
      AppEvents.succeeded(
        AppEvent.activityMediaRecover,
        count: recovered.filePaths.length,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } else if (recovered.hasFailedCapture) {
      // The camera app itself died: a capture was pending but no file came
      // back, and the platform's message is not ours to send.
      AppEvents.failed(
        AppEvent.activityMediaRecover,
        EventFailure.unknown,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
    return recovered;
  }
}
