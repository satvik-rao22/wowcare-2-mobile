/// Report filters (classroom / student / staff multi-selects) open with every
/// option selected — "All Classrooms", "All Students" — and stay that way,
/// including while the option list is still being fetched, until the user
/// edits that particular filter.
///
/// Once the user has edited a filter, their selection is authoritative: it is
/// never silently re-expanded back to "All", not on a later option-list
/// refresh, not after changing dates, format, or generating a report. The only
/// adjustment applied afterwards is dropping options that no longer exist
/// (e.g. students of a classroom that was just deselected), which is the
/// pre-existing dependency behaviour.
class ReportFilterDefault {
  bool _isUserEdited = false;

  /// Whether the user has explicitly changed this filter at least once.
  bool get isUserEdited => _isUserEdited;

  /// Records an explicit user selection and returns it, so call sites can read
  /// as `_selected = _classroomFilter.userSelected(values)`.
  List<String> userSelected(List<String> selection) {
    _isUserEdited = true;
    return List<String>.from(selection);
  }

  /// The selection to apply now that [options] are known.
  ///
  /// Untouched filter → all of [options] ("All ... Selected"). User-edited
  /// filter → [current], minus anything that is no longer available.
  List<String> resolve({
    required List<String> options,
    required List<String> current,
  }) {
    if (!_isUserEdited) return List<String>.from(options);
    return current.where(options.contains).toList();
  }
}
