/// The four headings the Choose Activity grid groups its tiles under (8g).
///
/// This is the activity type's own `category`, which the API already returns
/// on `GET /activity-types`; nothing here is invented.
enum ActivityCategory {
  dailyCare('Daily care'),
  health('Health'),
  learningAndPlay('Learning and play'),
  moments('Moments');

  const ActivityCategory(this.label);

  final String label;
}

/// Every activity type the app ships, in Choose Activity order (8g).
///
/// [slug] is the path segment `/activities/new/<slug>` uses, so a form is a
/// real route rather than a pushed widget. [iconAsset] is the same PNG the
/// shipped app draws; the design's own frames reference these files.
enum ActivityKind {
  nap('Nap', 'nap', ActivityCategory.dailyCare, 'nap-activity-icon.png'),
  bathroom(
    'Bathroom',
    'bathroom',
    ActivityCategory.dailyCare,
    'bathroom-activity-icon.png',
  ),
  bottle(
    'Bottle',
    'bottle',
    ActivityCategory.dailyCare,
    'bottle-activity-icon.png',
  ),
  meal('Meal', 'meal', ActivityCategory.dailyCare, 'meal-activity-icon.png'),
  incident(
    'Incident',
    'incident',
    ActivityCategory.health,
    'incident-activity-icon.png',
  ),
  medication(
    'Medication',
    'medication',
    ActivityCategory.health,
    'medication-activity-icon.png',
  ),
  learning(
    'Learning',
    'learning',
    ActivityCategory.learningAndPlay,
    'learning-activity-icon.png',
  ),
  outdoor(
    'Outdoor',
    'outdoor',
    ActivityCategory.learningAndPlay,
    'outdoor-activity-icon.png',
  ),
  photo(
    'Photo',
    'photo',
    ActivityCategory.moments,
    'photo-video-activity-icon.png',
  ),
  video(
    'Video',
    'video',
    ActivityCategory.moments,
    'photo-video-activity-icon.png',
  ),
  notes('Notes', 'notes', ActivityCategory.moments, 'notes-activity-icon.png');

  const ActivityKind(this.label, this.slug, this.category, this._icon);

  final String label;
  final String slug;
  final ActivityCategory category;
  final String _icon;

  static const String _iconDir = 'assets/icons';

  String get iconAsset => '$_iconDir/$_icon';

  /// The one type that reads red on the feed rail rather than teal: an
  /// incident is the card a director looks for first.
  bool get isUrgent => this == ActivityKind.incident;

  /// Only ever about one student. The grid switches it off for a multiple
  /// selection and says why (8g).
  bool get isSingleStudentOnly => this == ActivityKind.incident;

  /// A nap can only be logged for students who are all napping or all not,
  /// because the form closes one nap for the whole selection (8g).
  bool get needsUniformNapState => this == ActivityKind.nap;

  /// Health types are the two the school always sends for a signature.
  bool get alwaysNeedsApproval =>
      this == ActivityKind.incident || this == ActivityKind.medication;

  /// Which types carry an attachment tray, and how many files they take.
  /// `maxAttachments` is on the activity type already.
  int get maxAttachments => switch (this) {
    ActivityKind.video => 1,
    ActivityKind.photo ||
    ActivityKind.notes ||
    ActivityKind.outdoor ||
    ActivityKind.learning ||
    ActivityKind.incident => 5,
    _ => 0,
  };

  bool get hasAttachments => maxAttachments > 0;

  static ActivityKind? fromSlug(String slug) {
    for (final kind in ActivityKind.values) {
      if (kind.slug == slug) return kind;
    }
    return null;
  }

  static ActivityKind? fromLabel(String label) {
    final wanted = label.trim().toLowerCase();
    for (final kind in ActivityKind.values) {
      if (kind.label.toLowerCase() == wanted) return kind;
    }
    return null;
  }
}
