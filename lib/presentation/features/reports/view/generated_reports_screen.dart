import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_list.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class GeneratedReportsScreen extends StatefulWidget {
  const GeneratedReportsScreen({super.key});

  static const String routeName = '/reports/generated';

  @override
  State<GeneratedReportsScreen> createState() => _GeneratedReportsScreenState();
}

class _GeneratedReportsScreenState extends State<GeneratedReportsScreen> {
  final ValueNotifier<String?> _selectedTag = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final cubit = context.read<ReportsCubit>();
    cubit.loadRecentReports();
    cubit.loadDynamicTags();
  }

  @override
  void dispose() {
    _selectedTag.dispose();
    super.dispose();
  }

  List<ReportMetadataEntity> _filterReports(
    List<ReportMetadataEntity> reports,
    String? selectedTag,
  ) {
    if (selectedTag == null || selectedTag.isEmpty) {
      return reports;
    }
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                'assets/bgImages/wowcare_mobile_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(responsive.horizontalSpacing),
                    child: Text(
                      'Generated Reports',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                    child: _buildTagFilter(),
                  ),
                  Padding(
                    padding: EdgeInsets.all(responsive.horizontalSpacing),
                    child: _buildReportsContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilter() {
    return BlocSelector<ReportsCubit, ReportsState, List<String>>(
      selector: (state) => state.dynamicTagNames,
      builder: (context, tags) {
        if (tags.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Filter by Tag',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff573353),
                ),
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _selectedTag,
              builder: (context, selected, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTagChip(
                      label: 'All',
                      isSelected: selected == null,
                      onTap: () => _selectedTag.value = null,
                    ),
                    for (final tag in tags)
                      _buildTagChip(
                        label: tag,
                        isSelected: selected == tag,
                        onTap: () => _selectedTag.value = tag,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTagChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.white,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : const Color(0xFFE9ECEF),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xff573353),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsContent() {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if (state.isLoadingRecent) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.recentError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load reports',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff573353).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.recentError ?? 'Unknown error',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff573353).withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final filtered = _filterReports(
          state.recentReports.cast<ReportMetadataEntity>(),
          _selectedTag.value,
        );

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: const Color(0xff573353).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reports generated yet',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff573353).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate your first report to see it here',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff573353).withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return GeneratedReportsList(
          items: filtered
              .map(
                (report) => GeneratedReportItem(
                  fileName: report.fileName ?? 'Report',
                  generatedAt: report.generatedAt,
                  type: (report.fileName ?? '').endsWith('.pdf')
                      ? GeneratedReportFileType.pdf
                      : GeneratedReportFileType.xlsx,
                ),
              )
              .toList(),
          onView: null,
          onDownload: null,
        );
      },
    );
  }
}
