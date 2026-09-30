/// Predicate over a lower-cased `activityTypeName` coming from
/// `GET /classrooms/{code}/activity-settings`. Used to resolve which activity
/// type code a note-style form should submit against.
typedef ActivityTypeNameMatcher = bool Function(String normalizedName);

/// Notes and Observation are the same form: student tiles, date, time, staff
/// present, description and optional photos. Everything that differs between
/// them lives here, so [NoteStyleActivityScreen] stays a single implementation.
///
/// To add a third note-style activity: add a constant here, then register its
/// [uiKey] in `ChooseActivity.activityIcons` / `activityRoutes` and in the two
/// feed tabs' icon and route maps.
class NoteStyleActivityConfig {
  const NoteStyleActivityConfig({
    required this.uiKey,
    required this.title,
    required this.matchesActivityTypeName,
  });

  /// UI key shared by the icon and route maps. Must equal the API's
  /// `activityTypeName` (case-insensitively) or no tile renders, and must be
  /// what `mapApiActivityTypeNameToUiLabel` returns or the feed card cannot be
  /// opened.
  final String uiKey;

  /// Form app-bar title, also used in "unable to determine activity type"
  /// messages.
  final String title;

  /// Resolves this form's activity type out of the classroom activity
  /// settings list.
  final ActivityTypeNameMatcher matchesActivityTypeName;

  static const NoteStyleActivityConfig notes = NoteStyleActivityConfig(
    uiKey: 'Notes',
    title: 'Notes',
    matchesActivityTypeName: matchesNotesTypeName,
  );

  static const NoteStyleActivityConfig observation = NoteStyleActivityConfig(
    uiKey: 'Observation',
    title: 'Observation',
    matchesActivityTypeName: matchesObservationTypeName,
  );
}

/// Kept as a substring match so existing schools whose type is named "Note",
/// "Notes" or "Daily Notes" keep resolving, while explicitly refusing an
/// Observation type that happens to carry "note" in its name.
bool matchesNotesTypeName(String normalizedName) =>
    normalizedName.contains('note') && !normalizedName.contains('observation');

bool matchesObservationTypeName(String normalizedName) =>
    normalizedName.contains('observation');
