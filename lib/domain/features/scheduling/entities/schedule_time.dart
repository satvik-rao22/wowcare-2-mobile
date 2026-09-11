/// A wall-clock time of day (hour + minute), independent of any date or zone.
///
/// The domain equivalent of Flutter's `TimeOfDay`. School opening hours and
/// monitoring windows are schedule facts, so the types that carry them must not
/// drag the Flutter SDK into the domain layer — `SchoolHoursResolver` modelled
/// them as `TimeOfDay`, which is what kept it stuck in presentation.
///
/// Convert at the UI boundary with `toTimeOfDay()` / `toScheduleTime()` from
/// `core/extensions/schedule_time_ext.dart`.
class ScheduleTime implements Comparable<ScheduleTime> {
  const ScheduleTime({required this.hour, required this.minute});

  /// Builds from a whole-day minute offset, clamped to a valid 24h time.
  factory ScheduleTime.fromMinutesOfDay(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60 - 1);
    return ScheduleTime(hour: clamped ~/ 60, minute: clamped % 60);
  }

  /// 0–23.
  final int hour;

  /// 0–59.
  final int minute;

  /// Minutes since midnight — the form most scheduling maths wants.
  int get minutesOfDay => hour * 60 + minute;

  @override
  int compareTo(ScheduleTime other) =>
      minutesOfDay.compareTo(other.minutesOfDay);

  bool operator <(ScheduleTime other) => minutesOfDay < other.minutesOfDay;
  bool operator <=(ScheduleTime other) => minutesOfDay <= other.minutesOfDay;
  bool operator >(ScheduleTime other) => minutesOfDay > other.minutesOfDay;
  bool operator >=(ScheduleTime other) => minutesOfDay >= other.minutesOfDay;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleTime &&
          other.hour == hour &&
          other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
