/// Centralized user-visible string literals.
///
/// Seeded with the scheduling feature's copy as it moves off inline
/// literals in view files. Other features keep their inline strings until
/// they migrate too — this file grows feature by feature, not all at once.
abstract final class AppStrings {
  // Populated per-feature during migration. Scheduling's entries land here
  // in the theming pass (Mandate 4).
}
