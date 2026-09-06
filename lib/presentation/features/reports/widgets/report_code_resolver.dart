import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/usecases/resolve_report_codes_usecase.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// Resolves [names] to their backend codes via [nameToCode], reporting any
/// that could not be resolved to the user.
///
/// The rule itself lives in [ResolveReportCodesUseCase]; this is the thin
/// presentation half that owns the [BuildContext] and the error snackbar, so
/// no Flutter dependency reaches the domain layer (§3.3/§3.5).
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
  const useCase = ResolveReportCodesUseCase();
  final resolution = useCase(names: names, nameToCode: nameToCode);

  if (!resolution.isComplete) {
    CoreUtils.showTopSnackBar(
      context: context,
      message:
          'Could not resolve $labelPlural: '
          '${resolution.unresolved.join(', ')}. '
          '${ReportsStrings.pleaseCloseAndReopenThisFormThenReselectThem}',
      isError: true,
    );
    return null;
  }

  return resolution.codes;
}
