import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentAttendancePerStudentReportScreen extends StatefulWidget {
  const StudentAttendancePerStudentReportScreen({
    super.key,
    required this.students,
    required this.classrooms,
  });

  static const String routeName = '/reports/student/attendance-per-student';

  final List<String> students;
  final List<String> classrooms;

  @override
  State<StudentAttendancePerStudentReportScreen> createState() =>
      _StudentAttendancePerStudentReportScreenState();
}

class _StudentAttendancePerStudentReportScreenState
    extends State<StudentAttendancePerStudentReportScreen> {
  static const List<String> _frequencyOptions = <String>[
    'Daily',
    'Weekly',
    'Monthly',
  ];

  String _frequency = 'Monthly';
  late DateTime _periodDate;
  String? _selectedStudent;
  List<String> _selectedClassrooms = <String>[];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodDate = DateTime(now.year, now.month, 1);
  }

  void _onGenerate() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating Attendance per Student report…',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  TextStyle _labelStyle(ResponsiveHelper r) => TextStyle(
        fontSize: r.labelFontSize,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      );

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return ReportFormLayout(
      title: 'Attendance per Student',
      onGenerate: _onGenerate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CustomDropdown(
                  label: 'Frequency',
                  hintText: 'Select',
                  items: _frequencyOptions,
                  selectedItem: _frequency,
                  labelStyle: _labelStyle(responsive),
                  showAsterisk: true,
                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  prependHintAsSelectableItem: false,
                  onSelect: (val) {
                    if (val == null) return;
                    setState(() => _frequency = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ReportFieldLabel(label: 'Period'),
                    ReportMonthYearField(
                      initialMonth: _periodDate,
                      onMonthSelected: (d) =>
                          setState(() => _periodDate = d),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomDropdown(
            label: 'Student',
            hintText: 'Select Student',
            items: widget.students,
            selectedItem: _selectedStudent,
            labelStyle: _labelStyle(responsive),
            showAsterisk: false,
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            onSelect: (val) => setState(() => _selectedStudent = val),
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
