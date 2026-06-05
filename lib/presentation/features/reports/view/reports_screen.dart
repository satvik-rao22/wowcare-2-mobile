import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/annual_state_immunization_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/billing_plan_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/billing_transaction_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_absent_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_attendance_per_week_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_directory_report_screen.dart';
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
import 'package:wowcare/shared/utils/responsive_sizing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static const String routeName = '/dashboard/reports';

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
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
        screen = StudentIncidentReportScreen(students: reports.studentNames);
        break;
    }

    if (screen == null) {
      _showComingSoon(context, 'Generate');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ReportsCubit>.value(
          value: cubit,
          child: screen!,
        ),
      ),
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

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ReportsCubit>.value(
          value: cubit,
          child: screen!,
        ),
      ),
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

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ReportsCubit>.value(
          value: cubit,
          child: screen!,
        ),
      ),
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
      case 'Billing Plan':
        screen = BillingPlanReportScreen(classrooms: reports.classroomNames);
        break;
    }

    if (screen == null) {
      _showComingSoon(context, 'Generate');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ReportsCubit>.value(
          value: cubit,
          child: screen!,
        ),
      ),
    );
  }

  static const List<String> _tabs = <String>[
    'Generated',
    'Student',
    'Staff',
    'Compliance',
    'Billing',
  ];

  static final List<GeneratedReportItem> _generatedReports =
      <GeneratedReportItem>[
    GeneratedReportItem(
      fileName: 'Annual State Immunization Report 01-22-2026.xlsx',
      generatedAt: DateTime(2026, 1, 22, 11, 14),
      type: GeneratedReportFileType.xlsx,
    ),
    GeneratedReportItem(
      fileName: 'Student Daily Attendance 01-22-2026.xlsx',
      generatedAt: DateTime(2026, 1, 22, 11, 3),
      type: GeneratedReportFileType.xlsx,
    ),
    GeneratedReportItem(
      fileName: 'Annual State Immunization Report 01-13-2026.pdf',
      generatedAt: DateTime(2026, 1, 13, 9, 21),
      type: GeneratedReportFileType.pdf,
    ),
    GeneratedReportItem(
      fileName: 'Billing plan 01-12-2026.xlsx',
      generatedAt: DateTime(2026, 1, 12, 12, 23),
      type: GeneratedReportFileType.xlsx,
    ),
    GeneratedReportItem(
      fileName: 'Annual State Immunization Report 01-08-2026.xlsx',
      generatedAt: DateTime(2026, 1, 8, 10, 5),
      type: GeneratedReportFileType.xlsx,
    ),
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
      description: 'All transactions in the selected date range.',
    ),
    ReportItem(
      name: 'Billing Plan',
      description: 'Billing plan grouped by selected frequency.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);
    final EdgeInsets contentPadding = ResponsiveSizing.contentPadding(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ClassroomCubit>(
          create: (_) => serviceLocator<ClassroomCubit>()
            ..loadActiveClassrooms(onlyTypeClassroom: true),
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
              context.read<ReportsCubit>().setClassroomNames(
                    state.classrooms.map((c) => c.name).toList(growable: false),
                  );
            },
          ),
          BlocListener<StudentCubit, StudentState>(
            listenWhen: (prev, curr) => prev.items != curr.items,
            listener: (context, state) {
              context.read<ReportsCubit>().setStudentNames(
                    state.items
                        .map((s) => s.fullName)
                        .where((n) => n.isNotEmpty)
                        .toList(growable: false),
                  );
            },
          ),
          BlocListener<StaffCubit, StaffState>(
            listenWhen: (prev, curr) => prev.items != curr.items,
            listener: (context, state) {
              context.read<ReportsCubit>().setStaffNames(
                    state.items
                        .map((s) => s.name)
                        .where((n) => n.isNotEmpty)
                        .toList(growable: false),
                  );
            },
          ),
        ],
        child: GlobalScaffold(
      body: DefaultTabController(
        length: _tabs.length,
        child: Builder(
          builder: (context) {
            final TabController controller = DefaultTabController.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                              color: Colors.transparent,
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
                                    final int current = controller.index;
                                    if (current > 0) {
                                      controller.animateTo(current - 1);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: TabBar(
                                    isScrollable: true,
                                    padding: EdgeInsets.zero,
                                    labelPadding: EdgeInsets.zero,
                                    tabAlignment: TabAlignment.start,
                                    labelColor: AppColors.themeColor,
                                    unselectedLabelColor:
                                        const Color(0xff573353),
                                    dividerColor: Colors.transparent,
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
                                    final int current = controller.index;
                                    if (current < _tabs.length - 1) {
                                      controller.animateTo(current + 1);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: controller,
                            builder: (context, _) {
                              final int current = controller.index;
                              if (current == 0) {
                                return GeneratedReportsList(
                                  items: _generatedReports,
                                  onView: (item) =>
                                      _showComingSoon(context, 'View'),
                                  onDownload: (item) =>
                                      _showComingSoon(context, 'Download'),
                                );
                              }
                              final formats = current == 3
                                  ? const <ReportExportFormat>[
                                      ReportExportFormat.pdf,
                                      ReportExportFormat.excel,
                                    ]
                                  : const <ReportExportFormat>[
                                      ReportExportFormat.excel,
                                    ];
                              return _ReportsList(
                                reports: _reportsFor(current),
                                formats: formats,
                                onGenerate: (item, _) {
                                  if (current == 1) {
                                    _openStudentReportForm(context, item.name);
                                  } else if (current == 2) {
                                    _openStaffReportForm(context, item.name);
                                  } else if (current == 3) {
                                    _openComplianceReportForm(
                                        context, item.name);
                                  } else if (current == 4) {
                                    _openBillingReportForm(context, item.name);
                                  } else {
                                    _showComingSoon(context, 'Generate');
                                  }
                                },
                              );
                            },
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      showCustomNavigationBar: true,
        ),
      ),
    );
  }

  List<ReportItem> _reportsFor(int tabIndex) {
    // Tab 0 is "Generated" (rendered separately); tabs 1-4 map to template lists.
    switch (tabIndex) {
      case 1:
        return _studentReports;
      case 2:
        return _staffReports;
      case 3:
        return _complianceReports;
      case 4:
        return _billingReports;
      default:
        return const <ReportItem>[];
    }
  }

  void _showComingSoon(BuildContext context, String action) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: '$action — coming soon',
      isWarning: true,
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
