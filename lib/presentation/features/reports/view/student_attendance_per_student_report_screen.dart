import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_context_helper.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/utils/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

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

  String _frequency = 'Monthly';
  late DateTime _periodDate;
  List<String> _selectedStudents = <String>[];
  late List<String> _selectedClassrooms;
  List<String> _availableStudents = <String>[];
  Map<String, String> _studentCodeByName = <String, String>{};
  Map<String, String> _classroomCodeByName = <String, String>{};
  bool _isLoadingStudents = false;
  int _fetchId = 0;
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _periodDate = DateTime(now.year, now.month, 1);
    
    _availableStudents = List<String>.from(widget.students);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStudentsForClassrooms(_selectedClassrooms);
    });
  }

  Future<Map<String, String>> _resolveClassroomNameToCodeMap() async {
    final cubitMap = context.read<ReportsCubit>().state.classroomNameToCode;
    if (cubitMap.isNotEmpty) {
      _classroomCodeByName.addAll(cubitMap);
      return Map<String, String>.from(_classroomCodeByName);
    }
    if (_classroomCodeByName.isNotEmpty) {
      return Map<String, String>.from(_classroomCodeByName);
    }
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isNotEmpty) {
        final classrooms =
            await serviceLocator<GetActiveClassroomsUseCase>()(
              schoolCode: schoolCode,
            );
        for (final c in classrooms) {
          _classroomCodeByName[c.name] = c.code;
        }
      }
    } catch (_) {}
    return Map<String, String>.from(_classroomCodeByName);
  }

  Future<void> _fetchStudentsForClassrooms(
    List<String> selectedClassroomNames,
  ) async {
    final currentFetchId = ++_fetchId;
    if (selectedClassroomNames.isEmpty) {
      if (!mounted) return;
      setState(() {
        _availableStudents = <String>[];
        _selectedStudents = <String>[];
        _studentCodeByName = <String, String>{};
        _isLoadingStudents = false;
      });
      return;
    }

    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();

      final classroomNameToCode = await _resolveClassroomNameToCodeMap();
      final classroomCodes =
          selectedClassroomNames
              .map((name) => classroomNameToCode[name])
              .whereType<String>()
              .where((c) => c.trim().isNotEmpty)
              .toSet()
              .toList();

      if (classroomCodes.isEmpty) {
        if (!mounted || currentFetchId != _fetchId) return;
        setState(() {
          _availableStudents = <String>[];
          _selectedStudents = <String>[];
          _isLoadingStudents = false;
        });
        return;
      }

      final getStudentClassroomListUseCase =
          serviceLocator<GetStudentClassroomListUseCase>();

      final results = await Future.wait(
        classroomCodes.map(
          (code) => getStudentClassroomListUseCase(
            schoolCode: schoolCode,
            classroomCode: code,
            status: const ['ACTIVE'],
            refresh: true,
          ).catchError((_) => <StudentClassroomItem>[]),
        ),
      );

      if (!mounted || currentFetchId != _fetchId) return;

      final newStudentCodeByName = <String, String>{};
      for (final studentList in results) {
        for (final s in studentList) {
          final fullName = s.fullName.trim();
          if (fullName.isNotEmpty && s.studentCode.trim().isNotEmpty) {
            newStudentCodeByName[fullName] = s.studentCode.trim();
          }
        }
      }

      final sortedNames =
          newStudentCodeByName.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _studentCodeByName = newStudentCodeByName;
        _availableStudents = sortedNames;
        _selectedStudents =
            _selectedStudents
                .where((s) => newStudentCodeByName.containsKey(s))
                .toList();
        _isLoadingStudents = false;
      });

      if (mounted) {
        context.read<ReportsCubit>().setStudentNames(
          sortedNames,
          nameToCodeMap: newStudentCodeByName,
        );
      }
    } catch (e) {
      if (!mounted || currentFetchId != _fetchId) return;
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  void _onGenerate() async {
    if (_selectedClassrooms.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one classroom',
        isError: true,
      );
      return;
    }

    if (_selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one student',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final reportsState = cubit.state;

    final mergedStudentNameToCode = <String, String>{
      ...reportsState.studentNameToCode,
      ..._studentCodeByName,
    };

    final studentCodes = resolveReportCodes(
      context: context,
      names: _selectedStudents,
      nameToCode: mergedStudentNameToCode,
      labelPlural: 'students',
    );
    if (studentCodes == null) return;

    final classroomNameToCode = await _resolveClassroomNameToCodeMap();
    final mergedClassroomNameToCode = <String, String>{
      ...reportsState.classroomNameToCode,
      ...classroomNameToCode,
    };

    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.isEmpty ? widget.classrooms : _selectedClassrooms,
      nameToCode: mergedClassroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

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
    final params = ReportRequestParams(
      reportType: ReportType.studentAttendancePerStudent,
      startDate: _periodDate,
      endDate: _rangeEndForFrequency(_periodDate),
      studentCodes: studentCodes,
      format: _format,
      schoolName: schoolName.isNotEmpty ? schoolName : null,
      roomCodes: classroomCodes,
    );

    unawaited(cubit.generateReport(params));
  }

  DateTime _rangeEndForFrequency(DateTime startDate) {
    switch (_frequency) {
      case 'Daily':
        return startDate;
      case 'Weekly':
        return startDate.add(const Duration(days: 6));
      case 'Monthly':
      default:
        return DateTime(startDate.year, startDate.month + 1, 0);
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

    return MultiBlocListener(
      listeners: [
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen:
              (previous, current) =>
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
          listenWhen:
              (previous, current) =>
                  previous.generationSuccess != current.generationSuccess,
          listener: (context, state) {
            if (state.generationSuccess != null &&
                state.generationSuccess!.isNotEmpty) {
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
            title: 'Attendance per Student',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CustomDropdown(
                        label: 'Frequency',
                        hintText: 'Select',
                        items: _frequencyOptions,
                        selectedItem: _frequency,
                        labelStyle: _labelStyle(responsive),
                        showAsterisk: true,
                        labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                        onSelect: (val) {
                          if (val == null) return;
                          setState(() => _frequency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ReportFieldLabel(label: 'Period'),
                          ReportMonthYearField(
                            initialMonth: _periodDate,
                            onMonthSelected:
                                (d) => setState(() => _periodDate = d),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.verticalSpacing),
                CustomMultiSelectDropdown(
                  label: 'Classroom',
                  hintText: 'Select Classroom',
                  items: widget.classrooms,
                  selectedItems: _selectedClassrooms,
                  onChanged: (s) {
                    setState(() => _selectedClassrooms = s);
                    _fetchStudentsForClassrooms(s);
                  },
                  showSelectAll: true,
                ),
                const ReportDefaultNote(
                  text: 'Note: All Classrooms will be selected by Default.',
                ),
                SizedBox(height: responsive.verticalSpacing),
                MultiSelectFilterField<String>(
                  label: 'Student',
                  hintText:
                      _isLoadingStudents
                          ? 'Loading Students...'
                          : (_selectedClassrooms.isEmpty
                              ? 'Select Classroom First'
                              : 'Select Students'),
                  items: _availableStudents,
                  selectedItems: _selectedStudents,
                  onChanged: (s) => setState(() => _selectedStudents = s),
                  itemToString: (item) => item,
                  singularLabel: 'Student',
                  pluralLabel: 'Students',
                  showSelectAll: true,
                  enableSearch: true,
                  searchHintText: 'Search Students',
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
