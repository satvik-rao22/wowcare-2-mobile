import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_context_helper.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';

/// The generate flow shared by every "date range + classroom + format" report
/// form (§6.3).
///
/// Each of those screens carried its own copy of: validate the range, resolve
/// the selected classroom names to codes, resolve the school name, build a
/// [ReportRequestParams] and hand it to the cubit. The bodies were identical
/// apart from three things, which are the parameters here — the report type,
/// which classroom name→code map to resolve against, and the log tag.
///
/// The resulting payload is byte-identical to what each screen built inline:
/// same keys, same order-independent values, same null handling. In
/// particular `schoolName` is passed straight through, because every caller
/// already returns early when it is null or empty — so the old
/// `schoolName.isNotEmpty ? schoolName : null` could never yield null.
Future<void> submitClassroomRangeReport({
  required BuildContext context,
  required ReportType reportType,
  required DateTime fromDate,
  required DateTime toDate,
  required String format,
  required List<String> selectedClassrooms,
  required String logTag,

  /// True for the staff reports, which offer the wider `onlyTypeClassroom:
  /// false` list (Office and primary rooms included) and must therefore
  /// resolve against [ReportsState.allClassroomNameToCode].
  bool useWiderClassroomSet = false,
}) async {
  AppLogger.d('[$logTag] Generate button tapped');

  if (toDate.isBefore(fromDate)) {
    AppLogger.w('[$logTag] Generation blocked: To date before From date');
    CoreUtils.showTopSnackBar(
      context: context,
      message: ReportsStrings.toDateBeforeFromDate,
      isError: true,
    );
    return;
  }

  final cubit = context.read<ReportsCubit>();
  final state = cubit.state;
  final nameToCode =
      useWiderClassroomSet && state.allClassroomNameToCode.isNotEmpty
      ? state.allClassroomNameToCode
      : state.classroomNameToCode;

  // An empty selection means "all classrooms": it resolves to no codes, and
  // `roomCodes: null` below omits the key so the backend returns every room.
  // Substituting the full classroom list here would send an implicit filter
  // the user never chose.
  final classroomCodes = resolveReportCodes(
    context: context,
    names: selectedClassrooms,
    nameToCode: nameToCode,
    labelPlural: ReportsStrings.classroomsLabelPlural,
  );
  if (classroomCodes == null) return;

  AppLogger.d('[$logTag] Selected classrooms: $selectedClassrooms');
  AppLogger.d('[$logTag] Resolved roomCodes: $classroomCodes');

  final schoolName = await SchoolContextHelper.getSchoolName();
  AppLogger.d('resolvedSchoolName=$schoolName');
  if (schoolName == null || schoolName.isEmpty) {
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: ReportsStrings.unableToResolveSchoolName,
      isError: true,
    );
    return;
  }

  final params = ReportRequestParams(
    reportType: reportType,
    startDate: fromDate,
    endDate: toDate,
    format: format,
    roomCodes: classroomCodes.isEmpty ? null : classroomCodes,
    schoolName: schoolName,
  );

  AppLogger.d('[$logTag] Calling cubit.generateReport()');
  unawaited(cubit.generateReport(params));
}
