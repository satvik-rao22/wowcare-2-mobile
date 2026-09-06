import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_card.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/cubit/student_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_tab.dart';
import 'package:wowcare/presentation/features/reports/widgets/reports_tab.dart';
import 'package:wowcare/presentation/features/reports/model/report_catalog.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_download_actions.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/constants/app_sizes.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static const String routeName = '/dashboard/reports';

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ReportDownloadActions<ReportsScreen> {
  late final TabController _tabController;

  late final ReportFormLauncher _launcher = ReportFormLauncher(
    onReportGenerated: () => _tabController.animateTo(0),
    onViewReport: downloadAndViewReport,
    onDownloadReport: downloadAndSaveReport,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(
      length: ReportCatalog.tabs.length,
      vsync: this,
    );
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
      if (tabIndex >= 0 && tabIndex < ReportCatalog.tabs.length) {
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // After returning from an externally-launched file viewer (PDF/XLSX),
    // Android/iOS can resume Flutter without repainting its surface,
    // leaving a black screen. Force a rebuild on resume to guarantee a
    // fresh frame is drawn.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  /// What the student, staff and compliance forms produce when they close.
  ///
  /// Same three outcomes the old `Object?` protocol had: an entity carrying an
  /// inline `base64:` file is downloaded and shown; any other generated report
  /// bounces to the Generated tab; a dismissed form (`null`) does nothing.
  @override
  Widget build(BuildContext context) {
    // Same values ResponsiveSizing produced (its own breakpoint was already
    // 600, so this is a no-op at every width) — now resolved through the one
    // breakpoint source (M7).
    final double titleFontSize = context.responsive(
      compact: context.isNarrow ? 18.0 : 20.0,
      medium: 26.0,
    );
    final double titleLineHeight =
        context.responsive(compact: 28.0, medium: 34.0) / titleFontSize;
    final double outerPadding =
        (context.responsive(compact: 16.0, medium: 24.0) - 8).clamp(0, 32);
    final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
      outerPadding,
      outerPadding,
      8,
      0,
    );

    // The four cubits this screen needs are created in the `reports` GoRoute
    // builder (§5), not here.
    return MultiBlocListener(
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
                      ReportsStrings.reports,
                      style: AppTextStyles.reportsScreenTitle(
                        fontSize: titleFontSize,
                        height: titleLineHeight,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.transparentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.xs,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: ReportsStrings.scrollTabs,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 26,
                              height: 32,
                            ),
                            splashRadius: 14,
                            icon: const Icon(
                              Icons.chevron_left,
                              color: AppColors.primaryColor,
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
                              unselectedLabelColor: AppColors.primaryColor,
                              dividerColor: AppColors.transparentColor,
                              indicatorSize: TabBarIndicatorSize.label,
                              indicator: UnderlineTabIndicator(
                                borderSide: BorderSide(
                                  color: AppColors.themeColor,
                                  width: 2,
                                ),
                              ),
                              tabs: List<Widget>.generate(
                                ReportCatalog.tabs.length,
                                (int index) => Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    index == 0 ? 4 : 12,
                                    6,
                                    12,
                                    6,
                                  ),
                                  child: Text(
                                    ReportCatalog.tabs[index],
                                    style: AppTextStyles.reportsTabLabel,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: ReportsStrings.scrollTabs,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 26,
                              height: 32,
                            ),
                            splashRadius: 14,
                            icon: const Icon(
                              Icons.chevron_right,
                              color: AppColors.primaryColor,
                              size: 25,
                            ),
                            onPressed: () {
                              final int current = _tabController.index;
                              if (current < ReportCatalog.tabs.length - 1) {
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
            const SizedBox(height: AppSizes.sm),
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
                    GeneratedReportsTab(
                      onViewReport: downloadAndViewReport,
                      onDownloadReport: downloadAndSaveReport,
                    ),
                    // Tab 1: Student Reports
                    ReportsTab(
                      tabIndex: 1,
                      reports: ReportCatalog.studentReports,
                      formats: const [ReportExportFormat.excel],
                      onGenerate: _launcher.openStudentReportForm,
                    ),
                    // Tab 2: Staff Reports
                    ReportsTab(
                      tabIndex: 2,
                      reports: ReportCatalog.staffReports,
                      formats: const [ReportExportFormat.excel],
                      onGenerate: _launcher.openStaffReportForm,
                    ),
                    // Tab 3: Compliance Reports
                    ReportsTab(
                      tabIndex: 3,
                      reports: ReportCatalog.complianceReports,
                      formats: const [
                        // ReportExportFormat.pdf,
                        ReportExportFormat.excel,
                      ],
                      onGenerate: _launcher.openComplianceReportForm,
                    ),
                    // Tab 4: Billing Reports
                    ReportsTab(
                      tabIndex: 4,
                      reports: ReportCatalog.billingReports,
                      formats: const [ReportExportFormat.excel],
                      onGenerate: _launcher.openBillingReportForm,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        showCustomNavigationBar: true,
      ),
    );
  }
}
