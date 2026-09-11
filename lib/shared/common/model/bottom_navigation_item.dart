/// Semantic identifier for a bottom-navigation slot — replaces the old raw
/// integer tab index. `classrooms` only ever appears for staff/admin personas;
/// `billing` only ever appears for the parent persona (see
/// [BottomNavigationCubit] for the per-persona gating).
enum BottomNavigationItem {
  dashboard,
  attendance,
  classrooms,
  activities,
  communication,
  billing,
}
