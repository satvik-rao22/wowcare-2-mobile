import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/form_classrooms_field.dart';
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

class StaffDirectoryReportScreen extends StatefulWidget {
  const StaffDirectoryReportScreen({super.key, required this.classrooms});

  static const String routeName = '/reports/staff/directory';

  final List<String> classrooms;

  @override
  State<StaffDirectoryReportScreen> createState() =>
      _StaffDirectoryReportScreenState();
}

class _StaffDirectoryReportScreenState
    extends State<StaffDirectoryReportScreen> {
  static const List<String> _staffFields = <String>[
    ReportsStrings.name,
    ReportsStrings.dateOfBirth,
    ReportsStrings.emailId,
    ReportsStrings.phoneNumber,
    ReportsStrings.address,
    ReportsStrings.primaryClassroom,
    ReportsStrings.clockInOutPin,
    ReportsStrings.hireDate,
    ReportsStrings.designation,
    ReportsStrings.cdaExpirationDate,
    ReportsStrings.cprExpirationDate,
    ReportsStrings.lastPhysicalDate,
    'Is Active',
  ];

  /// The columns ticked when the form opens. Only the *field* checkboxes get
  /// a default — the classroom filter stays empty, because an empty filter
  /// means "all classrooms" there, whereas an empty column set means an empty
  /// report.
  static const List<String> _defaultStaffFields = <String>[
    ReportsStrings.name,
    ReportsStrings.emailId,
    ReportsStrings.designation,
  ];

  static const List<String> _statusOptions = <String>[
    'Active Staff',
    'Inactive Staff',
    'All Staff',
  ];

  /// §2.2 bucket B — which staff columns the report includes.
  final ValueNotifier<Set<String>> _selectedStaffFields =
      ValueNotifier<Set<String>>(_defaultStaffFields.toSet());
  final ValueNotifier<String> _status = ValueNotifier<String>('Active Staff');
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Staff reports need the wider list that also contains Office and
        // primary rooms (onlyTypeClassroom: false).
        context.read<ReportsCubit>().loadFormClassrooms(
          includeNonClassroomTypes: true,
        );
      }
    });
  }

  bool get _selectAll =>
      _selectedStaffFields.value.length == _staffFields.length;

  void _toggleSelectAll(bool checked) {
    _selectedStaffFields.value = checked ? _staffFields.toSet() : <String>{};
  }

  void _toggleField(String field, bool checked) {
    // A new Set, not an in-place mutation: ValueNotifier only notifies on a
    // reference change.
    final next = Set<String>.from(_selectedStaffFields.value);
    if (checked) {
      next.add(field);
    } else {
      next.remove(field);
    }
    _selectedStaffFields.value = next;
  }

  void _onGenerate() async {
    AppLogger.d('[STAFF-DETAILS-UI] Generate button tapped');

    if (_selectedStaffFields.value.isEmpty) {
      AppLogger.w('[STAFF-DETAILS-UI] Generation blocked: no fields selected');
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.pleaseSelectAtLeastOneField,
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final nameToCode = cubit.state.allClassroomNameToCode.isNotEmpty
        ? cubit.state.allClassroomNameToCode
        : cubit.state.classroomNameToCode;
    // Empty selection → no codes → `classroomCodes: null` below omits the
    // key, which is how this endpoint expresses "all classrooms".
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value,
      nameToCode: nameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    AppLogger.d('[STAFF-DETAILS-UI] Selected classrooms: $_selectedClassrooms');
    AppLogger.d('[STAFF-DETAILS-UI] Resolved classroomCodes: $classroomCodes');

    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;

    AppLogger.d(
      '[STAFF-DETAILS-UI] Creating report params with ${_selectedStaffFields.value.length} fields',
    );
    final params = StaffDetailsReportParams(
      reportType: ReportType.staffDetails,
      staffFieldsSelected: _selectedStaffFields.value,
      statusFilter: _status.value,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      format: _format.value,
      schoolName: schoolName,
    );
    AppLogger.d('[STAFF-DETAILS-UI] Calling cubit.generateReport()');
    cubit.generateReport(params);
  }

  TextStyle _labelStyle(BuildContext context) =>
      AppTextStyles.reportsFieldLabel(
        fontSize: context.responsive(compact: 14.0, medium: 16.0),
      );

  @override
  void dispose() {
    _selectedStaffFields.dispose();
    _format.dispose();
    _selectedClassrooms.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Drop selections that no longer exist when a refreshed classroom
        // list arrives. Never re-expands to "all" — an empty filter already
        // means every classroom.
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.allClassroomNames != current.allClassroomNames,
          listener: (context, state) {
            _selectedClassrooms.value = _selectedClassrooms.value
                .where(state.allClassroomNames.contains)
                .toList();
          },
        ),
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
          return ValueListenableBuilder<Set<String>>(
            valueListenable: _selectedStaffFields,
            builder: (context, staffFields, _) => ReportFormLayout(
              title: ReportsStrings.staffDetailsName,
              onGenerate: (staffFields.isNotEmpty && !isGenerating)
                  ? _onGenerate
                  : null,
              isLoading: isGenerating,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ReportsStrings.chooseTheBelowFieldsAndGenerateAReport,
                    style: AppTextStyles.reportsHeading(
                      fontSize: context.responsive(compact: 14.0, medium: 16.0),
                    ),
                  ),
                  SizedBox(
                    height: context.responsive(compact: 16.0, medium: 24.0),
                  ),
                  const ReportSectionLabel(label: ReportsStrings.fields),
                  const SizedBox(height: AppSizes.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomCheckbox(
                      value: _selectAll,
                      label: ReportsStrings.selectAll,
                      onChanged: (v) => _toggleSelectAll(v ?? false),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  ReportCheckboxGrid(
                    items: _staffFields,
                    selected: staffFields,
                    onChanged: _toggleField,
                  ),
                  const Divider(height: 32),
                  CustomDropdown(
                    label: ReportsStrings.status,
                    hintText: ReportsStrings.select,
                    items: _statusOptions,
                    selectedItem: _status.value,
                    labelStyle: _labelStyle(context),
                    showAsterisk: true,
                    labelBottomSpacing: context.isTablet ? 8.0 : 6.0,
                    onSelect: (val) => _status.value = val ?? _status.value,
                  ),
                  SizedBox(
                    height: context.responsive(compact: 16.0, medium: 24.0),
                  ),
                  FormClassroomsField(
                    includeNonClassroomTypes: true,
                    child:
                        BlocSelector<ReportsCubit, ReportsState, List<String>>(
                          selector: (state) =>
                              state.allClassroomNames.isNotEmpty
                              ? state.allClassroomNames
                              : widget.classrooms,
                          builder: (context, classroomItems) =>
                              CustomMultiSelectDropdown(
                                label: ReportsStrings.classroom,
                                hintText: ReportsStrings.allClassrooms,
                                items: classroomItems,
                                selectedItems: _selectedClassrooms.value,
                                onChanged: (s) => _selectedClassrooms.value = s,
                                showSelectAll: true,
                              ),
                        ),
                  ),
                  const ReportDefaultNote(
                    text: ReportsStrings.noteAllClassroomsIncludedByDefault,
                  ),
                  SizedBox(
                    height: context.responsive(compact: 16.0, medium: 24.0),
                  ),
                  const ReportFieldLabel(label: ReportsStrings.exportFormat),
                  ValueListenableBuilder<String>(
                    valueListenable: _format,
                    builder: (_, v, __) => ReportFormatSelector(
                      selectedFormat: v,
                      onFormatChanged: (value) => _format.value = value,
                      showLabel: false,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
