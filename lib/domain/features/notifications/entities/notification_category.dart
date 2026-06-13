/// Categories a notification-center item can belong to.
///
/// The set is intentionally fixed (matching the design: Availability / Staff /
/// Student). Each value carries a human [label] and the backend [apiValue] so
/// the data layer can map server payloads onto this enum without leaking raw
/// strings into the presentation layer.
///
/// Colour mapping is deliberately NOT defined here — that belongs to the
/// presentation layer (see the notification card widget), keeping the domain
/// free of any Flutter/UI dependency.
enum NotificationCategory {
  availability('Availability', 'AVAILABILITY'),
  staff('Staff', 'STAFF'),
  student('Student', 'STUDENT');

  const NotificationCategory(this.label, this.apiValue);

  final String label;
  final String apiValue;

  /// Maps a backend value (case-insensitive) onto a category, defaulting to
  /// [NotificationCategory.staff] when unknown so an item never disappears.
  static NotificationCategory fromApi(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final category in NotificationCategory.values) {
      if (category.apiValue == normalized ||
          category.label.toUpperCase() == normalized) {
        return category;
      }
    }
    return NotificationCategory.staff;
  }
}
