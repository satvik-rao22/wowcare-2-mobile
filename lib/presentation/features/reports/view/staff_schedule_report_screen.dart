import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffScheduleReportScreen extends StatefulWidget {
  const StaffScheduleReportScreen({
    super.key,
    required this.classrooms,
  });

  static const String routeName = '/reports/staff/schedule';

  final List<String> classrooms;

  @override
  State<StaffScheduleReportScreen> createState() =>
      _StaffScheduleReportScreenState();
}

class _StaffScheduleReportScreenState
    extends State<StaffScheduleReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<String> _selectedClassrooms = <String>[];
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = now;
    _endDate = now.add(const Duration(days: 6));
  }

  void _onGenerate() {
    const message = 'Staff Scheduling report is currently unavailable because backend endpoint does not exist.';
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: true,
    );
  }

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
      child: ReportFormLayout(
        title: 'Staff Scheduling',
        onGenerate: _onGenerate,
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
      ),
    );
  }
}
