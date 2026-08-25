import '../entities/ratio_monitoring_classroom.dart';
import '../repositories/classroom_repository.dart';

class GetRatioMonitoringClassroomsUseCase {
  GetRatioMonitoringClassroomsUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<List<RatioMonitoringClassroom>> call({required String schoolCode}) {
    return _repository.getRatioMonitoringClassrooms(schoolCode: schoolCode);
  }
}

class GetStudentAttendanceSummaryByClassroomsUseCase {
  GetStudentAttendanceSummaryByClassroomsUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<Map<String, ClassroomAttendanceSummaryEntry>> call({
    required List<String> classroomCodes,
    DateTime? date,
  }) {
    return _repository.getStudentAttendanceSummaryByClassrooms(
      classroomCodes: classroomCodes,
      date: date,
    );
  }
}

class GetStaffAttendanceSummaryByClassroomsUseCase {
  GetStaffAttendanceSummaryByClassroomsUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<Map<String, ClassroomAttendanceSummaryEntry>> call({
    required List<String> classroomCodes,
    DateTime? date,
  }) {
    return _repository.getStaffAttendanceSummaryByClassrooms(
      classroomCodes: classroomCodes,
      date: date,
    );
  }
}
