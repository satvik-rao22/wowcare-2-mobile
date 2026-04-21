/// Shared limits for free-text activity description fields across create/edit flows.
class ActivityDescriptionLimits {
  ActivityDescriptionLimits._();

  static const int maxLength = 500;

  static String get maxLengthMessage =>
      'Must be $maxLength characters or fewer.';
}
