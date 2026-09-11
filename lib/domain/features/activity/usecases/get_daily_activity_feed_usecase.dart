import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class GetDailyActivityFeedUseCase {
  GetDailyActivityFeedUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityFeedPage> call({
    required String classroomCode,
    required String date,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  }) {
    return _repository.getDailyActivityFeed(
      classroomCode: classroomCode,
      date: date,
      studentCode: studentCode,
      classroomCodes: classroomCodes,
      studentCodes: studentCodes,
      activityTypeCodes: activityTypeCodes,
      approvalStatuses: approvalStatuses,
      guardianPersona: guardianPersona,
      page: page,
      size: size,
    );
  }
}
