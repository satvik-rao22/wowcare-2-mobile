/// Module-level configuration knobs.
class Av2Config {
  const Av2Config._();

  /// Master switch for routing staff attendance detail to the V2 module.
  /// When false, the legacy `StaffAttendanceProfile` screen renders instead
  /// (instant rollback). Non-const so toggling it never dead-codes the legacy
  /// screen.
  static final bool enabled = true;

  /// Daily regular-hours threshold used to split worked time into regular vs
  /// overtime. The backend does not yet return this per school, so we default
  /// to 8h. Replace with the value from `overtimeConfig` once the API exposes
  /// it (see STAFF_OVERTIME_API_REQUIREMENTS.md §5.1).
  static const int defaultDailyRegularMinutes = 480;

  /// Page size for the profile fetch. A staff-month is a small number of
  /// sessions, so we pull them all in one page to group by day client-side.
  static const int profilePageSize = 500;
}
