import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/students_and_family_report_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';

import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_checkbox_grid.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_section_label.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/widgets/resolve_school_name.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

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
    ReportsStrings.fullName,
    ReportsStrings.dob,
    ReportsStrings.address,
    ReportsStrings.tags,
    ReportsStrings.classroom,
    ReportsStrings.status,
    ReportsStrings.note,
    ReportsStrings.allergies,
    ReportsStrings.schedule,
    ReportsStrings.medications,
    ReportsStrings.enrollDate,
    ReportsStrings.schoolLeavingDate,
    ReportsStrings.dietRestriction,
  ];

  static const List<String> _parentFields = <String>[
    ReportsStrings.firstName,
    ReportsStrings.lastName,
    ReportsStrings.relation,
    ReportsStrings.email,
    ReportsStrings.phoneNumberAlt,
    ReportsStrings.emergencyContact,
    ReportsStrings.signInPin,
  ];

  /// The columns ticked when the form opens. Only the *field* checkboxes get
  /// a default — the classroom and tag filters stay empty, because an empty
  /// filter means "all" there, whereas an empty column set means an empty
  /// report.
  static const List<String> _defaultStudentFields = <String>[
    ReportsStrings.fullName,
    ReportsStrings.dob,
    ReportsStrings.classroom,
  ];

  static const List<String> _defaultParentFields = <String>[
    ReportsStrings.firstName,
    ReportsStrings.lastName,
    ReportsStrings.relation,
    ReportsStrings.email,
  ];

  static const List<String> _statusOptions = <String>[
    'Active',
    'Upcoming',
    'Inactive',
  ];

  final ValueNotifier<Set<String>> _selectedStudentFields =
      ValueNotifier<Set<String>>(_defaultStudentFields.toSet());
  final ValueNotifier<Set<String>> _selectedParentFields =
      ValueNotifier<Set<String>>(_defaultParentFields.toSet());
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<List<String>> _selectedTags = ValueNotifier<List<String>>(
    <String>[],
  );
  final ValueNotifier<String> _status = ValueNotifier<String>('Active');
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

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

  void _onGenerate() async {
    if (_selectedStudentFields.value.isEmpty &&
        _selectedParentFields.value.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.pleaseSelectAtLeastOneField,
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final classroomNameToCode = cubit.state.classroomNameToCode;
    final classroomCodes = _selectedClassrooms.value.isEmpty
        ? <String>[]
        : resolveReportCodes(
            context: context,
            names: _selectedClassrooms.value,
            nameToCode: classroomNameToCode,
            labelPlural: 'classrooms',
          );
    if (classroomCodes == null) return;

    final selectedTagNames = _selectedTags.value;
    List<String>? tagCodes;
    if (selectedTagNames.isNotEmpty) {
      // The cubit already loads this map in loadTags(); top it up through the
      // cubit rather than resolving the use case here.
      final cubit = context.read<ReportsCubit>();
      if (cubit.state.tagNameToCode.isEmpty) {
        await cubit.loadTags();
        if (!mounted) return;
      }
      final tagNameToCode = cubit.state.tagNameToCode;
      if (tagNameToCode.isEmpty) {
        if (!mounted) return;

        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.unableToResolveSchoolCodeForTagLookup,
          isError: true,
        );
        return;
      }
      final unresolved = selectedTagNames.where(
        (name) => tagNameToCode[name] == null || tagNameToCode[name]!.isEmpty,
      );
      if (unresolved.isNotEmpty) {
        if (!mounted) return;

        CoreUtils.showTopSnackBar(
          context: context,
          message:
              'Could not resolve tags: ${unresolved.join(', ')}. Please refresh and reselect them.',
          isError: true,
        );
        return;
      }
      tagCodes = selectedTagNames.map((name) => tagNameToCode[name]!).toList();
    }

    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;
    final params = StudentsAndFamilyReportParams(
      reportType: ReportType.studentsAndFamily,
      startDate: AppTime.now(),
      endDate: AppTime.now(),
      studentFieldsSelected: _selectedStudentFields.value,
      parentFieldsSelected: _selectedParentFields.value,
      statusFilter: _status.value,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      tagCodes: tagCodes,
      format: _format.value,
      schoolName: schoolName,
    );
    cubit.generateReport(params);
  }

  TextStyle _labelStyle(BuildContext context) =>
      AppTextStyles.reportsFieldLabel(
        fontSize: context.responsive(compact: 14.0, medium: 16.0),
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.generationError != current.generationError,
          listener: (context, state) {
            if (state.generationError != null &&
                state.generationError!.isNotEmpty) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: state.generationError!,
                isError: true,
              );
            }
          },
        ),
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.generationSuccess != current.generationSuccess,
          listener: (context, state) {
            if (state.generationSuccess != null &&
                state.generationSuccess!.isNotEmpty &&
                state.generatedReport != null) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: ReportsStrings.reportGeneratedSuccessfully,
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // Hand the hub a typed result. The report is generated
                  // but the file is not attached, so the hub animates to the
                  // Generated tab -- the outcome pop(true) used to encode.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  context.pop(const ReportGeneratedRefreshList());
                });
              }
            }
          },
        ),
      ],
      child: BlocSelector<ReportsCubit, ReportsState, bool>(
        selector: (state) => state.isGenerating,
        builder: (context, isGenerating) {
          return ReportFormLayout(
            title: ReportsStrings.studentsAndFamilyName,
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReportsStrings.chooseTheBelowFieldsAndGenerateAReport,
                  style: AppTextStyles.reportsFieldValue(
                    fontSize: context.responsive(compact: 14.0, medium: 16.0),
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportSectionLabel(label: ReportsStrings.fields),
                const SizedBox(height: AppSizes.xs),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: _selectedStudentFields,
                  builder: (_, studentFields, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CustomCheckbox(
                          value: studentFields.length == _studentFields.length,
                          label: ReportsStrings.selectAll,
                          onChanged: (v) => _toggleSelectAll(v ?? false),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      ReportCheckboxGrid(
                        items: _studentFields,
                        selected: studentFields,
                        onChanged: _toggleStudentField,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportSectionLabel(
                  label: ReportsStrings.parentGuardianAuthorizedPickupInfo,
                ),
                const SizedBox(height: AppSizes.xs),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: _selectedParentFields,
                  builder: (_, parentFields, __) => ReportCheckboxGrid(
                    items: _parentFields,
                    selected: parentFields,
                    onChanged: _toggleParentField,
                  ),
                ),
                const Divider(height: 32),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: ReportsStrings.classroom,
                    hintText: ReportsStrings.allClassrooms,
                    items: widget.classrooms,
                    selectedItems: selected,
                    onChanged: (s) => _selectedClassrooms.value = s,
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: ReportsStrings.noteAllClassroomsIncludedByDefault,
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedTags,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: ReportsStrings.tag,
                    hintText: ReportsStrings.allTags,
                    items: widget.tags,
                    selectedItems: selected,
                    onChanged: (s) => _selectedTags.value = s,
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: ReportsStrings.noteAllTagsIncludedByDefault,
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: _status,
                  builder: (_, status, __) => CustomDropdown(
                    label: ReportsStrings.status,
                    hintText: ReportsStrings.select,
                    items: _statusOptions,
                    selectedItem: status,
                    labelStyle: _labelStyle(context),
                    showAsterisk: true,
                    labelBottomSpacing: context.isTablet ? 8.0 : 6.0,
                    onSelect: (val) => _status.value = val ?? _status.value,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportFieldLabel(label: ReportsStrings.exportFormat),
                ValueListenableBuilder<String>(
                  valueListenable: _format,
                  builder: (_, format, __) => ReportFormatSelector(
                    selectedFormat: format,
                    onFormatChanged: (value) => _format.value = value,
                    showLabel: false,
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
