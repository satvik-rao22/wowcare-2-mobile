import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';
import 'package:wowcare/domain/features/student/usecases/get_immunization_settings_usecase.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/utils/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/school_context_helper.dart';

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
  static const List<String> _statusOptions = <String>[
    'Active',
    'Upcoming',
    'Inactive',
  ];

  // --- Vaccine state loaded from API ---
  List<String> _availableVaccines = <String>[];
  Map<String, String> _vaccineNameToCode = <String, String>{};
  bool _isLoadingVaccines = false;

  List<String> _selectedVaccines = <String>[];
  String _status = 'Active';
  List<String> _selectedClassrooms = <String>[];
  List<String> _selectedTags = <String>[];
  bool _showParentInfo = false;
  String _format = 'XLSX';
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVaccines();
    });
  }

  /// Fetches available vaccines from the backend immunization settings API
  /// and populates [_availableVaccines] and [_vaccineNameToCode].
  Future<void> _loadVaccines() async {
    if (!mounted) return;
    setState(() => _isLoadingVaccines = true);

    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();

      if (schoolCode.isEmpty) {
        AppLogger.w(
          '[ImmunizationReport] schoolCode is empty – skipping vaccine load',
        );
        if (mounted) setState(() => _isLoadingVaccines = false);
        return;
      }

      final vaccines = await serviceLocator<GetImmunizationSettingsUseCase>()(
        schoolCode: schoolCode,
      );

      AppLogger.d(
        '[ImmunizationReport] Loaded ${vaccines.length} vaccines from API: $vaccines',
      );

      final nameToCode = <String, String>{};
      final names = <String>[];

      for (final v in vaccines) {
        if (v.name.isNotEmpty && v.code.isNotEmpty) {
          nameToCode[v.name] = v.code;
          names.add(v.name);
        }
      }

      AppLogger.d('[ImmunizationReport] vaccineNameToCode map: $nameToCode');

      if (!mounted) return;
      setState(() {
        _availableVaccines = names;
        _vaccineNameToCode = nameToCode;
        // Pre-select all by default (mirrors web behaviour)
        _selectedVaccines = List<String>.from(names);
        _isLoadingVaccines = false;
      });
    } catch (e, st) {
      AppLogger.e('[ImmunizationReport] Failed to load vaccines: $e\n$st');
      if (mounted) setState(() => _isLoadingVaccines = false);
    }
  }

  void _onGenerate() async {
    if (_startDate.isAfter(_endDate)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Start date must be on or before end date',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final state = cubit.state;

    // ── Classroom codes ──────────────────────────────────────────────────────
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.isEmpty
          ? widget.classrooms
          : _selectedClassrooms,
      nameToCode: state.classroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    // ── Vaccine codes ────────────────────────────────────────────────────────
    // Map selected display names to backend VCC_* codes fetched from the API.
    AppLogger.d(
      '[ImmunizationReport] Selected vaccines (UI): $_selectedVaccines',
    );
    AppLogger.d(
      '[ImmunizationReport] vaccineNameToCode map: $_vaccineNameToCode',
    );

    List<String>? vaccineCodes;
    if (_selectedVaccines.isEmpty) {
      // Nothing selected → send all available codes (= no filter on backend)
      vaccineCodes = null;
    } else {
      vaccineCodes = _selectedVaccines
          .map((name) => _vaccineNameToCode[name])
          .where((code) => code != null && code.isNotEmpty)
          .cast<String>()
          .toList();
    }

    AppLogger.d(
      '[ImmunizationReport] Final vaccineCodes payload: $vaccineCodes',
    );

    // ── Tag codes ────────────────────────────────────────────────────────────
    final tagNameToCode = state.tagNameToCode;
    AppLogger.d('[ImmunizationReport] Selected tags (UI): $_selectedTags');
    AppLogger.d('[ImmunizationReport] tagNameToCode map: $tagNameToCode');

    List<String>? tagCodes;
    if (_selectedTags.isEmpty) {
      tagCodes = null; // backend returns all tags when not filtered
    } else {
      tagCodes = _selectedTags
          .map((name) => tagNameToCode[name])
          .where((code) => code != null && code.isNotEmpty)
          .cast<String>()
          .toList();
    }

    AppLogger.d('[ImmunizationReport] Final tagCodes payload: $tagCodes');

    // ── School name ──────────────────────────────────────────────────────────
    final schoolName = await SchoolContextHelper.getSchoolName();

    AppLogger.d('[ImmunizationReport] resolvedSchoolName=$schoolName');

    if (!mounted) return;

    if (schoolName == null || schoolName.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to resolve school name',
        isError: true,
      );
      return;
    }

    final params = SchoolImmunizationReportParams(
      reportType: ReportType.immunization,
      startDate: _startDate,
      endDate: _endDate,

      // Backend VCC_* codes resolved from the immunization settings API.
      // Pass an empty list when nothing is selected (backend returns all).
      vaccineCodes: vaccineCodes ?? const <String>[],

      // API expects "Active" / "Upcoming" / "Inactive" (title-case).
      statusFilters: <String>[_status],

      includeParentName: _showParentInfo,
      includeParentEmail: _showParentInfo,

      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,

      tagCodes: tagCodes,

      format: _format,
      schoolName: schoolName,
    );

    AppLogger.d('[ImmunizationReport] params=$params');

    unawaited(cubit.generateReport(params));
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
            title: 'School Immunization Report',
            onGenerate: (isGenerating || _isLoadingVaccines)
                ? null
                : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Vaccines ────────────────────────────────────────────────
                if (_isLoadingVaccines)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  CustomMultiSelectDropdown(
                    label: 'Vaccines',
                    hintText: 'Select',
                    isRequired: true,
                    items: _availableVaccines,
                    selectedItems: _selectedVaccines,
                    onChanged: (s) => setState(() => _selectedVaccines = s),
                    showSelectAll: true,
                    labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  ),
                SizedBox(height: responsive.verticalSpacing),
                // ── Status ──────────────────────────────────────────────────
                CustomDropdown(
                  label: 'Status',
                  hintText: 'Select',
                  items: _statusOptions,
                  selectedItem: _status,
                  labelStyle: _labelStyle(responsive),
                  showAsterisk: true,
                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  onSelect: (val) {
                    if (val == null) return;
                    setState(() => _status = val);
                  },
                ),
                SizedBox(height: responsive.verticalSpacing),
                // ── Classroom ───────────────────────────────────────────────
                CustomMultiSelectDropdown(
                  label: 'Classroom',
                  hintText: 'Select Classroom',
                  items: widget.classrooms,
                  isRequired: true,
                  selectedItems: _selectedClassrooms,
                  onChanged: (s) => setState(() => _selectedClassrooms = s),
                  showSelectAll: true,
                ),
                const ReportDefaultNote(
                  text: 'Note: All Classrooms will be selected by Default.',
                ),
                SizedBox(height: responsive.verticalSpacing),
                // ── Tag ─────────────────────────────────────────────────────
                CustomMultiSelectDropdown(
                  label: 'Tag',
                  hintText: 'Select Tag',
                  items: widget.tags,
                  isRequired: true,
                  selectedItems: _selectedTags,
                  onChanged: (s) => setState(() => _selectedTags = s),
                  showSelectAll: true,
                ),
                const ReportDefaultNote(
                  text: 'Note: All Tags will be selected by Default.',
                ),
                SizedBox(height: responsive.verticalSpacing),
                // ── Show parent info ─────────────────────────────────────────
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
                // ── Export format ────────────────────────────────────────────
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
