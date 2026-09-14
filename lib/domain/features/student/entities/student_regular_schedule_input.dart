import 'package:equatable/equatable.dart';

/// Typed request entry for updating a student's regular schedule, replacing the
/// raw `Map<String, dynamic>` entries the repository contract used to take. One
/// working day, with times pre-formatted as the backend `HH:mm:ss` local-time
/// strings. Distinct from the READ model [StudentRegularScheduleEntry] (which
/// carries hour/minute ints). Pure domain — payload shaping lives in
/// `data/features/student/mappers/student_regular_schedule_input_mapper.dart`.
class StudentRegularScheduleInput extends Equatable {
  const StudentRegularScheduleInput({
    required this.dayOfWeek,
    required this.startTime,
    required this.halfDay,
    required this.endTime,
  });

  /// e.g. `MONDAY`.
  final String dayOfWeek;

  /// `HH:mm:ss`.
  final String startTime;

  /// `HH:mm:ss` — the half-day cutoff.
  final String halfDay;

  /// `HH:mm:ss`.
  final String endTime;

  @override
  List<Object?> get props => [dayOfWeek, startTime, halfDay, endTime];
}
