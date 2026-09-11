/// Outcome of resolving display names to backend codes.
class ReportCodeResolution {
  const ReportCodeResolution({required this.codes, required this.unresolved});

  /// Codes for the names that resolved, in input order.
  final List<String> codes;

  /// Names that had no usable code. Non-empty means the caller must abort.
  final List<String> unresolved;

  bool get isComplete => unresolved.isEmpty;
}

/// Resolves report filter selections (classrooms, students, staff, tags) from
/// their display names to the backend codes a report request needs.
///
/// Every report form previously did this inline as
/// `names.map((n) => nameToCode[n] ?? n).toList()` — whenever the lookup
/// missed (e.g. the multi-select's frozen `widget.students` list drifting
/// out of sync with `ReportsCubit.state.studentNameToCode`, re-read live at
/// submit time), that `?? n` fallback silently sent the raw DISPLAY NAME to
/// the backend as if it were a real code (e.g. `"studentCodes":
/// ["Avira Jadhav"]` instead of `["STD_4C7A90DD"]`), which the backend
/// can't resolve — surfacing only as an opaque 500 with no indication of
/// what actually went wrong.
///
/// This is the rule on its own, with no Flutter dependency and no UI. The
/// presentation-side `resolveReportCodes` helper wraps it and reports
/// [ReportCodeResolution.unresolved] to the user.
class ResolveReportCodesUseCase {
  const ResolveReportCodesUseCase();

  ReportCodeResolution call({
    required List<String> names,
    required Map<String, String> nameToCode,
  }) {
    if (names.isEmpty) {
      return const ReportCodeResolution(
        codes: <String>[],
        unresolved: <String>[],
      );
    }

    final codes = <String>[];
    final unresolved = <String>[];
    for (final name in names) {
      final code = nameToCode[name];
      if (code == null || code.isEmpty) {
        unresolved.add(name);
      } else {
        codes.add(code);
      }
    }
    return ReportCodeResolution(codes: codes, unresolved: unresolved);
  }
}
