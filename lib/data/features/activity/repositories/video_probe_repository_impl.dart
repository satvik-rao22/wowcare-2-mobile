import 'package:wowcare/data/features/activity/datasources/video_probe_local_datasource.dart';
import 'package:wowcare/domain/features/activity/repositories/video_probe_repository.dart';

class VideoProbeRepositoryImpl implements VideoProbeRepository {
  const VideoProbeRepositoryImpl(this._dataSource);

  final VideoProbeLocalDataSource _dataSource;

  @override
  Future<VideoProbe> probe(String path) async {
    try {
      return await _dataSource.probe(path);
    } catch (_) {
      // Contract: never throws. An unreadable file IS the answer.
      return VideoProbe.undecodable;
    }
  }
}
