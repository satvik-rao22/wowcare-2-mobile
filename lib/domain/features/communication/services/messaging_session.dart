/// Read-side session/identity access for the messaging cubits.
///
/// Mandate 5: presentation (cubits included) must not reference `StorageService`
/// directly. This injected domain service is the seam — the cubits depend on it
/// instead of the raw key/value store. Every method returns exactly what the
/// previous `StorageService.getString(StorageKeys.*)` calls returned (same key,
/// same value, same nullability), so moving to it is behaviour-preserving.
abstract class MessagingSession {
  /// The signed-in user's code (`StorageKeys.userCode`).
  Future<String?> userCode();

  /// The active school code (`StorageKeys.schoolCode`).
  Future<String?> schoolCode();

  /// The active organization code (`StorageKeys.organizationCode`).
  Future<String?> organizationCode();

  /// The signed-in staff member's code, if any (`StorageKeys.staffCode`).
  Future<String?> staffCode();

  /// The user's display name (`StorageKeys.displayName`).
  Future<String?> displayName();

  /// The raw stored active-school role (`StorageKeys.activeSchoolRole`).
  Future<String?> activeSchoolRole();

  /// The resolved backend role for the active school — the same single source
  /// of truth `resolveActiveBackendRole(StorageService)` computes.
  Future<String> activeBackendRole();

  // ── Composer draft persistence ─────────────────────────────────────────────
  // A lightweight per-conversation draft, keyed by the caller's own key.

  /// Reads a persisted composer draft for [key].
  Future<String?> readComposerDraft(String key);

  /// Persists a composer draft [text] under [key].
  Future<void> saveComposerDraft(String key, String text);

  /// Clears the persisted composer draft for [key].
  Future<void> removeComposerDraft(String key);
}
