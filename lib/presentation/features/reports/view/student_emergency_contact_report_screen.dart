import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
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
  List<String> _selectedClassrooms = <String>[];

  void _onGenerate() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating Student Emergency Contact List…',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ReportFormLayout(
      title: 'Student Emergency Contact List',
      onGenerate: _onGenerate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
