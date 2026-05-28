import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentsAndFamilyReportScreen extends StatefulWidget {
  const StudentsAndFamilyReportScreen({
    super.key,
    required this.classrooms,
    required this.tags,
  });

  static const String routeName = '/reports/student/students-and-family';

  final List<String> classrooms;
  final List<String> tags;

  @override
  State<StudentsAndFamilyReportScreen> createState() =>
      _StudentsAndFamilyReportScreenState();
}

class _StudentsAndFamilyReportScreenState
    extends State<StudentsAndFamilyReportScreen> {
  static const List<String> _studentFields = <String>[
    'Full Name',
    'DOB',
    'Address',
    'Tags',
    'Classroom',
    'Status',
    'Note',
    'Allergies',
    'Schedule',
    'Medications',
    'Enroll Date',
    'School Leaving Date',
    'Diet Restriction',
  ];

  static const List<String> _parentFields = <String>[
    'First name',
    'Last name',
    'Relation',
    'Email',
    'Phone number',
    'Emergency Contact',
    'Sign-in-Pin',
  ];

  static const List<String> _defaultStudentFields = <String>[
    'Full Name',
    'DOB',
    'Classroom',
  ];

  static const List<String> _defaultParentFields = <String>[
    'First name',
    'Last name',
    'Relation',
    'Email',
  ];

  static const List<String> _statusOptions = <String>[
    'Active',
    'Upcoming',
    'Inactive',
  ];

  late Set<String> _selectedStudentFields;
  late Set<String> _selectedParentFields;
  List<String> _selectedClassrooms = <String>[];
  List<String> _selectedTags = <String>[];
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _selectedStudentFields = _defaultStudentFields.toSet();
    _selectedParentFields = _defaultParentFields.toSet();
  }

  bool get _selectAllStudent =>
      _selectedStudentFields.length == _studentFields.length;

  void _toggleSelectAll(bool checked) {
    setState(() {
      if (checked) {
        _selectedStudentFields = _studentFields.toSet();
      } else {
        _selectedStudentFields = <String>{};
      }
    });
  }

  void _toggleStudentField(String field, bool checked) {
    setState(() {
      if (checked) {
        _selectedStudentFields.add(field);
      } else {
        _selectedStudentFields.remove(field);
      }
    });
  }

  void _toggleParentField(String field, bool checked) {
    setState(() {
      if (checked) {
        _selectedParentFields.add(field);
      } else {
        _selectedParentFields.remove(field);
      }
    });
  }

  void _onGenerate() {
    if (_selectedStudentFields.isEmpty && _selectedParentFields.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one field',
        isError: true,
      );
      return;
    }
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating Students and Family report…',
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
      title: 'Students and Family',
      onGenerate: _onGenerate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose the below fields and generate a report',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.labelFontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xff573353),
            ),
          ),
          SizedBox(height: responsive.verticalSpacing),
          const _SectionLabel(label: 'FIELDS'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: CustomCheckbox(
              value: _selectAllStudent,
              label: 'Select All',
              onChanged: (v) => _toggleSelectAll(v ?? false),
            ),
          ),
          const SizedBox(height: 8),
          _CheckboxGrid(
            items: _studentFields,
            selected: _selectedStudentFields,
            onChanged: _toggleStudentField,
          ),
          SizedBox(height: responsive.verticalSpacing),
          const _SectionLabel(label: 'PARENT/GUARDIAN & AUTHORIZED PICKUP INFO'),
          const SizedBox(height: 8),
          _CheckboxGrid(
            items: _parentFields,
            selected: _selectedParentFields,
            onChanged: _toggleParentField,
          ),
          const Divider(height: 32),
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
          CustomDropdown(
            label: 'Status',
            hintText: 'Select',
            items: _statusOptions,
            selectedItem: _status,
            labelStyle: _labelStyle(responsive),
            showAsterisk: true,
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            prependHintAsSelectableItem: false,
            onSelect: (val) => setState(() => _status = val ?? _status),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: Color(0xff4F46E5),
      ),
    );
  }
}

class _CheckboxGrid extends StatelessWidget {
  const _CheckboxGrid({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<String> items;
  final Set<String> selected;
  final void Function(String field, bool checked) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;
        final columns = isWide ? 3 : 2;
        return Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomCheckbox(
                    value: selected.contains(item),
                    label: item,
                    onChanged: (v) => onChanged(item, v ?? false),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
