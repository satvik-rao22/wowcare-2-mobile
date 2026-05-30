import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
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
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating Staff Absent Report…',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return ReportFormLayout(
      title: 'Absent Report',
      onGenerate: _onGenerate,
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
        ],
      ),
    );
  }
}
