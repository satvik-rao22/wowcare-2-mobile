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
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../core/util/school_context_helper.dart';

class StudentEmergencyContactReportScreen extends StatefulWidget {
  const StudentEmergencyContactReportScreen({
    super.key,
    required this.classrooms,
  });

  static const String routeName = '/reports/student/emergency-contact';

  final List<String> classrooms;

  @override
  State<StudentEmergencyContactReportScreen> createState() =>
      _StudentEmergencyContactReportScreenState();
}

class _StudentEmergencyContactReportScreenState
    extends State<StudentEmergencyContactReportScreen> {
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('PDF');

  @override
  void initState() {
    super.initState();
    _selectedClassrooms.value = List<String>.from(widget.classrooms);
  }

  @override
  void dispose() {
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  bool get _isFormValid => _selectedClassrooms.value.isNotEmpty;

  Future<void> _onGenerate() async {
    if (!_isFormValid) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one classroom',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final classroomNameToCode = cubit.state.classroomNameToCode;
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value,
      nameToCode: classroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

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
      reportType: ReportType.emergencyContacts,
      startDate: AppTime.now(),
      endDate: AppTime.now(),
      format: _format.value, // PDF or XLSX
      classroomCodes: classroomCodes,
      schoolName: schoolName,
    );
    cubit.generateReport(params);
  }

  @override
  Widget build(BuildContext context) {
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
          listenWhen: (previous, current) {
            final changed =
                previous.generationSuccess != current.generationSuccess;
            AppLogger.d(
              '[LISTENER-WHEN] generationSuccess changed: $changed (prev=${previous.generationSuccess}, curr=${current.generationSuccess})',
            );
            return changed;
          },
          listener: (context, state) {
            AppLogger.d(
              '[LISTENER-EXEC] generationSuccess=${state.generationSuccess}, generatedReport=${state.generatedReport != null}',
            );
            if (state.generationSuccess != null &&
                state.generationSuccess!.isNotEmpty &&
                state.generatedReport != null) {
              AppLogger.d('[LISTENER-SHOW-SNACKBAR] About to show snackbar');
              CoreUtils.showTopSnackBar(
                context: context,
                message: 'Report generated successfully',
                isSuccess: true,
              );

              if (mounted) {
                AppLogger.d(
                  '[LISTENER-NAVIGATE] Adding postFrameCallback for navigation',
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    AppLogger.d('[LISTENER-NAVIGATE-SKIP] Widget not mounted');
                    return;
                  }

                  AppLogger.d('[LISTENER-NAVIGATE-EXEC] Executing navigation');
                  // Pop (not context.go) — this screen was pushed via plain
                  // Navigator.push, so only popping actually dismisses it;
                  // the hub's own .then((success) => tab 0) callback reacts
                  // to the pop(true) result.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  Navigator.of(context).pop(true);
                });
              }
            } else {
              AppLogger.d('[LISTENER-SKIP] Condition not met for snackbar/nav');
            }
          },
        ),
      ],
      child: BlocSelector<ReportsCubit, ReportsState, bool>(
        selector: (state) => state.isGenerating,
        builder: (context, isGenerating) {
          return ReportFormLayout(
            title: 'Student Emergency Contact List',
            onGenerate: _onGenerate,
            isLoading: isGenerating,
            showButton: true,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: 'Classroom',
                    hintText: 'Select Classroom',
                    items: widget.classrooms,
                    selectedItems: selected,
                    onChanged: (s) => _selectedClassrooms.value = s,
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: 'Note: All Classrooms will be selected by Default.',
                ),
                SizedBox(height: ResponsiveHelper(context).verticalSpacing),
                const ReportFieldLabel(label: 'Export Format'),
                ValueListenableBuilder<String>(
                  valueListenable: _format,
                  builder: (_, format, __) => ReportFormatSelector(
                    selectedFormat: format,
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
