import '../entities/school_regular_schedule_day.dart';
import '../repositories/staff_repository.dart';

class GetSchoolRegularSchedulesUseCase {
  GetSchoolRegularSchedulesUseCase(this._repository);

  final StaffRepository _repository;

  Future<List<SchoolRegularScheduleDay>> call({required String schoolCode}) {
    return _repository.getSchoolRegularSchedules(schoolCode: schoolCode);
  }
}
