import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/utils/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../core/util/school_context_helper.dart';

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
    'Name',
    'Date Of Birth',
    'Email ID',
    'Phone Number',
    'Address',
    'Primary Classroom',
    'Clock-In-Out Pin',
    'Hire Date',
    'Designation',
    'CDA Expiration Date',
    'CPR Expiration Date',
    'Last Physical Date',
    'Is Active',
  ];

  static const List<String> _defaultStaffFields = <String>[
    'Name',
    'Email ID',
    'Designation',
  ];

  static const List<String> _statusOptions = <String>[
    'Active Staff',
    'Inactive Staff',
    'All Staff',
  ];

  late Set<String> _selectedStaffFields;
  String _status = 'Active Staff';
  List<String> _selectedClassrooms = <String>[];
  String _format = 'PDF';
  List<String> _availableClassrooms = <String>[];
  Map<String, String> _classroomNameToCode = <String, String>{};

  @override
  void initState() {
    super.initState();
    _selectedStaffFields = _defaultStaffFields.toSet();
    _selectedClassrooms = List<String>.from(widget.classrooms);
    _availableClassrooms = List<String>.from(widget.classrooms);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllStaffClassrooms();
      }
    });
  }

  Future<void> _loadAllStaffClassrooms() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isNotEmpty) {
        final classrooms =
            await serviceLocator<GetActiveClassroomsUseCase>()(
              schoolCode: schoolCode,
              onlyTypeClassroom: false,
            );
        final nameToCodeMap = <String, String>{};
        final names = <String>[];
        for (final c in classrooms) {
          names.add(c.name);
          nameToCodeMap[c.name] = c.code;
        }
        if (mounted) {
          setState(() {
            _availableClassrooms = names;
            _classroomNameToCode = nameToCodeMap;
            _selectedClassrooms = List<String>.from(names);
          });
        }
      }
    } catch (e) {
      AppLogger.e('[STAFF-DETAILS-UI] Failed to load staff classrooms: $e');
    }
  }

  bool get _selectAll => _selectedStaffFields.length == _staffFields.length;

  void _toggleSelectAll(bool checked) {
    setState(() {
      if (checked) {
        _selectedStaffFields = _staffFields.toSet();
      } else {
        _selectedStaffFields = <String>{};
      }
    });
  }

  void _toggleField(String field, bool checked) {
    setState(() {
      if (checked) {
        _selectedStaffFields.add(field);
      } else {
        _selectedStaffFields.remove(field);
      }
    });
  }

  void _onGenerate() async {
    AppLogger.d('[STAFF-DETAILS-UI] Generate button tapped');

    if (_selectedStaffFields.isEmpty) {
      AppLogger.w('[STAFF-DETAILS-UI] Generation blocked: no fields selected');
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one field',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final nameToCode = _classroomNameToCode.isNotEmpty
        ? _classroomNameToCode
        : cubit.state.classroomNameToCode;
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms,
      nameToCode: nameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    AppLogger.d(
      '[STAFF-DETAILS-UI] Selected classrooms: $_selectedClassrooms',
    );
    AppLogger.d(
      '[STAFF-DETAILS-UI] Resolved classroomCodes: $classroomCodes',
    );

    // Retrieve the school name from storage
    final schoolName = await SchoolContextHelper.getSchoolName();
    AppLogger.d('resolvedSchoolName=$schoolName');
    if (schoolName == null || schoolName.isEmpty) {
      if (!mounted) return;

      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to resolve school name',
        isError: true,
      );
      return;
    }

    AppLogger.d(
      '[STAFF-DETAILS-UI] Creating report params with ${_selectedStaffFields.length} fields',
    );
    final params = StaffDetailsReportParams(
      reportType: ReportType.staffDetails,
      staffFieldsSelected: _selectedStaffFields,
      statusFilter: _status,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      format: _format,
      schoolName: schoolName,
    );
    AppLogger.d('[STAFF-DETAILS-UI] Calling cubit.generateReport()');
    cubit.generateReport(params);
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
    final classroomItems = _availableClassrooms.isNotEmpty
        ? _availableClassrooms
        : widget.classrooms;

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
                message: 'Report generated successfully',
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // Pop (not context.go) — this screen was pushed via plain
                  // Navigator.push, so only popping actually dismisses it;
                  // the hub's own .then((success) => tab 0) callback reacts
                  // to the pop(true) result.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  Navigator.of(context).pop(true);
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
            title: 'Staff Details',
            onGenerate: (_selectedStaffFields.isNotEmpty && !isGenerating)
                ? _onGenerate
                : null,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose the below fields and generate a report',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff573353),
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing),
                const _SectionLabel(label: 'FIELDS'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomCheckbox(
                    value: _selectAll,
                    label: 'Select All',
                    onChanged: (v) => _toggleSelectAll(v ?? false),
                  ),
                ),
                const SizedBox(height: 8),
                _CheckboxGrid(
                  items: _staffFields,
                  selected: _selectedStaffFields,
                  onChanged: _toggleField,
                ),
                const Divider(height: 32),
                CustomDropdown(
                  label: 'Status',
                  hintText: 'Select',
                  items: _statusOptions,
                  selectedItem: _status,
                  labelStyle: _labelStyle(responsive),
                  showAsterisk: true,
                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  onSelect: (val) => setState(() => _status = val ?? _status),
                ),
                SizedBox(height: responsive.verticalSpacing),
                CustomMultiSelectDropdown(
                  label: 'Classroom',
                  hintText: 'Select Classroom',
                  items: classroomItems,
                  selectedItems: _selectedClassrooms,
                  onChanged: (s) => setState(() => _selectedClassrooms = s),
                  showSelectAll: true,
                ),
                const ReportDefaultNote(
                  text: 'Note: All Classrooms will be selected by Default.',
                ),
                SizedBox(height: responsive.verticalSpacing),
                const ReportFieldLabel(label: 'Export Format'),
                ReportFormatSelector(
                  selectedFormat: _format,
                  onFormatChanged: (value) => setState(() => _format = value),
                  showLabel: false,
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
