import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'dart:async';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/presentation/features/reports/utils/report_code_resolver.dart';

import '../widgets/multi_select_filter_field.dart';

class BillingTransactionReportScreen extends StatefulWidget {
  const BillingTransactionReportScreen({super.key});

  static const String routeName = '/reports/billing/transaction';

  @override
  State<BillingTransactionReportScreen> createState() =>
      _BillingTransactionReportScreenState();
}

class _BillingTransactionReportScreenState
    extends State<BillingTransactionReportScreen> {
  static const List<String> _transactionOptions = <String>[
    'Success',
    'Failed',
    'Refunded',
  ];

  static const List<String> _transactionTypeOptions = <String>[
    'Cash',
    'Cheque',
    'Online',
    'Others',
  ];

  late DateTime _startDate;
  late DateTime _endDate;
  List<String> _selectedTransactionStatuses = <String>[];
  List<String> _selectedTransactionTypes = <String>[];
  List<String> _selectedPaymentMethods = <String>[];
  String _format = 'XLSX';
  List<String> _availableStudents = <String>[];
  bool _isLoadingStudents = false;
  List<String> _selectedStudents = <String>[];

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchStudents();
      }
    });
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();

      final getActiveClassroomsUseCase =
          serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );

      final classroomCodes = classrooms.map((c) => c.code).toList();

      if (classroomCodes.isEmpty) {
        if (!mounted) return;
        setState(() {
          _availableStudents = <String>[];
          _selectedStudents = <String>[];
          _isLoadingStudents = false;
        });
        return;
      }

      final getStudentClassroomListUseCase =
          serviceLocator<GetStudentClassroomListUseCase>();

      final results = <List<StudentClassroomItem>>[];
      for (final code in classroomCodes) {
        try {
          final students = await getStudentClassroomListUseCase(
            schoolCode: schoolCode,
            classroomCode: code,
            status: const ['ACTIVE'],
            refresh: true,
          );
          results.add(students);
        } catch (_) {
          results.add(<StudentClassroomItem>[]);
        }
      }

      if (!mounted) return;

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
        _availableStudents = sortedNames;
        if (_selectedStudents.isEmpty) {
          _selectedStudents = List<String>.from(sortedNames);
        } else {
          _selectedStudents = _selectedStudents
              .where((s) => newStudentCodeByName.containsKey(s))
              .toList();
        }
        _isLoadingStudents = false;
      });

      if (mounted) {
        context.read<ReportsCubit>().setStudentNames(
          sortedNames,
          nameToCodeMap: newStudentCodeByName,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _onGenerate() async {
    if (_endDate.isBefore(_startDate)) {
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

    final reportsState = context.read<ReportsCubit>().state;
    final studentCodes = resolveReportCodes(
      context: context,
      names: _selectedStudents,
      nameToCode: reportsState.studentNameToCode,
      labelPlural: 'students',
    );
    if (studentCodes == null) return;

    context.read<ReportsCubit>().generateReport(
      ReportRequestParams(
        reportType: ReportType.billingTransaction,
        startDate: _startDate,
        endDate: _endDate,
        format: _format,
        studentCodes: studentCodes,
        schoolName: schoolName.isNotEmpty ? schoolName : null,
        transactionStatuses: _selectedTransactionStatuses.isNotEmpty
            ? _selectedTransactionStatuses
            : null,
        transactionTypes: _selectedTransactionTypes.isNotEmpty
            ? _selectedTransactionTypes
            : null,
        paymentMethods: _selectedPaymentMethods.isNotEmpty
            ? _selectedPaymentMethods
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
                  context.read<ReportsCubit>().clearGeneratedReport();
                  Navigator.of(context).pop(true);
                });
              }
            }
          },
        ),
      ],
      child: ReportFormLayout(
        title: 'Transaction Report',
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportFieldLabel(label: 'Start Date'),
            CustomDateTimeField(
              hasLabel: false,
              dateFormat: "dd-MM-yyyy",
              fetchInitialTime: false,
              initialDate: _startDate,
              onDateSelected: (d) => setState(() => _startDate = d),
            ),
            SizedBox(height: responsive.verticalSpacing),
            const ReportFieldLabel(label: 'End Date'),
            CustomDateTimeField(
              hasLabel: false,
              dateFormat: "dd-MM-yyyy",
              fetchInitialTime: false,
              initialDate: _endDate,
              onDateSelected: (d) => setState(() => _endDate = d),
            ),
            SizedBox(height: responsive.verticalSpacing),
            const ReportFieldLabel(label: 'Export Format'),
            ReportFormatSelector(
              selectedFormat: _format,
              onFormatChanged: (value) => setState(() => _format = value),
              showLabel: false,
            ),
            SizedBox(height: responsive.verticalSpacing),

            CustomMultiSelectDropdown(
              label: 'Payment Method',
              hintText: "Select Payment Methods",
              items: const ["Card", "ACH", "Cash"],
              selectedItems: _selectedPaymentMethods,
              showSelectAll: true,
              isRequired: true,
              onChanged: (s) => setState(() => _selectedPaymentMethods = s),
            ),
            SizedBox(height: responsive.verticalSpacing),

            CustomMultiSelectDropdown(
              label: 'Transaction Status',
              hintText: 'Select Transaction Statuses',
              items: _transactionOptions,
              selectedItems: _selectedTransactionStatuses,
              showSelectAll: true,
              isRequired: true,
              onChanged: (s) =>
                  setState(() => _selectedTransactionStatuses = s),
            ),
            SizedBox(height: responsive.verticalSpacing),

            // CustomMultiSelectDropdown(
            //   label: 'Transaction Type',
            //   hintText: 'Select Transaction Types',
            //   items: _transactionTypeOptions,
            //   selectedItems: _selectedTransactionTypes,
            //   showSelectAll: true,
            //   onChanged: (s) => setState(() => _selectedTransactionTypes = s),
            // ),
            SizedBox(height: responsive.verticalSpacing),
            // Student Dropdown
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
          ],
        ),
      ),
    );
  }
}
