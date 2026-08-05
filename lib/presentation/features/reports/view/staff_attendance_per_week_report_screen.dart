import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/utils/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../core/util/school_context_helper.dart';

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

  String _frequency = 'Monthly';
  late DateTime _periodMonth;
  List<String> _selectedStaff = <String>[];
  List<String> _selectedClassrooms = <String>[];
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _periodMonth = DateTime(now.year, now.month, 1);
  }

  void _onGenerate() async {
    AppLogger.d('[STAFF-ATTENDANCE-WEEKLY-UI] Generate button tapped');

    if (!_validateInputs()) {
      AppLogger.w(
        '[STAFF-ATTENDANCE-WEEKLY-UI] Generation blocked by validation',
      );
      return;
    }

    AppLogger.d('[STAFF-ATTENDANCE-WEEKLY-UI] Creating report params');
    final cubit = context.read<ReportsCubit>();
    final reportsState = cubit.state;

    // Convert staff names to codes
    final staffCodes = resolveReportCodes(
      context: context,
      names: _selectedStaff,
      nameToCode: reportsState.staffNameToCode,
      labelPlural: 'staff',
    );
    if (staffCodes == null) return;
    // Retrieve the school name from storage
    final schoolName = await SchoolContextHelper.getSchoolName();
    AppLogger.d('resolvedSchoolName=$schoolName');
    if (schoolName == null || schoolName.isEmpty) {
      if (!mounted) return;

      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to resolve school name',
        isError: true,
      );
      return;
    }
    // Convert classroom names to codes
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms,
      nameToCode: reportsState.classroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    final params = ReportRequestParams(
      reportType: ReportType.staffAttendancePerStaff,
      startDate: _periodMonth,
      endDate: _periodMonth.add(const Duration(days: 30)),
      staffCodes: staffCodes,
      classroomCodes: classroomCodes,
      format: _format,
      schoolName: schoolName,
    );
    AppLogger.d('[STAFF-ATTENDANCE-WEEKLY-UI] Calling cubit.generateReport()');
    cubit.generateReport(params);
  }

  bool _validateInputs() {
    if (_selectedStaff.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one staff member',
        isError: true,
      );
      return false;
    }
    return true;
  }

  TextStyle _labelStyle(ResponsiveHelper r) => TextStyle(
    fontSize: r.labelFontSize,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w400,
    color: const Color(0xff573353),
  );

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return MultiBlocListener(
      listeners: [
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
                message: 'Report generated successfully',
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // This screen was pushed via a plain Navigator.push (see
                  // ReportsScreen._openStaffReportForm), not a go_router
                  // route — context.go() alone updates the hub's route
                  // state but never dismisses this screen, so the user
                  // never actually sees the tab switch. Popping (with a
                  // `true` result) is what the hub's own
                  // `.then((success) => _tabController.animateTo(0))`
                  // callback is already waiting for.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  Navigator.of(context).pop(true);
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
            title: 'Attendance Per Staff',
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
                        label: 'Frequency',
                        hintText: 'Select',
                        items: _frequencyOptions,
                        selectedItem: _frequency,
                        labelStyle: _labelStyle(responsive),
                        showAsterisk: true,
                        labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                        onSelect: (val) {
                          if (val == null) return;
                          setState(() => _frequency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ReportFieldLabel(label: 'Period'),
                          ReportMonthYearField(
                            initialMonth: _periodMonth,
                            onMonthSelected: (d) =>
                                setState(() => _periodMonth = d),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.verticalSpacing),
                MultiSelectFilterField<String>(
                  label: 'Staff',
                  hintText: 'Select Staff Members',
                  items: widget.staff,
                  selectedItems: _selectedStaff,
                  onChanged: (s) => setState(() => _selectedStaff = s),
                  itemToString: (item) => item,
                  singularLabel: 'Staff Member',
                  pluralLabel: 'Staff Members',
                  showSelectAll: true,
                  enableSearch: true,
                  searchHintText: 'Search Staff',
                ),
                SizedBox(height: responsive.verticalSpacing),
                CustomMultiSelectDropdown(
                  label: 'Classroom',
                  hintText: 'Select Classroom',
                  items: widget.classrooms,
                  selectedItems: _selectedClassrooms,
                  onChanged: (s) => setState(() => _selectedClassrooms = s),
                  showSelectAll: true,
                ),
                const ReportDefaultNote(
                  text: 'Note: All Classrooms will be selected by Default.',
                ),
                SizedBox(height: responsive.verticalSpacing),
                const ReportFieldLabel(label: 'Export Format'),
                ReportFormatSelector(
                  selectedFormat: _format,
                  onFormatChanged: (value) => setState(() => _format = value),
                  showLabel: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
