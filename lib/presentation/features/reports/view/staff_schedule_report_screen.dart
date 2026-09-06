import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/utils/report_filter_defaults.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/school_context_helper.dart';
import '../../../../domain/features/reports/entities/report_type.dart';
import '../../../../domain/features/reports/usecases/staff_scheduling_report_params.dart';
import '../utils/report_code_resolver.dart';

class StaffScheduleReportScreen extends StatefulWidget {
  const StaffScheduleReportScreen({super.key, required this.classrooms});

  static const String routeName = '/reports/staff/schedule';

  final List<String> classrooms;

  @override
  State<StaffScheduleReportScreen> createState() =>
      _StaffScheduleReportScreenState();
}

class _StaffScheduleReportScreenState extends State<StaffScheduleReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<String> _selectedClassrooms = <String>[];
  String _format = 'XLSX';
  List<String> _availableClassrooms = <String>[];
  Map<String, String> _classroomNameToCode = <String, String>{};
  final ReportFilterDefault _classroomFilter = ReportFilterDefault();

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = now;
    _endDate = now.add(const Duration(days: 6));

    _availableClassrooms = List<String>.from(widget.classrooms);
    // All Classrooms are selected by default until the user changes it.
    _selectedClassrooms = List<String>.from(widget.classrooms);
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
        final classrooms = await serviceLocator<GetActiveClassroomsUseCase>()(
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
            _selectedClassrooms = _classroomFilter.resolve(
              options: names,
              current: _selectedClassrooms,
            );
          });
        }
      }
    } catch (e) {
      AppLogger.e('[STAFF-SCHEDULE-UI] Failed to load staff classrooms: $e');
    }
  }

  Future<void> _onGenerate() async {
    AppLogger.d('[STAFF-SCHEDULE-UI] Generate button tapped');

    if (_endDate.isBefore(_startDate)) {
      AppLogger.w(
        '[STAFF-SCHEDULE-UI] Generation blocked: End date before Start date',
      );
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'End date cannot be before Start date',
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
      names: _selectedClassrooms.isEmpty
          ? widget.classrooms
          : _selectedClassrooms,
      nameToCode: nameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;

    AppLogger.d(
      '[STAFF-SCHEDULE-UI] Selected classrooms: $_selectedClassrooms',
    );
    AppLogger.d('[STAFF-SCHEDULE-UI] Resolved classroomCodes: $classroomCodes');

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
    final params = StaffSchedulingReportParams(
      reportType: ReportType.staffScheduling,
      startDate: _startDate,
      endDate: _endDate,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      format: _format,
      schoolName: schoolName,
    );

    AppLogger.d('[STAFF-SCHEDULE-UI] Calling cubit.generateReport()');
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
                message: 'Report generated successfully',
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  context.read<ReportsCubit>().clearGeneratedReport();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                  }
                });
              }
            }
          },
        ),
      ],
      child: ReportFormLayout(
        title: 'Staff Scheduling',
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportFieldLabel(label: 'Start Date'),
            CustomDateTimeField(
              hasLabel: false,
              dateFormat: 'MM/dd/yyyy',
              fetchInitialTime: false,
              initialDate: _startDate,
              onDateSelected: (d) => setState(() => _startDate = d),
            ),
            SizedBox(height: responsive.verticalSpacing),
            const ReportFieldLabel(label: 'End Date'),
            CustomDateTimeField(
              hasLabel: false,
              dateFormat: 'MM/dd/yyyy',
              fetchInitialTime: false,
              initialDate: _endDate,
              onDateSelected: (d) => setState(() => _endDate = d),
            ),
            SizedBox(height: responsive.verticalSpacing),
            CustomMultiSelectDropdown(
              label: 'Classroom',
              hintText: 'Select Classroom',
              items: classroomItems,
              isRequired: true,
              selectedItems: _selectedClassrooms,
              onChanged: (s) => setState(
                () => _selectedClassrooms = _classroomFilter.userSelected(s),
              ),
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
      ),
    );
  }
}
