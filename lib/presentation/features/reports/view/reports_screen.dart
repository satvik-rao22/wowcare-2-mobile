import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_list.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_card.dart';
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

  static const List<ReportItem> _staffReports = <ReportItem>[];
  static const List<ReportItem> _complianceReports = <ReportItem>[];
  static const List<ReportItem> _billingReports = <ReportItem>[];

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);
    final EdgeInsets contentPadding = ResponsiveSizing.contentPadding(context);

    return GlobalScaffold(
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
                              return _ReportsList(
                                reports: _reportsFor(current),
                                onView: (item) =>
                                    _showComingSoon(context, 'View'),
                                onGenerate: (item) =>
                                    _showComingSoon(context, 'Generate'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList({
    required this.reports,
    required this.onView,
    required this.onGenerate,
  });

  final List<ReportItem> reports;
  final ValueChanged<ReportItem> onView;
  final ValueChanged<ReportItem> onGenerate;

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
            onView: () => onView(reports[i]),
            onGenerate: () => onGenerate(reports[i]),
          ),
          if (i != reports.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
