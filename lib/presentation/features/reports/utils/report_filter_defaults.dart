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

/// Returns [fileName] with the extension implied by the chosen export
/// [format] (`PDF` → `.pdf`, anything else → `.xlsx`).
///
/// The synchronous billing endpoints stream the file back and label it
/// `<reportType>_report.xlsx` regardless of the requested format, so a PDF
/// arrived named `.xlsx` — which made the viewer show the Excel placeholder
/// instead of the PDF and made the saved file open with the wrong handler.
String reportFileNameForFormat(String? fileName, String format) {
  final extension = format.trim().toUpperCase() == 'PDF' ? 'pdf' : 'xlsx';
  final name = (fileName ?? '').trim();
  final base = name.isEmpty ? 'report' : name;
  final dotIndex = base.lastIndexOf('.');
  final stem = dotIndex > 0 ? base.substring(0, dotIndex) : base;
  return '$stem.$extension';
}
