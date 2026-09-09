import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/form_classrooms_field.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/widgets/resolve_school_name.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class StaffAttendancePerWeekReportScreen extends StatefulWidget {
  const StaffAttendancePerWeekReportScreen({
    super.key,
    required this.staff,
    required this.classrooms,
  });

  static const String routeName = '/reports/staff/attendance-per-week';

  final List<String> staff;
  final List<String> classrooms;

  @override
  State<StaffAttendancePerWeekReportScreen> createState() =>
      _StaffAttendancePerWeekReportScreenState();
}

class _StaffAttendancePerWeekReportScreenState
    extends State<StaffAttendancePerWeekReportScreen> {
  static const List<String> _frequencyOptions = <String>[
    'Daily',
    'Weekly',
    'Monthly',
  ];

  final ValueNotifier<String> _frequency = ValueNotifier<String>('Monthly');
  late final ValueNotifier<DateTime> _periodMonth;
  final ValueNotifier<List<String>> _selectedStaff =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  List<String> _getAvailableStaff(BuildContext context) {
    final cubitStaff = context.watch<ReportsCubit>().state.staffNames;
    if (cubitStaff.isNotEmpty) return cubitStaff;
    return widget.staff;
  }

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _periodMonth = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));

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

  void _onGenerate() async {
    AppLogger.d('[STAFF-ATTENDANCE-WEEKLY-UI] Generate button tapped');

    AppLogger.d('[STAFF-ATTENDANCE-WEEKLY-UI] Creating report params');
    final cubit = context.read<ReportsCubit>();
    final reportsState = cubit.state;

    // Convert staff names to codes
    final staffCodes = resolveReportCodes(
      context: context,
      names: _selectedStaff.value,
      nameToCode: reportsState.staffNameToCode,
      labelPlural: 'staff',
    );
    if (staffCodes == null) return;
    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;
    // Convert classroom names to codes
    final nameToCode = reportsState.allClassroomNameToCode.isNotEmpty
        ? reportsState.allClassroomNameToCode
        : reportsState.classroomNameToCode;
    // Empty selection → no codes → the key is omitted below, which is how
    // this endpoint expresses "all classrooms" / "all staff".
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value,
      nameToCode: nameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    final params = ReportRequestParams(
      reportType: ReportType.staffAttendancePerStaff,
      startDate: _periodMonth.value,
      endDate: _periodMonth.value.add(const Duration(days: 30)),
      staffCodes: staffCodes.isEmpty ? null : staffCodes,
      roomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      format: _format.value,
      schoolName: schoolName,
    );
    AppLogger.d('[STAFF-ATTENDANCE-WEEKLY-UI] Calling cubit.generateReport()');
    cubit.generateReport(params);
  }

  TextStyle _labelStyle(BuildContext context) =>
      AppTextStyles.reportsFieldLabel(
        fontSize: context.responsive(compact: 14.0, medium: 16.0),
      );

  @override
  void dispose() {
    _format.dispose();
    _frequency.dispose();
    _periodMonth.dispose();
    _selectedClassrooms.dispose();
    _selectedStaff.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableStaff = _getAvailableStaff(context);

    return MultiBlocListener(
      listeners: [
        // Drop selections that no longer exist when a refreshed list
        // arrives. Neither filter ever re-expands to "all" — an empty filter
        // already means every classroom / every staff member.
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
              previous.staffNames != current.staffNames,
          listener: (context, state) {
            _selectedStaff.value = _selectedStaff.value
                .where(state.staffNames.contains)
                .toList();
          },
        ),
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.generationError != current.generationError,
          listener: (context, state) {
            if (state.generationError != null &&
                state.generationError!.isNotEmpty) {
              AppLogger.e('[REPORT_GENERATION_ERROR] ${state.generationError}');
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
                state.generationSuccess!.isNotEmpty &&
                state.generatedReport != null) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: ReportsStrings.reportGeneratedSuccessfully,
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // Hand the hub a typed result. The report is generated
                  // but the file is not attached, so the hub animates to the
                  // Generated tab -- the outcome pop(true) used to encode.
                  // Still a pop, not context.go(): go() would update the
                  // hub's route state without dismissing this screen, so the
                  // user would never see the tab switch.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  context.pop(const ReportGeneratedRefreshList());
                });
              }
            }
          },
        ),
      ],
      child: BlocSelector<ReportsCubit, ReportsState, bool>(
        selector: (state) => state.isGenerating,
        builder: (context, isGenerating) {
          return ReportFormLayout(
            title: ReportsStrings.staffAttendancePerStaffName,
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CustomDropdown(
                        label: ReportsStrings.frequency,
                        hintText: ReportsStrings.select,
                        items: _frequencyOptions,
                        selectedItem: _frequency.value,
                        labelStyle: _labelStyle(context),
                        showAsterisk: true,
                        labelBottomSpacing: context.isTablet ? 8.0 : 6.0,
                        onSelect: (val) {
                          if (val == null) return;
                          _frequency.value = val;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ReportFieldLabel(label: ReportsStrings.period),
                          ValueListenableBuilder<DateTime>(
                            valueListenable: _periodMonth,
                            builder: (_, v, __) => ReportMonthYearField(
                              initialMonth: v,
                              onMonthSelected: (d) => _periodMonth.value = d,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedStaff,
                  builder: (_, v, __) => MultiSelectFilterField<String>(
                    label: ReportsStrings.tabStaff,
                    hintText: ReportsStrings.allStaffMembers,
                    items: availableStaff,
                    selectedItems: v,
                    onChanged: (s) => _selectedStaff.value = s,
                    itemToString: (item) => item,
                    singularLabel: ReportsStrings.staffMember,
                    pluralLabel: ReportsStrings.staffMembers,
                    showSelectAll: true,
                    enableSearch: true,
                    searchHintText: ReportsStrings.searchStaff,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                FormClassroomsField(
                  includeNonClassroomTypes: true,
                  child: BlocSelector<ReportsCubit, ReportsState, List<String>>(
                    selector: (state) => state.allClassroomNames.isNotEmpty
                        ? state.allClassroomNames
                        : widget.classrooms,
                    builder: (context, classroomItems) =>
                        CustomMultiSelectDropdown(
                          label: ReportsStrings.classroom,
                          hintText: ReportsStrings.allClassrooms,
                          items: classroomItems,
                          selectedItems: _selectedClassrooms.value,
                          onChanged: (s) => _selectedClassrooms.value = s,
                          showSelectAll: true,
                        ),
                  ),
                ),
                const ReportDefaultNote(
                  text: ReportsStrings.noteAllClassroomsIncludedByDefault,
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
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
          );
        },
      ),
    );
  }
}
