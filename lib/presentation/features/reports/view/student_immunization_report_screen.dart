import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_context_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

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

  // §2.2 bucket A — the vaccine list, its name→code map and the loading flag
  // are API-owned and live on ReportsCubit. No local copies.

  // §2.2 bucket B — form inputs. Final notifier fields, all disposed below.
  final ValueNotifier<List<String>> _selectedVaccines =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _status = ValueNotifier<String>('Active');
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<List<String>> _selectedTags = ValueNotifier<List<String>>(
    <String>[],
  );
  final ValueNotifier<bool> _showParentInfo = ValueNotifier<bool>(false);
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');
  late final ValueNotifier<DateTime> _startDate;
  late final ValueNotifier<DateTime> _endDate;

  @override
  void dispose() {
    _selectedVaccines.dispose();
    _status.dispose();
    _selectedClassrooms.dispose();
    _selectedTags.dispose();
    _showParentInfo.dispose();
    _format.dispose();
    _startDate.dispose();
    _endDate.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _endDate = ValueNotifier<DateTime>(now);
    // All Classrooms are selected by default until the user changes it.
    _selectedClassrooms.value = List<String>.from(widget.classrooms);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsCubit>().loadVaccines();
    });
  }

  void _onGenerate() async {
    if (_startDate.value.isAfter(_endDate.value)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.startDateMustBeOnOrBeforeEndDate,
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final state = cubit.state;

    // ── Classroom codes ──────────────────────────────────────────────────────
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value.isEmpty
          ? widget.classrooms
          : _selectedClassrooms.value,
      nameToCode: state.classroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    // ── Vaccine codes ────────────────────────────────────────────────────────
    // Map selected display names to backend VCC_* codes fetched from the API.
    AppLogger.d(
      '[ImmunizationReport] Selected vaccines (UI): ${_selectedVaccines.value}',
    );
    AppLogger.d(
      '[ImmunizationReport] vaccineNameToCode map: '
      '${cubit.state.vaccineNameToCode}',
    );

    List<String>? vaccineCodes;
    if (_selectedVaccines.value.isEmpty) {
      // Nothing selected → send all available codes (= no filter on backend)
      vaccineCodes = null;
    } else {
      vaccineCodes = _selectedVaccines.value
          .map((name) => cubit.state.vaccineNameToCode[name])
          .where((code) => code != null && code.isNotEmpty)
          .cast<String>()
          .toList();
    }

    AppLogger.d(
      '[ImmunizationReport] Final vaccineCodes payload: $vaccineCodes',
    );

    // ── Tag codes ────────────────────────────────────────────────────────────
    final tagNameToCode = state.tagNameToCode;
    AppLogger.d(
      '[ImmunizationReport] Selected tags (UI): ${_selectedTags.value}',
    );
    AppLogger.d('[ImmunizationReport] tagNameToCode map: $tagNameToCode');

    List<String>? tagCodes;
    if (_selectedTags.value.isEmpty) {
      tagCodes = null; // backend returns all tags when not filtered
    } else {
      tagCodes = _selectedTags.value
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
        message: ReportsStrings.unableToResolveSchoolName,
        isError: true,
      );
      return;
    }

    final params = SchoolImmunizationReportParams(
      reportType: ReportType.immunization,
      startDate: _startDate.value,
      endDate: _endDate.value,

      // Backend VCC_* codes resolved from the immunization settings API.
      // Pass an empty list when nothing is selected (backend returns all).
      vaccineCodes: vaccineCodes ?? const <String>[],

      // API expects "Active" / "Upcoming" / "Inactive" (title-case).
      statusFilters: <String>[_status.value],

      includeParentName: _showParentInfo.value,
      includeParentEmail: _showParentInfo.value,

      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,

      tagCodes: tagCodes,

      format: _format.value,
      schoolName: schoolName,
    );

    AppLogger.d('[ImmunizationReport] params=$params');

    unawaited(cubit.generateReport(params));
  }

  TextStyle _labelStyle(BuildContext context) =>
      AppTextStyles.reportsFieldLabel(
        fontSize: context.responsive(compact: 14.0, medium: 16.0),
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Pre-select every vaccine the first time the list arrives, which is
        // what the old in-widget _loadVaccines() did inline (mirrors web).
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.vaccineNames != current.vaccineNames,
          listener: (context, state) {
            _selectedVaccines.value = List<String>.from(state.vaccineNames);
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

                  context.read<ReportsCubit>().clearGeneratedReport();
                  context.pop(const ReportGeneratedRefreshList());
                });
              }
            }
          },
        ),
      ],
      child:
          BlocSelector<
            ReportsCubit,
            ReportsState,
            ({bool isGenerating, bool vaccinesLoading, List<String> vaccines})
          >(
            selector: (state) => (
              isGenerating: state.isGenerating,
              vaccinesLoading: state.vaccinesLoading,
              vaccines: state.vaccineNames,
            ),
            builder: (context, data) {
              final isGenerating = data.isGenerating;
              return ReportFormLayout(
                title: ReportsStrings.studentImmunizationName,
                onGenerate: (isGenerating || data.vaccinesLoading)
                    ? null
                    : _onGenerate,
                isLoading: isGenerating,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Vaccines ────────────────────────────────────────────────
                    if (data.vaccinesLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      ValueListenableBuilder<List<String>>(
                        valueListenable: _selectedVaccines,
                        builder: (_, selected, __) => CustomMultiSelectDropdown(
                          label: ReportsStrings.vaccines,
                          hintText: ReportsStrings.select,
                          isRequired: true,
                          items: data.vaccines,
                          selectedItems: selected,
                          onChanged: (s) => _selectedVaccines.value = s,
                          showSelectAll: true,
                          labelBottomSpacing: context.isTablet ? 8.0 : 6.0,
                        ),
                      ),
                    SizedBox(
                      height: context.responsive(compact: 16.0, medium: 24.0),
                    ),
                    // ── Status ──────────────────────────────────────────────────
                    ValueListenableBuilder<String>(
                      valueListenable: _status,
                      builder: (_, v, __) => CustomDropdown(
                        label: ReportsStrings.status,
                        hintText: ReportsStrings.select,
                        items: _statusOptions,
                        selectedItem: v,
                        labelStyle: _labelStyle(context),
                        showAsterisk: true,
                        labelBottomSpacing: context.isTablet ? 8.0 : 6.0,
                        onSelect: (val) {
                          if (val == null) return;
                          _status.value = val;
                        },
                      ),
                    ),
                    SizedBox(
                      height: context.responsive(compact: 16.0, medium: 24.0),
                    ),
                    // ── Classroom ───────────────────────────────────────────────
                    ValueListenableBuilder<List<String>>(
                      valueListenable: _selectedClassrooms,
                      builder: (_, v, __) => CustomMultiSelectDropdown(
                        label: ReportsStrings.classroom,
                        hintText: ReportsStrings.selectClassroom,
                        items: widget.classrooms,
                        isRequired: true,
                        selectedItems: v,
                        onChanged: (s) => _selectedClassrooms.value = s,
                        showSelectAll: true,
                      ),
                    ),
                    const ReportDefaultNote(
                      text: ReportsStrings
                          .noteAllClassroomsWillBeSelectedByDefault,
                    ),
                    SizedBox(
                      height: context.responsive(compact: 16.0, medium: 24.0),
                    ),
                    // ── Tag ─────────────────────────────────────────────────────
                    ValueListenableBuilder<List<String>>(
                      valueListenable: _selectedTags,
                      builder: (_, v, __) => CustomMultiSelectDropdown(
                        label: ReportsStrings.tag,
                        hintText: ReportsStrings.selectTag,
                        items: widget.tags,
                        isRequired: true,
                        selectedItems: v,
                        onChanged: (s) => _selectedTags.value = s,
                        showSelectAll: true,
                      ),
                    ),
                    const ReportDefaultNote(
                      text: ReportsStrings.noteAllTagsWillBeSelectedByDefault,
                    ),
                    SizedBox(
                      height: context.responsive(compact: 16.0, medium: 24.0),
                    ),
                    // ── Show parent info ─────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _showParentInfo,
                        builder: (_, v, __) => CustomCheckbox(
                          value: v,
                          label: ReportsStrings.showParentNameAndEmails,
                          onChanged: (v) => _showParentInfo.value = v ?? false,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: context.responsive(compact: 16.0, medium: 24.0),
                    ),
                    // ── Export format ────────────────────────────────────────────
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
              );
            },
          ),
    );
  }
}
