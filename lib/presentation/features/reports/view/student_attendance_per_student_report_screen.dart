import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentAttendancePerStudentReportScreen extends StatefulWidget {
  const StudentAttendancePerStudentReportScreen({
    super.key,
    required this.students,
    required this.classrooms,
  });

  static const String routeName = '/reports/student/attendance-per-student';

  final List<String> students;
  final List<String> classrooms;

  @override
  State<StudentAttendancePerStudentReportScreen> createState() =>
      _StudentAttendancePerStudentReportScreenState();
}

class _StudentAttendancePerStudentReportScreenState
    extends State<StudentAttendancePerStudentReportScreen> {
  static const List<String> _frequencyOptions = <String>[
    'Daily',
    'Weekly',
    'Monthly',
  ];

  String _frequency = 'Monthly';
  late DateTime _periodDate;
  List<String> _selectedStudents = <String>[];
  List<String> _selectedClassrooms = <String>[];
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _periodDate = DateTime(now.year, now.month, 1);
  }

  void _onGenerate() {
    if (_selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one student',
        isError: true,
      );
      return;
    }

    if (_selectedClassrooms.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one classroom',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final reportsState = cubit.state;

    final studentCodes = _selectedStudents.isNotEmpty
        ? _selectedStudents
              .map((name) => reportsState.studentNameToCode[name] ?? name)
              .toList()
        : null;
    final classroomCodes = _selectedClassrooms.isNotEmpty
        ? _selectedClassrooms
              .map((name) => reportsState.classroomNameToCode[name] ?? name)
              .toList()
        : null;

    final params = ReportRequestParams(
      reportType: ReportType.studentAttendancePerStudent,
      startDate: _periodDate,
      endDate: _periodDate.add(
        Duration(
          days: _frequency == 'Daily'
              ? 0
              : _frequency == 'Weekly'
              ? 6
              : 30,
        ),
      ),
      studentCodes: studentCodes,
      classroomCodes: classroomCodes,
    );

    unawaited(cubit.generateReport(params));
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
                message: 'Report generated successfully',
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  context.go('/dashboard/reports?tab=0');
                  context.read<ReportsCubit>().clearGeneratedReport();
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
            title: 'Attendance per Student',
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
                            initialMonth: _periodDate,
                            onMonthSelected: (d) =>
                                setState(() => _periodDate = d),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.verticalSpacing),
                MultiSelectFilterField<String>(
                  label: 'Student',
                  hintText: 'Select Students',
                  items: widget.students,
                  selectedItems: _selectedStudents,
                  onChanged: (s) => setState(() => _selectedStudents = s),
                  itemToString: (item) => item,
                  singularLabel: 'Student',
                  pluralLabel: 'Students',
                  showSelectAll: true,
                  enableSearch: true,
                  searchHintText: 'Search Students',
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
