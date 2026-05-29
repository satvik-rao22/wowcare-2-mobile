import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
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
  String? _selectedStudent;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _onGenerate() {
    if (_endDate.isBefore(_startDate)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'End date cannot be before Start date',
        isError: true,
      );
      return;
    }
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating School Incident Report…',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return ReportFormLayout(
      title: 'School Incident Report',
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
          CustomDropdown(
            label: 'Student',
            hintText: 'Select Student',
            items: widget.students,
            selectedItem: _selectedStudent,
            labelStyle: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              color: const Color(0xff573353),
            ),
            showAsterisk: false,
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            onSelect: (val) => setState(() => _selectedStudent = val),
          ),
          const ReportDefaultNote(
            text: 'Note: All Students will be selected by Default.',
          ),
        ],
      ),
    );
  }
}
