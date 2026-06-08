import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';

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
  void dispose() {
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  bool get _isFormValid => _selectedClassrooms.value.isNotEmpty;

  void _onGenerate() {
    if (!_isFormValid) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one classroom',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final params = ReportRequestParams(
      reportType: ReportType.emergencyContacts,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      classroomCodes: _selectedClassrooms.value,
    );
    cubit.generateReport(params);
    if (mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Report generated successfully',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsCubit, ReportsState>(
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
      child: BlocSelector<ReportsCubit, ReportsState, bool>(
        selector: (state) => state.isGenerating,
        builder: (context, isGenerating) {
          return ReportFormLayout(
            title: 'Student Emergency Contact List',
            onGenerate: (_isFormValid && !isGenerating) ? _onGenerate : null,
            isLoading: isGenerating,
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
                ValueListenableBuilder<String>(
                  valueListenable: _format,
                  builder: (_, format, __) => ReportFormatSelector(
                    selectedFormat: format,
                    onFormatChanged: (value) => _format.value = value,
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
