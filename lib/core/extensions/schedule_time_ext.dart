import 'package:flutter/material.dart';

import 'package:wowcare/domain/features/scheduling/entities/schedule_time.dart';

/// Conversions between the domain's [ScheduleTime] and Flutter's [TimeOfDay].
///
/// The domain models wall-clock times as [ScheduleTime] so it carries no
/// dependency on the widget library. Presentation converts here, at the
/// boundary — pickers, formatters and layout maths still want [TimeOfDay].
extension ScheduleTimeToTimeOfDay on ScheduleTime {
  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);
}

extension TimeOfDayToScheduleTime on TimeOfDay {
  ScheduleTime toScheduleTime() => ScheduleTime(hour: hour, minute: minute);
}
