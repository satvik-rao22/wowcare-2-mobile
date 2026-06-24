import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
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

class _GeneratedReportsScreenState extends State<GeneratedReportsScreen>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<String?> _selectedTag = ValueNotifier<String?>(null);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    AppLogger.d('[REPORTS-UI] GeneratedReportsScreen: initState - starting initial load');
    _loadData();
  }

  void _loadData({bool isRefresh = false}) {
    final cubit = context.read<ReportsCubit>();
    AppLogger.d('[REPORTS-UI] GeneratedReportsScreen: Loading data [isRefresh=$isRefresh]');
    // Load in sequence: first reports, then tags (chained with .then() to ensure order)
    unawaited(cubit.loadRecentReports(isRefresh: isRefresh).then((_) {
      AppLogger.d('[REPORTS-UI] GeneratedReportsScreen: Reports loaded, now loading tags');
      cubit.loadDynamicTags();
    }));
  }

  Future<void> _handleDownload(BuildContext context, String? assetCode) async {
    if (assetCode == null || assetCode.isEmpty) {
      AppLogger.e('[REPORTS-UI-DOWN] Invalid assetCode: $assetCode');
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to download: Invalid report identifier',
        isError: true,
      );
      return;
    }

    AppLogger.d('[REPORTS-UI-DOWN] Started for assetCode: $assetCode');

    final cubit = context.read<ReportsCubit>();
    final allReports = cubit.state.recentReports;

    // Find report metadata
    late final ReportMetadataEntity report;
    try {
      report = allReports.firstWhere((r) => r.assetCode == assetCode);
      AppLogger.d('[REPORTS-UI-DOWN] Found report by assetCode');
    } catch (_) {
      if (allReports.isNotEmpty) {
        report = allReports.first;
        AppLogger.d('[REPORTS-UI-DOWN] Using first report as fallback');
      } else {
        report = ReportMetadataEntity(
          reportId: assetCode,
          reportType: ReportType.studentDailyAttendance,
          generatedAt: DateTime.now(),
          assetCode: assetCode,
          fileName: 'report.pdf',
        );
        AppLogger.d('[REPORTS-UI-DOWN] Created default report');
      }
    }

    final fileName = report.fileName ?? 'report.pdf';

    // Show downloading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
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
    }

    try {
      AppLogger.d('[REPORTS-UI-DOWN] Downloading: $fileName');

      final fileData = await cubit.downloadReport(assetCode);

      if (!mounted) return;
      Navigator.pop(context); // Close download dialog

      if (fileData == null || fileData.isEmpty) {
        AppLogger.e('[REPORTS-UI-DOWN] Bytes empty - assetCode: $assetCode');
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to download report',
          isError: true,
        );
        return;
      }

      AppLogger.d('[REPORTS-UI-DOWN] Downloaded: bytesLength=${fileData.length}');

      // Show saving dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Saving file...'),
              ],
            ),
          ),
        );
      }

      // Save file
      AppLogger.d('[REPORTS-UI-DOWN] Saving: $fileName');

      final filePath = await cubit.saveReportFile(
        fileData: Uint8List.fromList(fileData),
        fileName: fileName,
        assetCode: assetCode,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close save dialog

      if (filePath == null) {
        AppLogger.e('[REPORTS-UI-DOWN] Save failed - assetCode: $assetCode');
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to save file',
          isError: true,
        );
        return;
      }

      AppLogger.i('[REPORTS-UI-DOWN] Saved: $filePath');

      // Show success message
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: '$fileName saved successfully',
          isSuccess: true,
        );
      }

      // Try to open file
      AppLogger.d('[REPORTS-UI-DOWN] Opening: $filePath');

      final opened = await cubit.openReportFile(
        filePath: filePath,
        fileName: fileName,
        assetCode: assetCode,
      );

      if (!opened && mounted) {
        AppLogger.w('[REPORTS-UI-DOWN] Auto-open failed, file still saved');
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Saved. Open from file manager to view',
          isSuccess: true,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[REPORTS-UI-DOWN] Exception:\n'
        '  assetCode: $assetCode\n'
        '  fileName: $fileName\n'
        '  error: $e\n'
        '  stackTrace: $stackTrace',
      );

      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}

        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
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
    super.build(context);
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
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalSpacing,
                    ),
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
            color: isSelected ? AppColors.primaryColor : Colors.white,
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
    return BlocListener<ReportsCubit, ReportsState>(
      listenWhen: (previous, current) =>
          previous.generatedReportsState != current.generatedReportsState ||
          previous.generationSuccess != current.generationSuccess,
      listener: (context, state) {
        // Auto-refresh reports when a new report is generated
        if (state.generationSuccess != null &&
            state.generationSuccess!.isNotEmpty &&
            state.generatedReport != null) {
          AppLogger.d('[RECENT_REPORTS_BACKGROUND_REFRESH] New report generated, refreshing list silently');
          _loadData(isRefresh: true);

          // Clear the success signal so future generations trigger this listener again
          unawaited(
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.read<ReportsCubit>().clearGeneratedReport();
              }
            }),
          );
        }

        // Show error snackbar when loading fails
        if (state.generatedReportsState == GeneratedReportsLoadingState.error &&
            state.generatedReportsError != null) {
          AppLogger.e('[REPORTS-UI] Failed to load reports - ${state.generatedReportsError}');
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.generatedReportsError ?? 'Failed to load reports',
            isError: true,
          );
        }
      },
      child: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          AppLogger.d('[REPORTS-UI] Build: state=${state.generatedReportsState}, count=${state.recentReports.length}');

          // Show spinner while loading initial data
          if (state.generatedReportsState == GeneratedReportsLoadingState.initial ||
              state.generatedReportsState == GeneratedReportsLoadingState.loading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading reports from:\n'
                      '• Student Attendance\n'
                      '• Staff Attendance\n'
                      '• Staff Reports\n'
                      '• Student Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: Color(0xff573353),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show error state with retry button
          if (state.generatedReportsState == GeneratedReportsLoadingState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                      state.generatedReportsError ?? 'Unknown error',
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
                      onPressed: () => _loadData(isRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show empty state when no reports
          final filtered = _filterReports(
            state.recentReports,
            _selectedTag.value,
          );

          if (filtered.isEmpty) {
            AppLogger.d('[REPORTS-UI] Showing empty state: ${state.recentReports.length} total, ${filtered.length} filtered');
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

          AppLogger.d('[REPORTS-UI] Showing ${filtered.length} reports in list');

          // Show reports list with pull-to-refresh
          return RefreshIndicator(
            onRefresh: () async {
              AppLogger.d('[REPORTS-UI] Pull-to-refresh triggered');
              await context.read<ReportsCubit>().loadRecentReports(isRefresh: true);
              AppLogger.d('[REPORTS-UI] Refresh completed');
            },
            backgroundColor: AppColors.primaryColor,
            color: Colors.white,
            strokeWidth: 2.0,
            displacement: 40,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                GeneratedReportsList(
                  items: filtered
                      .map(
                        (report) => GeneratedReportItem(
                          fileName: report.fileName ?? 'Report',
                          generatedAt: report.generatedAt,
                          type: (report.fileName ?? '').endsWith('.pdf')
                              ? GeneratedReportFileType.pdf
                              : GeneratedReportFileType.xlsx,
                          assetCode: report.assetCode,
                        ),
                      )
                      .toList(),
                  onView: null,
                  onDownload: (assetCode) => _handleDownload(context, assetCode),
                ),
                // Add padding at bottom to allow pull-to-refresh on short lists
                if (filtered.isEmpty)
                  const SizedBox(height: 200)
                else
                  const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
