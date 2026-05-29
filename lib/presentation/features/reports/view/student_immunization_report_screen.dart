import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentImmunizationReportScreen extends StatefulWidget {
  const StudentImmunizationReportScreen({
    super.key,
    required this.classrooms,
    required this.tags,
  });

  static const String routeName = '/reports/student/immunization';

  final List<String> classrooms;
  final List<String> tags;

  @override
  State<StudentImmunizationReportScreen> createState() =>
      _StudentImmunizationReportScreenState();
}

class _StudentImmunizationReportScreenState
    extends State<StudentImmunizationReportScreen> {
  static const List<String> _vaccineOptions = <String>[
    'All Vaccines',
    'DTaP',
    'Polio (IPV)',
    'MMR',
    'Varicella',
    'Hepatitis B',
    'Hepatitis A',
    'Hib',
    'Pneumococcal (PCV)',
    'Rotavirus',
    'Influenza',
    'COVID-19',
  ];

  static const List<String> _statusOptions = <String>[
    'Active',
    'Upcoming',
    'Inactive',
  ];

  String _vaccine = 'All Vaccines';
  String _status = 'Active';
  List<String> _selectedClassrooms = <String>[];
  List<String> _selectedTags = <String>[];
  bool _showParentInfo = false;

  void _onGenerate() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating School Immunization Report…',
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
      title: 'School Immunization Report',
      onGenerate: _onGenerate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDropdown(
            label: 'Vaccines',
            hintText: 'Select',
            items: _vaccineOptions,
            selectedItem: _vaccine,
            labelStyle: _labelStyle(responsive),
            showAsterisk: true,
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            prependHintAsSelectableItem: false,
            onSelect: (val) {
              if (val == null) return;
              setState(() => _vaccine = val);
            },
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomDropdown(
            label: 'Status',
            hintText: 'Select',
            items: _statusOptions,
            selectedItem: _status,
            labelStyle: _labelStyle(responsive),
            showAsterisk: true,
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            prependHintAsSelectableItem: false,
            onSelect: (val) {
              if (val == null) return;
              setState(() => _status = val);
            },
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
          SizedBox(height: responsive.verticalSpacing),
          CustomMultiSelectDropdown(
            label: 'Tag',
            hintText: 'Select Tag',
            items: widget.tags,
            selectedItems: _selectedTags,
            onChanged: (s) => setState(() => _selectedTags = s),
          ),
          const ReportDefaultNote(
            text: 'Note: All Tags will be selected by Default.',
          ),
          SizedBox(height: responsive.verticalSpacing),
          Align(
            alignment: Alignment.centerLeft,
            child: CustomCheckbox(
              value: _showParentInfo,
              label: 'Show Parent name and emails',
              onChanged: (v) => setState(() => _showParentInfo = v ?? false),
            ),
          ),
        ],
      ),
    );
  }
}
