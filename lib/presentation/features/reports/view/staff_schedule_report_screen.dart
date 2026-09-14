import 'dart:async';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/form_classrooms_field.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_scheduling_report_params.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/resolve_school_name.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class StaffScheduleReportScreen extends StatefulWidget {
  const StaffScheduleReportScreen({super.key, required this.classrooms});

  static const String routeName = '/reports/staff/schedule';

  final List<String> classrooms;

  @override
  State<StaffScheduleReportScreen> createState() =>
      _StaffScheduleReportScreenState();
}

class _StaffScheduleReportScreenState extends State<StaffScheduleReportScreen> {
  late final ValueNotifier<DateTime> _startDate;
  late final ValueNotifier<DateTime> _endDate;
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = ValueNotifier<DateTime>(now);
    _endDate = ValueNotifier<DateTime>(now.add(const Duration(days: 6)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Staff reports need the wider list that also contains Office and
        // primary rooms (onlyTypeClassroom: false).
        context.read<ReportsCubit>().loadFormClassrooms(
          includeNonClassroomTypes: true,
        );
      }
    });
  }

  Future<void> _onGenerate() async {
    AppLogger.d('[STAFF-SCHEDULE-UI] Generate button tapped');

    if (_endDate.value.isBefore(_startDate.value)) {
      AppLogger.w(
        '[STAFF-SCHEDULE-UI] Generation blocked: End date before Start date',
      );
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.endDateCannotBeBeforeStartDate,
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final nameToCode = cubit.state.allClassroomNameToCode.isNotEmpty
        ? cubit.state.allClassroomNameToCode
        : cubit.state.classroomNameToCode;
    // Empty selection → no codes → `classroomCodes: null` below omits the
    // key, which is how this endpoint expresses "all classrooms".
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value,
      nameToCode: nameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    AppLogger.d(
      '[STAFF-SCHEDULE-UI] Selected classrooms: $_selectedClassrooms',
    );
    AppLogger.d('[STAFF-SCHEDULE-UI] Resolved classroomCodes: $classroomCodes');

    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;
    final params = StaffSchedulingReportParams(
      reportType: ReportType.staffScheduling,
      startDate: _startDate.value,
      endDate: _endDate.value,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      format: _format.value,
      schoolName: schoolName,
    );

    AppLogger.d('[STAFF-SCHEDULE-UI] Calling cubit.generateReport()');
    unawaited(cubit.generateReport(params));
  }

  @override
  void dispose() {
    _endDate.dispose();
    _format.dispose();
    _selectedClassrooms.dispose();
    _startDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Drop selections that no longer exist when a refreshed classroom
        // list arrives. Never re-expands to "all" — an empty filter already
        // means every classroom.
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.allClassroomNames != current.allClassroomNames,
          listener: (context, state) {
            _selectedClassrooms.value = _selectedClassrooms.value
                .where(state.allClassroomNames.contains)
                .toList();
          },
        ),
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.generationError != current.generationError,
          listener: (context, state) {
            if (state.generationError != null &&
                state.generationError!.isNotEmpty) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: state.generationError!,
                isError: true,
              );
            }
          },
        ),
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.generationSuccess != current.generationSuccess,
          listener: (context, state) {
            if (state.generationSuccess != null &&
                state.generationSuccess!.isNotEmpty) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: ReportsStrings.reportGeneratedSuccessfully,
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  context.read<ReportsCubit>().clearGeneratedReport();
                  if (context.canPop()) {
                    context.pop(const ReportGeneratedRefreshList());
                  }
                });
              }
            }
          },
        ),
      ],
      child: ReportFormLayout(
        title: ReportsStrings.staffSchedulingName,
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportFieldLabel(label: ReportsStrings.startDate),
            ValueListenableBuilder<DateTime>(
              valueListenable: _startDate,
              builder: (_, v, __) => CustomDateTimeField(
                hasLabel: false,
                dateFormat: 'MM/dd/yyyy',
                fetchInitialTime: false,
                initialDate: v,
                onDateSelected: (d) => _startDate.value = d,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            const ReportFieldLabel(label: ReportsStrings.endDate),
            ValueListenableBuilder<DateTime>(
              valueListenable: _endDate,
              builder: (_, v, __) => CustomDateTimeField(
                hasLabel: false,
                dateFormat: 'MM/dd/yyyy',
                fetchInitialTime: false,
                initialDate: v,
                onDateSelected: (d) => _endDate.value = d,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            FormClassroomsField(
              includeNonClassroomTypes: true,
              child: BlocSelector<ReportsCubit, ReportsState, List<String>>(
                selector: (state) => state.allClassroomNames.isNotEmpty
                    ? state.allClassroomNames
                    : widget.classrooms,
                builder: (context, classroomItems) =>
                    ValueListenableBuilder<List<String>>(
                      valueListenable: _selectedClassrooms,
                      builder: (_, v, __) => CustomMultiSelectDropdown(
                        label: ReportsStrings.classroom,
                        hintText: ReportsStrings.allClassrooms,
                        items: classroomItems,
                        selectedItems: v,
                        onChanged: (s) => _selectedClassrooms.value = s,
                        showSelectAll: true,
                      ),
                    ),
              ),
            ),
            const ReportDefaultNote(
              text: ReportsStrings.noteAllClassroomsIncludedByDefault,
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            const ReportFieldLabel(label: ReportsStrings.exportFormat),
            ValueListenableBuilder<String>(
              valueListenable: _format,
              builder: (_, v, __) => ReportFormatSelector(
                selectedFormat: v,
                onFormatChanged: (value) => _format.value = value,
                showLabel: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
