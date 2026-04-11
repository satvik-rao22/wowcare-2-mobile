import '../entities/activity_feed_row.dart';
import '../repositories/activity_repository.dart';

class GetRangeActivityFeedUseCase {
  GetRangeActivityFeedUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityFeedPage> call({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  }) {
    return _repository.getRangeActivityFeed(
      classroomCode: classroomCode,
      startDate: startDate,
      endDate: endDate,
      studentCode: studentCode,
      activityTypeCode: activityTypeCode,
      page: page,
      size: size,
    );
  }
}

