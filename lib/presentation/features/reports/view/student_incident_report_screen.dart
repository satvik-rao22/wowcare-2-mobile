import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentIncidentReportScreen extends StatefulWidget {
  const StudentIncidentReportScreen({
    super.key,
    required this.students,
  });

  static const String routeName = '/reports/student/incident';

  final List<String> students;

  @override
  State<StudentIncidentReportScreen> createState() =>
      _StudentIncidentReportScreenState();
}

class _StudentIncidentReportScreenState
    extends State<StudentIncidentReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<String> _selectedStudents = <String>[];
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _onGenerate() {
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
    final params = ReportRequestParams(
      reportType: ReportType.studentIncident,
      startDate: _startDate,
      endDate: _endDate,
      studentCodes: _selectedStudents.isEmpty ? null : _selectedStudents,
      format: _format,
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
            title: 'School Incident Report',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReportFieldLabel(label: 'Start Date'),
              CustomDateTimeField(
                hasLabel: false,
                fetchInitialTime: false,
                initialDate: _startDate,
                onDateSelected: (d) => setState(() => _startDate = d),
              ),
              SizedBox(height: responsive.verticalSpacing),
              const ReportFieldLabel(label: 'End Date'),
              CustomDateTimeField(
                hasLabel: false,
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
