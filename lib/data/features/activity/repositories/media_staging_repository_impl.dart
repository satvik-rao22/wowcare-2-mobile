import 'package:wowcare/core/observability/media_upload_trace.dart';
import 'package:wowcare/data/features/activity/datasources/media_staging_local_datasource.dart';
import 'package:wowcare/domain/features/activity/entities/staged_media.dart';
import 'package:wowcare/domain/features/activity/repositories/media_staging_repository.dart';

class MediaStagingRepositoryImpl implements MediaStagingRepository {
  MediaStagingRepositoryImpl(this._dataSource);

  final MediaStagingLocalDataSource _dataSource;

  @override
  Future<StagedMedia> stage(String sourcePath) async {
    MediaUploadTrace.stage(MediaUploadStage.stagingStarted);
    try {
      final staged = await _dataSource.stage(sourcePath);
      MediaUploadTrace.stage(MediaUploadStage.stagingDone);
      // Re-recorded from the copy rather than trusted from the source: this is
      // the size everything downstream will actually read.
      MediaUploadTrace.fileSizeBytes(staged.sizeBytes);
      return staged;
    } on MediaStagingException catch (e, stackTrace) {
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.stagingFailed,
        e.failure.name,
      );
      MediaUploadTrace.failure(MediaUploadStage.stagingFailed, e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> discard(String stagedPath) async {
    try {
      await _dataSource.discard(stagedPath);
    } catch (_) {
      // Best-effort by contract. A copy that outlives its upload is swept by
      // [sweepOrphans] on a later app start, so failing here changes nothing a
      // caller could act on.
    }
  }

  @override
  Future<int> sweepOrphans({required Duration maxAge}) async {
    try {
      final deleted = await _dataSource.sweepOrphans(maxAge: maxAge);
      if (deleted > 0) {
        MediaUploadTrace.orphansSwept(deleted);
        MediaUploadTrace.stage(MediaUploadStage.orphanSwept);
      }
      return deleted;
    } catch (_) {
      return 0;
    }
  }
}
