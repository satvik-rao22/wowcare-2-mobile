import 'package:flutter/material.dart';

import '../entities/classroom_forecast_block.dart';
import '../repositories/staff_shift_repository.dart';

class GetClassroomForecastRangeUseCase {
  const GetClassroomForecastRangeUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<List<ClassroomForecastBlock>> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int durationMinutes,
    required List<String> classroomCodes,
  }) {
    return _repository.getClassroomForecastRange(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      query: ClassroomForecastRangeQuery(
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        classroomCodes: classroomCodes,
      ),
    );
  }
}
