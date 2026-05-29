import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentDailyAttendanceReportScreen extends StatefulWidget {
  const StudentDailyAttendanceReportScreen({
    super.key,
    required this.classrooms,
  });

  static const String routeName = '/reports/student/daily-attendance';

  final List<String> classrooms;

  @override
  State<StudentDailyAttendanceReportScreen> createState() =>
      _StudentDailyAttendanceReportScreenState();
}

class _StudentDailyAttendanceReportScreenState
    extends State<StudentDailyAttendanceReportScreen> {
  late DateTime _date;
  List<String> _selectedClassrooms = <String>[];

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  void _onGenerate() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating Student Daily Attendance report…',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return ReportFormLayout(
      title: 'Student Daily Attendance',
      onGenerate: _onGenerate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportFieldLabel(label: 'Date'),
          CustomDateTimeField(
            hasLabel: false,
            fetchInitialTime: false,
            initialDate: _date,
            onDateSelected: (d) => setState(() => _date = d),
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
