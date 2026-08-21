import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/annual_state_immunization_report_screen.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/presentation/features/reports/view/billing_report_form_screen.dart';
import 'package:wowcare/presentation/features/reports/view/billing_transaction_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/report_file_viewer_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_absent_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_attendance_per_week_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_details_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_schedule_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_absent_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_attendance_per_student_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_daily_attendance_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_emergency_contact_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_immunization_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_incident_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/students_and_family_report_screen.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_list.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_card.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static const String routeName = '/dashboard/reports';

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // After returning from an externally-launched file viewer (PDF/XLSX),
    // Android/iOS can resume Flutter without repainting its surface,
    // leaving a black screen. Force a rebuild on resume to guarantee a
    // fresh frame is drawn.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  /// Dismiss a dialog shown via [showDialog] (which defaults to the root
  /// navigator). Popping through the ambient [context] instead would hit
  /// go_router's branch navigator and pop the screen itself off the page
  /// stack, which crashes with `currentConfiguration.isNotEmpty` once no
  /// pages remain — always target the same (root) navigator the dialog was
  /// pushed on, and never pop when there's nothing left to pop.
  void _dismissDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _openStudentReportForm(BuildContext context, String name) {
    final reports = context.read<ReportsCubit>().state;
    final cubit = context.read<ReportsCubit>();
    Widget? screen;
    switch (name) {
      case 'Student Daily Attendance':
        screen = StudentDailyAttendanceReportScreen(
          classrooms: reports.classroomNames,
        );
        break;
      case 'Absent Report':
        screen = StudentAbsentReportScreen(classrooms: reports.classroomNames);
        break;
      case 'Attendance per Student':
        screen = StudentAttendancePerStudentReportScreen(
          students: reports.studentNames,
          classrooms: reports.classroomNames,
        );
        break;
      case 'Students and Family':
        screen = StudentsAndFamilyReportScreen(
          classrooms: reports.classroomNames,
          tags: reports.tagNames,
        );
        break;
      case 'School Immunization Report':
        screen = StudentImmunizationReportScreen(
          classrooms: reports.classroomNames,
          tags: reports.tagNames,
        );
        break;
      case 'Student Emergency Contact List':
        screen = StudentEmergencyContactReportScreen(
          classrooms: reports.classroomNames,
        );
        break;
      case 'School Incident Report':
        screen = StudentIncidentReportScreen(
          students: reports.studentNames,
          classrooms: reports.classroomNames,
        );
        break;
    }

    if (screen == null) {
      _showComingSoon(context, 'Generate');
      return;
    }

    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<bool>(
              builder: (_) => BlocProvider<ReportsCubit>.value(
                value: cubit,
                child: screen!,
              ),
            ),
          )
          .then((success) {
            if (success == true && mounted) {
              _tabController.animateTo(0);
            }
          }),
    );
  }

  void _openStaffReportForm(BuildContext context, String name) {
    final reports = context.read<ReportsCubit>().state;
    final cubit = context.read<ReportsCubit>();
    Widget? screen;
    switch (name) {
      case 'Attendance Per Staff':
        screen = StaffAttendancePerWeekReportScreen(
          staff: reports.staffNames,
          classrooms: reports.classroomNames,
        );
        break;
      case 'Staff Details':
        screen = StaffDirectoryReportScreen(classrooms: reports.classroomNames);
        break;
      case 'Absent Report':
        screen = StaffAbsentReportScreen(classrooms: reports.classroomNames);
        break;
      case 'Staff Scheduling':
        screen = StaffScheduleReportScreen(classrooms: reports.classroomNames);
        break;
    }

    if (screen == null) {
      _showComingSoon(context, 'Generate');
      return;
    }

    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<bool>(
              builder: (_) => BlocProvider<ReportsCubit>.value(
                value: cubit,
                child: screen!,
              ),
            ),
          )
          .then((success) {
            if (success == true && mounted) {
              _tabController.animateTo(0);
            }
          }),
    );
  }

  void _openComplianceReportForm(BuildContext context, String name) {
    final cubit = context.read<ReportsCubit>();
    Widget? screen;
    switch (name) {
      case 'Annual State Immunization Report':
        // Both PDF and Excel buttons open the same form; format selection
        // happens on the backend when Generate is pressed.
        screen = const AnnualStateImmunizationReportScreen();
        break;
    }

    if (screen == null) {
      _showComingSoon(context, 'Generate');
      return;
    }

    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<bool>(
              builder: (_) => BlocProvider<ReportsCubit>.value(
                value: cubit,
                child: screen!,
              ),
            ),
          )
          .then((success) {
            if (success == true && mounted) {
              _tabController.animateTo(0);
            }
          }),
    );
  }

  void _openBillingReportForm(BuildContext context, String name) {
    final reports = context.read<ReportsCubit>().state;
    final cubit = context.read<ReportsCubit>();
    Widget? screen;
    switch (name) {
      case 'Transaction Report':
        screen = const BillingTransactionReportScreen();
        break;
      case 'Invoice Report':
        screen = BillingReportFormScreen(
          reportType: ReportType.billingInvoice,
          title: 'Invoice Report',
          classrooms: reports.classroomNames,
          students: reports.studentNames,
        );
        break;
      case 'Payment Summary':
        screen = BillingReportFormScreen(
          reportType: ReportType.billingPaymentSummary,
          title: 'Payment Summary',
          classrooms: reports.classroomNames,
          students: reports.studentNames,
        );
        break;
      case 'Outstanding Report':
        screen = BillingReportFormScreen(
          reportType: ReportType.billingOutstanding,
          title: 'Outstanding Report',
          classrooms: reports.classroomNames,
          students: reports.studentNames,
        );
        break;
      case 'Refund Report':
        screen = BillingReportFormScreen(
          reportType: ReportType.billingRefund,
          title: 'Refund Report',
          classrooms: reports.classroomNames,
          students: reports.studentNames,
        );
        break;
      case 'Students & Billing Mapping':
        screen = BillingReportFormScreen(
          reportType: ReportType.billingStudentMapping,
          title: 'Students & Billing Mapping',
          classrooms: reports.classroomNames,
          students: reports.studentNames,
        );
        break;
    }

    if (screen == null) {
      _showComingSoon(context, 'Generate');
      return;
    }

    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<bool>(
              builder: (_) => BlocProvider<ReportsCubit>.value(
                value: cubit,
                child: screen!,
              ),
            ),
          )
          .then((success) {
            if (success == true && mounted) {
              _tabController.animateTo(0);
            }
          }),
    );
  }

  static const List<String> _tabs = <String>[
    'Generated',
    'Student',
    'Staff',
    'Compliance',
    'Billing',
  ];

  static const List<ReportItem> _studentReports = <ReportItem>[
    ReportItem(
      name: 'Student Daily Attendance',
      description: 'Sign in-out records time signed by.',
    ),
    ReportItem(
      name: 'Absent Report',
      description: 'List of students with no sign-in for day.',
    ),
    ReportItem(
      name: 'Attendance per Student',
      description: 'Sign in-out records for weekly, entire month.',
    ),
    ReportItem(
      name: 'Students and Family',
      description: 'Download all students and family information.',
    ),
    ReportItem(
      name: 'School Immunization Report',
      description: 'Download all immunization information.',
    ),
    ReportItem(
      name: 'Student Emergency Contact List',
      description: 'Download all students emergency information.',
    ),
    ReportItem(
      name: 'School Incident Report',
      description:
          'All incident information, including approvals & acknowledgements.',
    ),
  ];

  static const List<ReportItem> _staffReports = <ReportItem>[
    ReportItem(
      name: 'Attendance Per Staff',
      description:
          'Sign In-Out records for entire month and date range Selection.',
    ),
    ReportItem(
      name: 'Staff Details',
      description: 'Download all staff information.',
    ),
    ReportItem(
      name: 'Absent Report',
      description: 'List of Staff with no sign-in for day.',
    ),
    ReportItem(
      name: 'Staff Scheduling',
      description: 'List of all Staff schedule.',
    ),
  ];

  static const List<ReportItem> _complianceReports = <ReportItem>[
    ReportItem(
      name: 'Annual State Immunization Report',
      description: 'Download student state immunization information.',
    ),
  ];

  static const List<ReportItem> _billingReports = <ReportItem>[
    ReportItem(
      name: 'Transaction Report',
      description: 'Payments, invoices, refunds and credits for a date range.',
    ),
    ReportItem(
      name: 'Invoice Report',
      description: 'Issued invoices with total, paid and balance due.',
    ),
    ReportItem(
      name: 'Payment Summary',
      description: 'Total payments and transaction count over the period.',
    ),
    ReportItem(
      name: 'Outstanding Report',
      description: 'Open invoice balances by student / family.',
    ),
    ReportItem(
      name: 'Refund Report',
      description: 'Refunds issued over the period.',
    ),
    ReportItem(
      name: 'Students & Billing Mapping',
      description:
          'Each student mapped to their invoices (total, paid, balance).',
    ),
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Load recent reports when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsCubit>().loadRecentReports();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tabParam != null) {
      final tabIndex = int.tryParse(tabParam) ?? 0;
      if (tabIndex >= 0 && tabIndex < _tabs.length) {
        if (_tabController.index != tabIndex) {
          _tabController.animateTo(tabIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);
    final EdgeInsets contentPadding = ResponsiveSizing.contentPadding(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ClassroomCubit>(
          create: (_) =>
              serviceLocator<ClassroomCubit>()
                ..loadActiveClassrooms(force: true, onlyTypeClassroom: true),
        ),
        BlocProvider<StudentCubit>(
          create: (_) => serviceLocator<StudentCubit>()..loadInitial(),
        ),
        BlocProvider<StaffCubit>(
          create: (_) => serviceLocator<StaffCubit>()..loadInitial(),
        ),
        BlocProvider<ReportsCubit>(
          create: (_) => serviceLocator<ReportsCubit>()..loadTags(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ClassroomCubit, ClassroomState>(
            listenWhen: (prev, curr) => prev.classrooms != curr.classrooms,
            listener: (context, state) {
              final nameToCodeMap = <String, String>{};
              for (final classroom in state.classrooms) {
                nameToCodeMap[classroom.name] = classroom.code;
              }
              context.read<ReportsCubit>().setClassroomNames(
                state.classrooms.map((c) => c.name).toList(growable: false),
                nameToCodeMap: nameToCodeMap,
              );
            },
          ),
          BlocListener<StudentCubit, StudentState>(
            listenWhen: (prev, curr) => prev.items != curr.items,
            listener: (context, state) {
              final nameToCodeMap = <String, String>{};
              final studentNames = <String>[];
              for (final student in state.items) {
                if (student.fullName.isNotEmpty) {
                  studentNames.add(student.fullName);
                  nameToCodeMap[student.fullName] = student.code;
                }
              }
              context.read<ReportsCubit>().setStudentNames(
                studentNames,
                nameToCodeMap: nameToCodeMap,
              );
            },
          ),
          BlocListener<StaffCubit, StaffState>(
            listenWhen: (prev, curr) => prev.items != curr.items,
            listener: (context, state) {
              final nameToCodeMap = <String, String>{};
              final staffNames = <String>[];
              for (final staff in state.items) {
                if (staff.name.isNotEmpty) {
                  staffNames.add(staff.name);
                  nameToCodeMap[staff.name] = staff.code;
                }
              }
              context.read<ReportsCubit>().setStaffNames(
                staffNames,
                nameToCodeMap: nameToCodeMap,
              );
            },
          ),
          BlocListener<ReportsCubit, ReportsState>(
            listenWhen: (prev, curr) =>
                prev.generationSuccess != curr.generationSuccess,
            listener: (context, state) {
              if (state.generationSuccess != null) {
                context.read<ReportsCubit>().loadRecentReports();
              }
            },
          ),
        ],
        child: GlobalScaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header and TabBar
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff573353),
                          height: titleLineHeight,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Scroll tabs',
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(
                                width: 26,
                                height: 32,
                              ),
                              splashRadius: 14,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Color(0xff573353),
                                size: 25,
                              ),
                              onPressed: () {
                                final int current = _tabController.index;
                                if (current > 0) {
                                  _tabController.animateTo(current - 1);
                                }
                              },
                            ),
                            Expanded(
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                padding: EdgeInsets.zero,
                                labelPadding: EdgeInsets.zero,
                                tabAlignment: TabAlignment.start,
                                labelColor: AppColors.themeColor,
                                unselectedLabelColor: const Color(0xff573353),
                                dividerColor: AppColors.transparent,
                                indicatorSize: TabBarIndicatorSize.label,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    color: AppColors.themeColor,
                                    width: 2,
                                  ),
                                ),
                                tabs: List<Widget>.generate(
                                  _tabs.length,
                                  (int index) => Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      index == 0 ? 4 : 12,
                                      6,
                                      12,
                                      6,
                                    ),
                                    child: Text(
                                      _tabs[index],
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Scroll tabs',
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(
                                width: 26,
                                height: 32,
                              ),
                              splashRadius: 14,
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Color(0xff573353),
                                size: 25,
                              ),
                              onPressed: () {
                                final int current = _tabController.index;
                                if (current < _tabs.length - 1) {
                                  _tabController.animateTo(current + 1);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tab Content - Swipeable
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: contentPadding.left,
                    vertical: contentPadding.top,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Tab 0: Generated Reports
                      _GeneratedReportsTab(context: context),
                      // Tab 1: Student Reports
                      _ReportsTab(
                        tabIndex: 1,
                        reports: _studentReports,
                        formats: const [ReportExportFormat.excel],
                        onGenerate: _openStudentReportForm,
                      ),
                      // Tab 2: Staff Reports
                      _ReportsTab(
                        tabIndex: 2,
                        reports: _staffReports,
                        formats: const [ReportExportFormat.excel],
                        onGenerate: _openStaffReportForm,
                      ),
                      // Tab 3: Compliance Reports
                      _ReportsTab(
                        tabIndex: 3,
                        reports: _complianceReports,
                        formats: const [
                          // ReportExportFormat.pdf,
                          ReportExportFormat.excel,
                        ],
                        onGenerate: _openComplianceReportForm,
                      ),
                      // Tab 4: Billing Reports
                      _ReportsTab(
                        tabIndex: 4,
                        reports: _billingReports,
                        formats: const [ReportExportFormat.excel],
                        onGenerate: _openBillingReportForm,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          showCustomNavigationBar: true,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String action) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: '$action — coming soon',
      isWarning: true,
    );
  }

  Future<void> _downloadAndViewReport(
    BuildContext context,
    String assetCode,
    String fileName,
  ) async {
    // Viewing renders the file bytes in memory (PDFView/Excel preview);
    // no storage permission is needed since nothing is written to shared
    // storage here.
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Downloading report...',
      isSuccess: true,
    );

    final fileData = await context.read<ReportsCubit>().downloadReport(
      assetCode,
    );

    if (!mounted) return;

    if (fileData == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to download report',
        isError: true,
      );
      return;
    }

    // Determine file type
    final fileType = fileName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'xlsx';

    if (!mounted) return;

    // Navigate to the viewer screen and navigate to it
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportFileViewerScreen(
          fileData: Uint8List.fromList(fileData),
          fileName: fileName,
          fileType: fileType,
        ),
      ),
    );
  }

  /// Downloads the report bytes, saves them to device storage, and opens
  /// the saved file with the OS's default handler — unlike
  /// [_downloadAndViewReport], which only renders bytes in-memory and never
  /// persists anything, this is what makes "Download" actually download.
  Future<void> _downloadAndSaveReport(
    BuildContext context,
    String assetCode,
    String fileName,
  ) async {
    final cubit = context.read<ReportsCubit>();

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Downloading $fileName...'),
          ],
        ),
      ),
    );

    try {
      final fileData = await cubit.downloadReport(assetCode);

      if (!mounted) return;
      _dismissDialog(context); // close downloading dialog

      if (fileData == null || fileData.isEmpty) {
        AppLogger.e('[REPORTS-UI-DOWN] Bytes empty for assetCode=$assetCode');
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to download report',
          isError: true,
        );
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving file...'),
              ],
            ),
          ),
        );
      }

      final filePath = await cubit.saveReportFile(
        fileData: Uint8List.fromList(fileData),
        fileName: fileName,
        assetCode: assetCode,
      );

      if (!mounted) return;
      _dismissDialog(context); // close saving dialog

      if (filePath == null) {
        AppLogger.e('[REPORTS-UI-DOWN] Save failed for assetCode=$assetCode');
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to save file',
          isError: true,
        );
        return;
      }

      AppLogger.i('[REPORTS-UI-DOWN] Saved: $filePath');
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: '$fileName saved successfully',
          isSuccess: true,
        );
      }

      final opened = await cubit.openReportFile(
        filePath: filePath,
        fileName: fileName,
        assetCode: assetCode,
      );

      if (!opened && mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Saved. Open from file manager to view',
          isSuccess: true,
        );
      }
    } catch (e) {
      AppLogger.e('[REPORTS-UI-DOWN] Exception for assetCode=$assetCode: $e');
      if (mounted) {
        _dismissDialog(context);
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
  }
}

