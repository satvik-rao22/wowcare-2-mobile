import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentAbsentReportScreen extends StatefulWidget {
  const StudentAbsentReportScreen({
    super.key,
    required this.classrooms,
  });

  static const String routeName = '/reports/student/absent';

  final List<String> classrooms;

  @override
  State<StudentAbsentReportScreen> createState() =>
      _StudentAbsentReportScreenState();
}

class _StudentAbsentReportScreenState extends State<StudentAbsentReportScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  List<String> _selectedClassrooms = <String>[];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
  }

  void _onGenerate() {
    if (_toDate.isBefore(_fromDate)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'To date cannot be before From date',
        isError: true,
      );
      return;
    }
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating Absent Report…',
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
          CustomDateTimeField(
            hasLabel: false,
            fetchInitialTime: false,
            initialDate: _fromDate,
            onDateSelected: (d) => setState(() => _fromDate = d),
          ),
          SizedBox(height: responsive.verticalSpacing),
          const ReportFieldLabel(label: 'To'),
          CustomDateTimeField(
            hasLabel: false,
            fetchInitialTime: false,
            initialDate: _toDate,
            onDateSelected: (d) => setState(() => _toDate = d),
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomMultiSelectDropdown(
            label: 'Classroom',
            hintText: 'Select Classroom',
            items: widget.classrooms,
            selectedItems: _selectedClassrooms,
            onChanged: (s) => setState(() => _selectedClassrooms = s),
          ),
          const ReportDefaultNote(
            text: 'Note: All Classrooms will be selected by Default.',
          ),
        ],
      ),
    );
  }
}
