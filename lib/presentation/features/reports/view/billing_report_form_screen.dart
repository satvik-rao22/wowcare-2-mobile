import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../widgets/multi_select_filter_field.dart';

/// Generic date-range + format form for the billing reports that don't need extra filters
/// (Invoice, Payment Summary, Outstanding, Refund, Students & Billing Mapping).
class BillingReportFormScreen extends StatefulWidget {
  const BillingReportFormScreen({
    super.key,
    required this.reportType,
    required this.title,
    this.classrooms = const <String>[],
    this.students = const <String>[],
  });

  final ReportType reportType;
  final String title;
  final List<String> classrooms;
  final List<String> students;

  @override
  State<BillingReportFormScreen> createState() =>
      _BillingReportFormScreenState();
}

class _BillingReportFormScreenState extends State<BillingReportFormScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _format = 'XLSX';
  late DateTime _periodDate;
  List<String> _selectedStudents = <String>[];
  late List<String> _selectedClassrooms;
  List<String> _selectedInvoiceStatuses = <String>[];
  List<String> _availableStudents = <String>[];
  Map<String, String> _studentCodeByName = <String, String>{};
  Map<String, String> _classroomCodeByName = <String, String>{};
  bool _isLoadingStudents = false;
  int _fetchId = 0;
  String _folderClassGrouping = 'Daily';
  String _periodType = 'Monthly';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _periodDate = DateTime(now.year, now.month, 1);
    _selectedClassrooms = <String>[];
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
        final classrooms = await serviceLocator<GetActiveClassroomsUseCase>()(
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
      final targetClassroomNames = selectedClassroomNames.isEmpty
          ? widget.classrooms
          : selectedClassroomNames;
      final classroomCodes = targetClassroomNames
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

      final sortedNames = newStudentCodeByName.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _studentCodeByName = newStudentCodeByName;
        _availableStudents = sortedNames;
        _selectedStudents = _selectedStudents
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

  Future<void> _onGenerate() async {
    if (_selectedStudents.isNotEmpty && _selectedClassrooms.isNotEmpty) {
      // Allow proceeding if they selected classrooms and students.
    }

    DateTime reqStartDate = _startDate;
    DateTime? reqEndDate = _endDate;

    if (widget.reportType == ReportType.billingOutstanding) {
      reqEndDate = null;
    }

    if (widget.reportType == ReportType.billingStudentMapping &&
        _periodType == 'Monthly') {
      reqStartDate = DateTime(_periodDate.year, _periodDate.month, 1);
      reqEndDate = DateTime(
        _periodDate.year,
        _periodDate.month + 1,
        0,
        23,
        59,
        59,
      );
    }

    if (reqEndDate != null && reqEndDate.isBefore(reqStartDate)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'End date cannot be before Start date',
        isError: true,
      );
      return;
    }

    final storage = serviceLocator<StorageService>();
    final schoolName = (await storage.getString(StorageKeys.schoolName) ?? '')
        .trim();

    final cubit = context.read<ReportsCubit>();
    final reportsState = cubit.state;

    final mergedStudentNameToCode = <String, String>{
      ...reportsState.studentNameToCode,
      ..._studentCodeByName,
    };

    final targetStudentNames = _selectedStudents.isEmpty
        ? _availableStudents
        : _selectedStudents;

    final studentCodes = targetStudentNames
        .map((name) => mergedStudentNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final classroomNameToCode = await _resolveClassroomNameToCodeMap();
    final mergedClassroomNameToCode = <String, String>{
      ...reportsState.classroomNameToCode,
      ...classroomNameToCode,
    };

    final targetClassroomNames = _selectedClassrooms.isEmpty
        ? widget.classrooms
        : _selectedClassrooms;

    final classroomCodes = targetClassroomNames
        .map((name) => mergedClassroomNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    context.read<ReportsCubit>().generateReport(
      ReportRequestParams(
        reportType: widget.reportType,
        startDate: reqStartDate,
        endDate: reqEndDate,
        format: _format,
        schoolName: schoolName.isNotEmpty ? schoolName : null,
        roomCodes: classroomCodes.isNotEmpty ? classroomCodes : null,
        studentCodes: studentCodes.isNotEmpty ? studentCodes : null,
        periodType: widget.reportType == ReportType.billingStudentMapping
            ? _periodType.toLowerCase()
            : null,
        folderClassGrouping:
            widget.reportType == ReportType.billingPaymentSummary
            ? _folderClassGrouping.toUpperCase()
            : null,
        invoiceStatuses:
            widget.reportType == ReportType.billingInvoice &&
                _selectedInvoiceStatuses.isNotEmpty
            ? _selectedInvoiceStatuses.map((s) => s.toUpperCase()).toList()
            : null,
      ),
    );
  }

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
                  // Pop (not context.go) — this screen was pushed via plain
                  // Navigator.push, so only popping actually dismisses it;
                  // the hub's own .then((success) => tab 0) callback reacts
                  // to the pop(true) result.
                  final reportToReturn = state.generatedReport;
                  context.read<ReportsCubit>().clearGeneratedReport();
                  Navigator.of(context).pop(reportToReturn ?? true);
                });
              }
            }
          },
        ),
      ],
      child: ReportFormLayout(
        title: widget.title,
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reportType == ReportType.billingStudentMapping) ...[
              CustomDropdown(
                label: 'Report Period Type',
                hintText: 'Select',
                items: const ['Monthly', 'Custom'],
                selectedItem: _periodType,
                showAsterisk: true,
                onSelect: (val) {
                  if (val != null) {
                    setState(() => _periodType = val);
                  }
                },
              ),
              SizedBox(height: responsive.verticalSpacing),
              if (_periodType == 'Monthly') ...[
                const ReportFieldLabel(label: 'Date'),
                ReportMonthYearField(
                  initialMonth: _periodDate,
                  onMonthSelected: (d) => setState(() => _periodDate = d),
                ),
              ] else ...[
                const ReportFieldLabel(label: 'Date Range'),
                CustomDateTimeField(
                  hasLabel: false,
                  isRangePicker: true,
                  fetchInitialTime: false,
                  initialDate: _startDate,
                  onRangeSelected: (start, end) {
                    if (end != null) {
                      setState(() {
                        _startDate = start;
                        _endDate = end;
                      });
                    }
                  },
                ),
              ],
              SizedBox(height: responsive.verticalSpacing),
              const ReportFieldLabel(label: 'Export Format'),
              ReportFormatSelector(
                selectedFormat: _format,
                onFormatChanged: (value) => setState(() => _format = value),
                showLabel: false,
              ),
              SizedBox(height: responsive.verticalSpacing),
              CustomMultiSelectDropdown(
                label: 'Classroom',
                hintText: 'Select Classrooms',
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
            ] else if (widget.reportType == ReportType.billingOutstanding) ...[
              const ReportFieldLabel(label: 'As-Of Date'),
              CustomDateTimeField(
                hasLabel: false,
                fetchInitialTime: false,
                initialDate: _startDate,
                onDateSelected: (d) => setState(() => _startDate = d),
              ),
              SizedBox(height: responsive.verticalSpacing),
              const ReportFieldLabel(label: 'Export Format'),
              ReportFormatSelector(
                selectedFormat: _format,
                onFormatChanged: (value) => setState(() => _format = value),
                showLabel: false,
              ),
              SizedBox(height: responsive.verticalSpacing),
            ] else ...[
              const ReportFieldLabel(label: 'Start Date'),
              CustomDateTimeField(
                hasLabel: false,
                fetchInitialTime: false,
                initialDate: _startDate,
                onDateSelected: (d) => setState(() => _startDate = d),
              ),
              SizedBox(height: responsive.verticalSpacing),
              const ReportFieldLabel(label: 'End Date'),
              CustomDateTimeField(
                hasLabel: false,
                fetchInitialTime: false,
                initialDate: _endDate,
                onDateSelected: (d) => setState(() => _endDate = d),
              ),
              const ReportFieldLabel(label: 'Export Format'),
              ReportFormatSelector(
                selectedFormat: _format,
                onFormatChanged: (value) => setState(() => _format = value),
                showLabel: false,
              ),
              SizedBox(height: responsive.verticalSpacing),
            ],
            if (widget.reportType == ReportType.billingPaymentSummary) ...[
              CustomDropdown(
                label: 'Grouping',
                hintText: 'Select Grouping',
                items: const ['Daily', 'Weekly', 'Monthly'],
                initialValue: _folderClassGrouping,
                onSelect: (value) {
                  if (value != null) {
                    setState(() => _folderClassGrouping = value);
                  }
                },
              ),
              SizedBox(height: responsive.verticalSpacing),
            ],
            if (widget.reportType == ReportType.billingInvoice) ...[
              // Add the Optional filters:  Payment method (Card, ACH, Cash)
              CustomMultiSelectDropdown(
                label: 'Invoice Status',
                hintText: "Select Status",
                isRequired: true,
                items: const ["Paid", "Unpaid", "Partial"],
                selectedItems: _selectedInvoiceStatuses,
                onChanged: (s) {
                  setState(() => _selectedInvoiceStatuses = s);
                },
                showSelectAll: true,
              ),
              SizedBox(height: responsive.verticalSpacing),
              CustomMultiSelectDropdown(
                label: 'Classroom',
                hintText: 'Select Classroom',
                items: widget.classrooms,
                isRequired: true,
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
                hintText: _isLoadingStudents
                    ? 'Loading Students...'
                    : 'Select Students',
                items: _availableStudents,
                isRequired: true,
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
            ],
          ],
        ),
      ),
    );
  }
}
