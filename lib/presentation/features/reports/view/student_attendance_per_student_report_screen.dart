import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/model/report_filter_defaults.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/widgets/resolve_school_name.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class StudentAttendancePerStudentReportScreen extends StatefulWidget {
  const StudentAttendancePerStudentReportScreen({
    super.key,
    this.students = const <String>[],
    required this.classrooms,
  });

  static const String routeName = '/reports/student/attendance-per-student';

  final List<String> students;
  final List<String> classrooms;

  @override
  State<StudentAttendancePerStudentReportScreen> createState() =>
      _StudentAttendancePerStudentReportScreenState();
}

class _StudentAttendancePerStudentReportScreenState
    extends State<StudentAttendancePerStudentReportScreen> {
  static const List<String> _frequencyOptions = <String>[
    'Daily',
    'Weekly',
    'Monthly',
  ];

  // §2.2 bucket B — form inputs. Final notifier fields, all disposed below.
  final ValueNotifier<String> _frequency = ValueNotifier<String>('Monthly');
  late final ValueNotifier<DateTime> _periodDate;
  final ValueNotifier<List<String>> _selectedStudents =
      ValueNotifier<List<String>>(<String>[]);
  late final ValueNotifier<List<String>> _selectedClassrooms;
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  // §2.2 bucket A — the student list, its name→code map and the loading flag
  // are API-owned and live on ReportsCubit. No local copies.
  final ReportFilterDefault _studentFilter = ReportFilterDefault();

  @override
  void dispose() {
    _frequency.dispose();
    _periodDate.dispose();
    _selectedStudents.dispose();
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _periodDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));

    // All Classrooms / All Students are selected by default until the user
    // changes them; the post-frame fetch below seeds the students for every
    // classroom.
    _selectedClassrooms = ValueNotifier<List<String>>(
      List<String>.from(widget.classrooms),
    );
    _selectedStudents.value = List<String>.from(widget.students);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsCubit>().loadFormStudents(
        classroomNames: _selectedClassrooms.value.isEmpty
            ? widget.classrooms
            : _selectedClassrooms.value,
      );
    });
  }

  void _onGenerate() async {
    if (_selectedClassrooms.value.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.pleaseSelectAtLeastOneClassroom,
        isError: true,
      );
      return;
    }

    if (_selectedStudents.value.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.pleaseSelectAtLeastOneStudent,
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final reportsState = cubit.state;

    final studentCodes = resolveReportCodes(
      context: context,
      names: _selectedStudents.value,
      nameToCode: reportsState.studentNameToCode,
      labelPlural: 'students',
    );
    if (studentCodes == null) return;

    final mergedClassroomNameToCode = await cubit.ensureClassroomNameToCode();

    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value.isEmpty
          ? widget.classrooms
          : _selectedClassrooms.value,
      nameToCode: mergedClassroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;
    final params = ReportRequestParams(
      reportType: ReportType.studentAttendancePerStudent,
      startDate: _periodDate.value,
      endDate: _rangeEndForFrequency(_periodDate.value),
      studentCodes: studentCodes,
      format: _format.value,
      schoolName: schoolName.isNotEmpty ? schoolName : null,
      roomCodes: classroomCodes,
    );

    unawaited(cubit.generateReport(params));
  }

  DateTime _rangeEndForFrequency(DateTime startDate) {
    switch (_frequency.value) {
      case 'Daily':
        return startDate;
      case 'Weekly':
        return startDate.add(const Duration(days: 6));
      case 'Monthly':
      default:
        return DateTime(startDate.year, startDate.month + 1, 0);
    }
  }

  TextStyle _labelStyle(BuildContext context) =>
      AppTextStyles.reportsFieldLabel(
        fontSize: context.responsive(compact: 14.0, medium: 16.0),
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Re-resolve the student selection whenever the cubit publishes a new
        // list — the rule the old in-widget fetch applied inline.
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.studentNames != current.studentNames,
          listener: (context, state) {
            _selectedStudents.value = _studentFilter.resolve(
              options: state.studentNames,
              current: _selectedStudents.value,
            );
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
                state.generationSuccess!.isNotEmpty) {
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
            title: ReportsStrings.studentAttendancePerStudentName,
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: _frequency,
                        builder: (_, v, __) => CustomDropdown(
                          label: ReportsStrings.frequency,
                          hintText: ReportsStrings.select,
                          items: _frequencyOptions,
                          selectedItem: v,
                          labelStyle: _labelStyle(context),
                          showAsterisk: true,
                          labelBottomSpacing: context.isTablet ? 8.0 : 6.0,
                          onSelect: (val) {
                            if (val == null) return;
                            _frequency.value = val;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ReportFieldLabel(label: ReportsStrings.period),
                          ValueListenableBuilder<DateTime>(
                            valueListenable: _periodDate,
                            builder: (_, v, __) => ReportMonthYearField(
                              initialMonth: v,
                              onMonthSelected: (d) => _periodDate.value = d,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, v, __) => CustomMultiSelectDropdown(
                    label: ReportsStrings.classroom,
                    hintText: ReportsStrings.selectClassroom,
                    items: widget.classrooms,
                    isRequired: true,
                    selectedItems: v,
                    onChanged: (s) {
                      _selectedClassrooms.value = s;
                      // Clearing the filter means "no classrooms", not "all"
                      // — re-expanding it here silently put every classroom's
                      // students back into a report the user had just narrowed,
                      // which is exactly what ReportFilterDefault forbids.
                      context.read<ReportsCubit>().loadFormStudents(
                        classroomNames: s,
                      );
                    },
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: ReportsStrings.noteAllClassroomsWillBeSelectedByDefault,
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                // The student list and its loading flag are cubit-owned
                // (§2.2 bucket A); only the selection is local.
                BlocSelector<
                  ReportsCubit,
                  ReportsState,
                  ({List<String> items, bool loading})
                >(
                  selector: (state) => (
                    items: state.studentNames,
                    loading: state.formStudentsLoading,
                  ),
                  builder: (context, students) => ValueListenableBuilder<List<String>>(
                    valueListenable: _selectedClassrooms,
                    builder: (_, classrooms, __) =>
                        ValueListenableBuilder<List<String>>(
                          valueListenable: _selectedStudents,
                          builder: (_, selected, __) =>
                              MultiSelectFilterField<String>(
                                label: ReportsStrings.tabStudent,
                                // An empty student list has two very different
                                // causes; say which one the user is looking at.
                                hintText: students.loading
                                    ? ReportsStrings.loadingStudents
                                    : classrooms.isEmpty
                                    ? ReportsStrings.selectClassroomFirst
                                    : ReportsStrings.selectStudents,
                                items: students.items,
                                isRequired: true,
                                selectedItems: selected,
                                onChanged: (s) => _selectedStudents.value =
                                    _studentFilter.userSelected(s),
                                itemToString: (item) => item,
                                singularLabel: ReportsStrings.tabStudent,
                                pluralLabel: ReportsStrings.students,
                                showSelectAll: true,
                                enableSearch: true,
                                searchHintText: ReportsStrings.searchStudents,
                              ),
                        ),
                  ),
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
          );
        },
      ),
    );
  }
}
