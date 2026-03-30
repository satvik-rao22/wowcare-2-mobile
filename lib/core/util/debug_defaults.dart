/// Temporary hardcoded values used while bypassing login/selection flows.
///
/// IMPORTANT: Remove/revert this file once normal login + school selection is restored.
class DebugDefaults {
  DebugDefaults._();

  /// Temporary schoolCode used for API calls while login is bypassed.
  static const String schoolCode = 'SCH_5317481E-5';

  /// Temporary organizationCode used for API calls while login is bypassed.
  /// Only used as a last-resort fallback (e.g., during local dev without login).
  static const String organizationCode = 'ORG_ED603065-6';
}

