import 'package:flutter/material.dart';

import '../entities/classroom_forecast_block.dart';
import '../repositories/staff_shift_repository.dart';

class GetClassroomForecastUseCase {
  const GetClassroomForecastUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<List<ClassroomForecastBlock>> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int durationMinutes,
    required List<String> classroomCodes,
  }) {
    return _repository.getClassroomForecast(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      query: ClassroomForecastQuery(
        date: date,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        classroomCodes: classroomCodes,
      ),
    );
  }
}
