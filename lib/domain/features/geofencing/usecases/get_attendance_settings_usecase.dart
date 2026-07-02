import '../entities/attendance_settings_entity.dart';
import '../repositories/geofencing_repository.dart';

class GetAttendanceSettingsUseCase {
  const GetAttendanceSettingsUseCase(this._repository);
  final GeofencingRepository _repository;

  Future<AttendanceSettingsEntity> call({required String schoolCode}) =>
      _repository.getAttendanceSettings(schoolCode: schoolCode);
}
