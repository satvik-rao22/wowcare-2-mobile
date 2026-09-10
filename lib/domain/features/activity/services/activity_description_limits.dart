/// Shared limits for free-text activity description fields across create/edit
/// flows.
///
/// The limit is a domain validation rule, so it lives here rather than in
/// presentation. The message is kept alongside it, derived from [maxLength],
/// rather than moved to `AppStrings`: `AppStrings` is in `core`, so it cannot
/// reference this constant without inverting the dependency rule, and copying
/// `500` into the string by hand lets the number and the copy drift apart the
/// first time the limit changes.
class ActivityDescriptionLimits {
  ActivityDescriptionLimits._();

  static const int maxLength = 500;

  static String get maxLengthMessage =>
      'Must be $maxLength characters or fewer.';
}