class _GeneratedReportsTab extends StatefulWidget {
  const _GeneratedReportsTab({required this.context});

  final BuildContext context;

  @override
  State<_GeneratedReportsTab> createState() => _GeneratedReportsTabState();
}

class _GeneratedReportsTabState extends State<_GeneratedReportsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Always load reports when tab is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsCubit>().loadRecentReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<ReportsCubit, ReportsState>(
      listenWhen: (previous, current) =>
          previous.generatedReportsState != current.generatedReportsState,
      listener: (context, state) {
        // Show error snackbar when loading fails (only show errors, not success)
        if (state.generatedReportsState == GeneratedReportsLoadingState.error &&
            state.generatedReportsError != null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.generatedReportsError ?? 'Failed to load reports',
            isError: true,
          );
        }
      },
      child:
          BlocSelector<
            ReportsCubit,
            ReportsState,
            ({
              List<ReportMetadataEntity> reports,
              GeneratedReportsLoadingState state,
              String? error,
            })
          >(
            selector: (state) => (
              reports: state.recentReports,
              state: state.generatedReportsState,
              error: state.generatedReportsError,
            ),
            builder: (context, data) {
              // Initial or loading state - show shimmer placeholders
              if (data.state == GeneratedReportsLoadingState.initial ||
                  data.state == GeneratedReportsLoadingState.loading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: GeneratedReportsListShimmer(),
                );
              }

              // Error state - show error with retry button
              if (data.state == GeneratedReportsLoadingState.error) {
                return _buildErrorState(data.error);
              }

              // Empty state - show no reports message
              if (data.reports.isEmpty) {
                return _buildEmptyState();
              }

              // Loaded with data or refreshing - show data with optional progress
              return Stack(
                children: [
                  _buildReportsList(data.reports),
                  if (data.state == GeneratedReportsLoadingState.refreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: AppColors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildErrorState(String? error) {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<ReportsCubit>().loadRecentReports(isRefresh: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load reports',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReportsCubit>().loadRecentReports();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<ReportsCubit>().loadRecentReports(isRefresh: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppColors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reports generated yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate your first report to see it here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList(List<ReportMetadataEntity> reports) {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<ReportsCubit>().loadRecentReports(isRefresh: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          GeneratedReportsList(
            items: reports.map((report) {
              final fileName = report.fileName ?? 'Unknown';
              final ext = fileName.split('.').last.toLowerCase();
              return GeneratedReportItem(
                fileName: fileName,
                generatedAt: report.generatedAt,
                type: ext == 'xlsx'
                    ? GeneratedReportFileType.xlsx
                    : GeneratedReportFileType.pdf,
                assetCode: report.assetCode,
              );
            }).toList(),
            onView: (item) {
              if (item.assetCode != null) {
                context
                    .findAncestorStateOfType<_ReportsScreenState>()
                    ?._downloadAndViewReport(
                      context,
                      item.assetCode!,
                      item.fileName,
                    );
              }
            },
            onDownload: (assetCode) async {
              if (assetCode != null) {
                await context
                    .findAncestorStateOfType<_ReportsScreenState>()
                    ?._downloadAndSaveReport(
                      context,
                      assetCode,
                      reports
                              .firstWhere(
                                (r) => r.assetCode == assetCode,
                                orElse: () => reports.first,
                              )
                              .fileName ??
                          'report.pdf',
                    );
              }
            },
          ),
          // Add padding to allow pull-to-refresh on short lists
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({
    required this.tabIndex,
    required this.reports,
    required this.formats,
    required this.onGenerate,
  });

  final int tabIndex;
  final List<ReportItem> reports;
  final List<ReportExportFormat> formats;
  final void Function(BuildContext context, String name) onGenerate;

  /// Whether this tab's report cards depend on classroom/student/staff
  /// lookup data that's still loading. Compliance and Billing reports use
  /// only date ranges (no classroom/student/staff selection), so they have
  /// nothing to wait for and always render immediately.
  bool _isLoadingLookupData(BuildContext context) {
    switch (tabIndex) {
      case 1: // Student
        return context.select<ClassroomCubit, bool>((c) => c.state.isLoading) ||
            context.select<StudentCubit, bool>((c) => c.state.isLoading);
      case 2: // Staff
        return context.select<ClassroomCubit, bool>((c) => c.state.isLoading) ||
            context.select<StaffCubit, bool>((c) => c.state.isLoading);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingLookupData(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GeneratedReportsListShimmer(
                rowCount: reports.isEmpty ? 4 : reports.length,
              ),
            )
          : _ReportsList(
              reports: reports,
              formats: formats,
              onGenerate: (item, _) {
                onGenerate(context, item.name);
              },
            ),
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList({
    required this.reports,
    required this.onGenerate,
    required this.formats,
  });

  final List<ReportItem> reports;
  final List<ReportExportFormat> formats;
  final void Function(ReportItem item, ReportExportFormat format) onGenerate;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No reports available yet.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xff573353).withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < reports.length; i++) ...[
          ReportCard(
            report: reports[i],
            formats: formats,
            onGenerate: (format) => onGenerate(reports[i], format),
          ),
          if (i != reports.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
