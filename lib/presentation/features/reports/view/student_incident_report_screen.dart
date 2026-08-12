import 'dart:async';
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
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
// import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../core/util/school_context_helper.dart';

class StudentIncidentReportScreen extends StatefulWidget {
  const StudentIncidentReportScreen({
    super.key,
    required this.students,
    this.classrooms = const [],
    // required this.classrooms,
  });

  static const String routeName = '/reports/student/incident';

  final List<String> students;
  final List<String> classrooms;

  @override
  State<StudentIncidentReportScreen> createState() =>
      _StudentIncidentReportScreenState();
}

class _StudentIncidentReportScreenState
    extends State<StudentIncidentReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<String> _selectedStudents = <String>[];
  // late List<String> _selectedClassrooms;
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _selectedStudents = List<String>.from(widget.students);
    // _selectedClassrooms = List<String>.from(widget.classrooms);
  }

  @override
  void didUpdateWidget(covariant StudentIncidentReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students != widget.students) {
      setState(() {
        _selectedStudents = List<String>.from(widget.students);
      });
    }
  }

  void _onGenerate() async {
    AppLogger.d('[INCIDENT-UI] Generate button tapped');

    if (_toDate.isBefore(_startDate)) {
      AppLogger.w('[INCIDENT-UI] Generation blocked: To date before From date');
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'End date cannot be before Start date',
        isError: true,
      );
      return;
    }

    AppLogger.d('[INCIDENT-UI] Creating report params');
    final cubit = context.read<ReportsCubit>();
    final studentNameToCode = cubit.state.studentNameToCode;
    final studentCodes = resolveReportCodes(
      context: context,
      names: _selectedStudents,
      nameToCode: studentNameToCode,
      labelPlural: 'students',
    );
    if (studentCodes == null) return;

    // final classroomCodes = resolveReportCodes(
    //   context: context,
    //   names: _selectedClassrooms.isEmpty ? widget.classrooms : _selectedClassrooms,
    //   nameToCode: cubit.state.classroomNameToCode,
    //   labelPlural: 'classrooms',
    // );
    // if (classroomCodes == null) return;

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
    final params = ReportRequestParams(
      reportType: ReportType.studentIncident,
      startDate: _startDate,
      endDate: _endDate,
      studentCodes: studentCodes,
      // roomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      format: _format,
      schoolName: schoolName,
    );

    AppLogger.d('[INCIDENT-UI] Calling cubit.generateReport()');
    unawaited(cubit.generateReport(params));
  }

  DateTime get _toDate => _endDate;

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

                  // Pop (not context.go) — this screen was pushed via plain
                  // Navigator.push, so only popping actually dismisses it;
                  // the hub's own .then((success) => tab 0) callback reacts
                  // to the pop(true) result.
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
            title: 'School Incident Report',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: 'Start Date'),
                CustomDateTimeField(
                  hasLabel: false,
                  dateFormat: 'MM/dd/yyyy',
                  fetchInitialTime: false,
                  initialDate: _startDate,
                  onDateSelected: (d) => setState(() => _startDate = d),
                ),
                SizedBox(height: responsive.verticalSpacing),
                const ReportFieldLabel(label: 'End Date'),
                CustomDateTimeField(
                  hasLabel: false,
                  dateFormat: 'MM/dd/yyyy',
                  fetchInitialTime: false,
                  initialDate: _endDate,
                  onDateSelected: (d) => setState(() => _endDate = d),
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
                const ReportDefaultNote(
                  text: 'Note: All Students will be selected by Default.',
                ),
                // SizedBox(height: responsive.verticalSpacing),
                // CustomMultiSelectDropdown(
                //   label: 'Classroom',
                //   hintText: 'Select Classroom',
                //   items: widget.classrooms,
                //   selectedItems: _selectedClassrooms,
                //   onChanged: (s) => setState(() => _selectedClassrooms = s),
                //   showSelectAll: true,
                // ),
                // const ReportDefaultNote(
                //   text: 'Note: All Classrooms will be selected by Default.',
                // ),
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
