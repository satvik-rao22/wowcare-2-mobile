import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffAbsentReportScreen extends StatefulWidget {
  const StaffAbsentReportScreen({
    super.key,
    required this.classrooms,
  });

  static const String routeName = '/reports/staff/absent';

  final List<String> classrooms;

  @override
  State<StaffAbsentReportScreen> createState() =>
      _StaffAbsentReportScreenState();
}

class _StaffAbsentReportScreenState extends State<StaffAbsentReportScreen> {
  late final ValueNotifier<DateTime> _fromDate;
  late final ValueNotifier<DateTime> _toDate;
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('PDF');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _toDate = ValueNotifier<DateTime>(DateTime(now.year, now.month + 1, 0));
  }

  @override
  void dispose() {
    _fromDate.dispose();
    _toDate.dispose();
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  void _onGenerate() {
    if (_toDate.value.isBefore(_fromDate.value)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'To date cannot be before From date',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final params = ReportRequestParams(
      reportType: ReportType.staffAbsent,
      startDate: _fromDate.value,
      endDate: _toDate.value,
      classroomCodes: _selectedClassrooms.value.isEmpty
          ? null
          : _selectedClassrooms.value,
    );

    cubit.generateReport(params);
    if (mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Report generated successfully',
        isError: false,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return BlocListener<ReportsCubit, ReportsState>(
      listenWhen: (previous, current) =>
          previous.generationError != current.generationError,
      listener: (context, state) {
        if (state.generationError != null && state.generationError!.isNotEmpty) {
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
            title: 'Absent Report',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReportFieldLabel(label: 'From'),
              ValueListenableBuilder<DateTime>(
                valueListenable: _fromDate,
                builder: (_, date, __) => CustomDateTimeField(
                  hasLabel: false,
                  fetchInitialTime: false,
                  initialDate: date,
                  onDateSelected: (d) => _fromDate.value = d,
                ),
              ),
              SizedBox(height: responsive.verticalSpacing),
              const ReportFieldLabel(label: 'To'),
              ValueListenableBuilder<DateTime>(
                valueListenable: _toDate,
                builder: (_, date, __) => CustomDateTimeField(
                  hasLabel: false,
                  fetchInitialTime: false,
                  initialDate: date,
                  onDateSelected: (d) => _toDate.value = d,
                ),
              ),
              SizedBox(height: responsive.verticalSpacing),
              ValueListenableBuilder<List<String>>(
                valueListenable: _selectedClassrooms,
                builder: (_, selected, __) => CustomMultiSelectDropdown(
                  label: 'Classroom',
                  hintText: 'Select Classroom',
                  items: widget.classrooms,
                  selectedItems: selected,
                  onChanged: (s) => _selectedClassrooms.value = s,
                ),
              ),
              const ReportDefaultNote(
                text: 'Note: All Classrooms will be selected by Default.',
              ),
              SizedBox(height: responsive.verticalSpacing),
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
