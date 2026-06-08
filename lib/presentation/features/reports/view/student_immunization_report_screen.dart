import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:go_router/go_router.dart';
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
  String _format = 'PDF';

  void _onGenerate() {
    final cubit = context.read<ReportsCubit>();

    // Map vaccine selection to backend codes
    final vaccineCodes = _mapVaccineToCode(_vaccine);

    // Map status selection to backend codes
    final statusFilters = _mapStatusToCode(_status);

    final params = SchoolImmunizationReportParams(
      reportType: ReportType.immunization,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      vaccineCodes: vaccineCodes,
      statusFilters: statusFilters,
      includeParentName: _showParentInfo,
      includeParentEmail: _showParentInfo,
      classroomCodes: _selectedClassrooms.isEmpty ? null : _selectedClassrooms,
      tagCodes: _selectedTags.isEmpty ? null : _selectedTags,
      format: _format,
    );
    cubit.generateReport(params);
    if (mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Report generated successfully',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    }
  }

  /// Map UI vaccine selection to backend vaccine codes.
  List<String> _mapVaccineToCode(String vaccine) {
    const vaccineMap = {
      'All Vaccines': [
        'DTaP',
        'Polio',
        'MMR',
        'Varicella',
        'Hepatitis_B',
        'Hepatitis_A',
        'Hib',
        'Pneumococcal',
        'Rotavirus',
        'Influenza',
        'COVID19',
      ],
      'DTaP': ['DTaP'],
      'Polio (IPV)': ['Polio'],
      'MMR': ['MMR'],
      'Varicella': ['Varicella'],
      'Hepatitis B': ['Hepatitis_B'],
      'Hepatitis A': ['Hepatitis_A'],
      'Hib': ['Hib'],
      'Pneumococcal (PCV)': ['Pneumococcal'],
      'Rotavirus': ['Rotavirus'],
      'Influenza': ['Influenza'],
      'COVID-19': ['COVID19'],
    };

    return vaccineMap[vaccine] ?? ['DTaP'];
  }

  /// Map UI status selection to backend status codes.
  List<String> _mapStatusToCode(String status) {
    switch (status) {
      case 'Active':
        return ['ACTIVE'];
      case 'Upcoming':
        return ['UPCOMING'];
      case 'Inactive':
        return ['INACTIVE'];
      default:
        return ['ACTIVE'];
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
        if (state.generationError != null &&
            state.generationError!.isNotEmpty) {
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
            title: 'School Immunization Report',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
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
                  showSelectAll: true,
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
                  showSelectAll: true,
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
                    onChanged: (v) =>
                        setState(() => _showParentInfo = v ?? false),
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing),
                ReportFormatSelector(
                  selectedFormat: _format,
                  onFormatChanged: (value) => setState(() => _format = value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
