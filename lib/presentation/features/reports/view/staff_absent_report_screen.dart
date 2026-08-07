import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/utils/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../core/util/school_context_helper.dart';

class StaffAbsentReportScreen extends StatefulWidget {
  const StaffAbsentReportScreen({super.key, required this.classrooms});

  static const String routeName = '/reports/staff/absent';

  final List<String> classrooms;

  @override
  State<StaffAbsentReportScreen> createState() =>
      _StaffAbsentReportScreenState();
}

class _StaffAbsentReportScreenState extends State<StaffAbsentReportScreen> {
  late final ValueNotifier<DateTime> _fromDate;
  late final ValueNotifier<DateTime> _toDate;
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('PDF');
  List<String> _availableClassrooms = <String>[];
  Map<String, String> _classroomNameToCode = <String, String>{};

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _fromDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _toDate = ValueNotifier<DateTime>(DateTime(now.year, now.month + 1, 0));
    
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
            _selectedClassrooms.value = <String>[];
          });
        }
      }
    } catch (e) {
      AppLogger.e('[STAFF-ABSENT-UI] Failed to load staff classrooms: $e');
    }
  }

  @override
  void dispose() {
    _fromDate.dispose();
    _toDate.dispose();
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  void _onGenerate() async {
    AppLogger.d('[STAFF-ABSENT-UI] Generate button tapped');

    if (_toDate.value.isBefore(_fromDate.value)) {
      AppLogger.w(
        '[STAFF-ABSENT-UI] Generation blocked: To date before From date',
      );
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'To date cannot be before From date',
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
      names: _selectedClassrooms.value.isEmpty ? widget.classrooms : _selectedClassrooms.value,
      nameToCode: nameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    AppLogger.d(
      '[STAFF-ABSENT-UI] Selected classrooms: ${_selectedClassrooms.value}',
    );
    AppLogger.d(
      '[STAFF-ABSENT-UI] Resolved roomCodes: $classroomCodes',
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

    AppLogger.d('[STAFF-ABSENT-UI] Creating report params');
    final params = ReportRequestParams(
      reportType: ReportType.staffAbsent,
      format: _format.value, // PDF or XLSX
      startDate: _fromDate.value,
      endDate: _toDate.value,
      roomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      schoolName: schoolName,
    );

    AppLogger.d('[STAFF-ABSENT-UI] Calling cubit.generateReport()');
    unawaited(cubit.generateReport(params));
  }

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
              AppLogger.e('[REPORT_GENERATION_ERROR] ${state.generationError}');
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
            title: 'Absent Report',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: 'From'),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _fromDate,
                  builder: (_, date, __) => CustomDateTimeField(
                    hasLabel: false,
                    fetchInitialTime: false,
                    initialDate: date,
                    onDateSelected: (d) => _fromDate.value = d,
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing),
                const ReportFieldLabel(label: 'To'),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _toDate,
                  builder: (_, date, __) => CustomDateTimeField(
                    hasLabel: false,
                    fetchInitialTime: false,
                    initialDate: date,
                    onDateSelected: (d) => _toDate.value = d,
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: 'Classroom',
                    hintText: 'Select Classroom',
                    items: classroomItems,
                    selectedItems: selected,
                    onChanged: (s) => _selectedClassrooms.value = s,
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: 'Note: All Classrooms will be selected by Default.',
                ),
                SizedBox(height: responsive.verticalSpacing),
                const ReportFieldLabel(label: 'Export Format'),
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
