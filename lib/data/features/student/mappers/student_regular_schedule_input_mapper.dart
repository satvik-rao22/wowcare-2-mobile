import '../../../../domain/features/student/entities/student_regular_schedule_input.dart';

/// Shapes a [StudentRegularScheduleInput] into the exact regular-schedule PATCH
/// entry the view used to build inline (`dayOfWeek`/`startTime`/`halfDay`/
/// `endTime`). Keeps payload shaping in the data layer.
Map<String, dynamic> studentRegularScheduleInputToPayload(
  StudentRegularScheduleInput entry,
) {
  return <String, dynamic>{
    'dayOfWeek': entry.dayOfWeek,
    'startTime': entry.startTime,
    'halfDay': entry.halfDay,
    'endTime': entry.endTime,
  };
}
