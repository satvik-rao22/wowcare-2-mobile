/// Where a staff member stands on the school's books, which is the "Status ·
/// pick one" row of the 6b filter sheet.
///
/// Mirrors `StaffMember.status` on the existing entity, whose server values
/// are `ACTIVE`, `UPCOMING` and `INACTIVE`.
enum StaffStatus {
  /// On the books and working now.
  active,

  /// Hired, with a start date that has not arrived (6a "Starting soon").
  upcoming,

  /// Deactivated. Kept on file, and reactivatable (6f).
  inactive,
}
