/// Reads the active school's identifiers from local storage.
///
/// Exists so the reports cubit can resolve the school code/name without
/// naming `StorageService`, which §5.3 forbids anywhere under
/// `lib/presentation`.
///
/// NOTE: school context is app-wide, not reports-specific. It lives under
/// `features/reports` because the reports module is the first to need it
/// behind a contract; move it to a shared feature the moment a second module
/// does, rather than declaring a second interface for the same thing (§6.5).
abstract class SchoolContextRepository {
  /// The active school code, trimmed. Empty string when unset.
  Future<String> getSchoolCode();

  /// The active school name, trimmed. Empty string when unset.
  Future<String> getSchoolName();
}
