import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';

/// Resolves [names] to their backend codes via [nameToCode].
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
/// Returns the resolved codes, or `null` (after showing an error snackbar
/// naming exactly which selections couldn't be resolved) if anything is
/// unresolved — callers should treat `null` the same as any other
/// validation failure and abort the generate call.
List<String>? resolveReportCodes({
  required BuildContext context,
  required List<String> names,
  required Map<String, String> nameToCode,
  required String labelPlural,
}) {
  if (names.isEmpty) return const [];

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

  if (unresolved.isNotEmpty) {
    CoreUtils.showTopSnackBar(
      context: context,
      message:
          'Could not resolve $labelPlural: ${unresolved.join(', ')}. '
          'Please close and reopen this form, then reselect them.',
      isError: true,
    );
    return null;
  }

  return codes;
}
