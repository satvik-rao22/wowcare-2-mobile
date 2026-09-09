import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_context_helper.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// Resolves the active school name for a report request.
///
/// Returns `null` — after showing the standard error — when it cannot be
/// resolved; callers treat that exactly like any other validation failure and
/// abort the generate call.
///
/// This block was duplicated verbatim in ten report forms (§6.1): the same
/// lookup, the same debug line, the same `null || isEmpty` guard, the same
/// snackbar. Because every caller aborts on empty, a non-null result is always
/// non-empty — which is why the request payloads can pass it straight through.
Future<String?> resolveSchoolNameOrWarn(BuildContext context) async {
  final schoolName = await SchoolContextHelper.getSchoolName();
  AppLogger.d('resolvedSchoolName=$schoolName');

  if (schoolName == null || schoolName.isEmpty) {
    if (!context.mounted) return null;
    CoreUtils.showTopSnackBar(
      context: context,
      message: ReportsStrings.unableToResolveSchoolName,
      isError: true,
    );
    return null;
  }
  return schoolName;
}
