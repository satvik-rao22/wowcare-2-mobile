/// One day's work/break schedule entry, used to build the edit-schedule
/// screen's initial form state from a staff member's current schedule.
///
/// A screen-form model, so it lives in `model/` (§3.1) rather than in
/// `widgets/` where it previously sat alongside the chips that render it.
class ScheduleEntry {
  const ScheduleEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isBreakTime,
  });

  final String day; // e.g. 'monday'
  final String startTime; // e.g. '09:00 AM'
  final String endTime; // e.g. '05:00 PM'
  final bool isBreakTime;
}
