import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/data/features/activity/datasources/lost_media_local_datasource.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';
import 'package:wowcare/domain/features/activity/repositories/lost_media_repository.dart';

class LostMediaRepositoryImpl implements LostMediaRepository {
  LostMediaRepositoryImpl(this._dataSource);

  final LostMediaLocalDataSource _dataSource;

  @override
  Future<RecoveredMedia> retrieveLostMedia() async {
    try {
      return await _dataSource.retrieveLostMedia();
    } catch (error, stackTrace) {
      // Recovery is a best-effort nicety layered on top of the normal picker
      // flow: if claiming the cached capture fails, the screen must open
      // exactly as it did before this feature existed. Swallowing here (rather
      // than at the call site) is what lets the contract promise "never
      // throws".
      AppLogger.e(
        '[LostMedia] retrieveLostData failed; continuing without recovery',
        error,
        stackTrace,
      );
      return RecoveredMedia.none;
    }
  }
}
