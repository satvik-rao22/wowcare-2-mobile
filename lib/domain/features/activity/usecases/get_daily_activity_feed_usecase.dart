import '../entities/activity_feed_row.dart';
import '../repositories/activity_repository.dart';

class GetDailyActivityFeedUseCase {
  GetDailyActivityFeedUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityFeedPage> call({
    required String classroomCode,
    required String date,
    String? studentCode,
    List<String>? activityTypeCodes,
    bool guardianPersona = false,
    int page = 0,
    int size = 100,
  }) {
    return _repository.getDailyActivityFeed(
      classroomCode: classroomCode,
      date: date,
      studentCode: studentCode,
      activityTypeCodes: activityTypeCodes,
      guardianPersona: guardianPersona,
      page: page,
      size: size,
    );
  }
}
