import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/students_and_family_report_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
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

  late final ValueNotifier<Set<String>> _selectedStudentFields =
      ValueNotifier<Set<String>>(_defaultStudentFields.toSet());
  late final ValueNotifier<Set<String>> _selectedParentFields =
      ValueNotifier<Set<String>>(_defaultParentFields.toSet());
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<List<String>> _selectedTags = ValueNotifier<List<String>>(
    <String>[],
  );
  final ValueNotifier<String> _status = ValueNotifier<String>('Active');
  final ValueNotifier<String> _format = ValueNotifier<String>('PDF');

  @override
  void dispose() {
    _selectedStudentFields.dispose();
    _selectedParentFields.dispose();
    _selectedClassrooms.dispose();
    _selectedTags.dispose();
    _status.dispose();
    _format.dispose();
    super.dispose();
  }

  void _toggleSelectAll(bool checked) {
    _selectedStudentFields.value = checked
        ? _studentFields.toSet()
        : <String>{};
  }

  void _toggleStudentField(String field, bool checked) {
    final next = Set<String>.from(_selectedStudentFields.value);
    checked ? next.add(field) : next.remove(field);
    _selectedStudentFields.value = next;
  }

  void _toggleParentField(String field, bool checked) {
    final next = Set<String>.from(_selectedParentFields.value);
    checked ? next.add(field) : next.remove(field);
    _selectedParentFields.value = next;
  }

  void _onGenerate() {
    if (_selectedStudentFields.value.isEmpty &&
        _selectedParentFields.value.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one field',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final params = StudentsAndFamilyReportParams(
      reportType: ReportType.studentsAndFamily,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      studentFieldsSelected: _selectedStudentFields.value,
      parentFieldsSelected: _selectedParentFields.value,
      statusFilter: _status.value,
      classroomCodes: _selectedClassrooms.value.isEmpty
          ? null
          : _selectedClassrooms.value,
      tagCodes: _selectedTags.value.isEmpty ? null : _selectedTags.value,
      format: _format.value,
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

  TextStyle _labelStyle(ResponsiveHelper r) => TextStyle(
    fontSize: r.labelFontSize,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w400,
    color: const Color(0xff573353),
  );

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
            title: 'Students and Family',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
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
              ValueListenableBuilder<Set<String>>(
                valueListenable: _selectedStudentFields,
                builder: (_, studentFields, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomCheckbox(
                        value: studentFields.length == _studentFields.length,
                        label: 'Select All',
                        onChanged: (v) => _toggleSelectAll(v ?? false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CheckboxGrid(
                      items: _studentFields,
                      selected: studentFields,
                      onChanged: _toggleStudentField,
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.verticalSpacing),
              const _SectionLabel(
                label: 'PARENT/GUARDIAN & AUTHORIZED PICKUP INFO',
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Set<String>>(
                valueListenable: _selectedParentFields,
                builder: (_, parentFields, __) => _CheckboxGrid(
                  items: _parentFields,
                  selected: parentFields,
                  onChanged: _toggleParentField,
                ),
              ),
              const Divider(height: 32),
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
              ValueListenableBuilder<List<String>>(
                valueListenable: _selectedTags,
                builder: (_, selected, __) => CustomMultiSelectDropdown(
                  label: 'Tag',
                  hintText: 'Select Tag',
                  items: widget.tags,
                  selectedItems: selected,
                  onChanged: (s) => _selectedTags.value = s,
                ),
              ),
              const ReportDefaultNote(
                text: 'Note: All Tags will be selected by Default.',
              ),
              SizedBox(height: responsive.verticalSpacing),
              ValueListenableBuilder<String>(
                valueListenable: _status,
                builder: (_, status, __) => CustomDropdown(
                  label: 'Status',
                  hintText: 'Select',
                  items: _statusOptions,
                  selectedItem: status,
                  labelStyle: _labelStyle(responsive),
                  showAsterisk: true,
                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  prependHintAsSelectableItem: false,
                  onSelect: (val) => _status.value = val ?? _status.value,
                ),
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
