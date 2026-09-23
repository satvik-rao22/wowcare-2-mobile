import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_list.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/core/constants/app_sizes.dart';

/// The "Generated" tab of the reports hub: the recent-reports list plus its
/// loading, empty and error states.
///
/// Extracted from `reports_screen.dart` (§6.7). The two download actions used
/// to be reached with `context.findAncestorStateOfType<_ReportsScreenState>()`
/// — they are now explicit callbacks, so this widget has no hidden dependency
/// on its host.
class GeneratedReportsTab extends StatefulWidget {
  const GeneratedReportsTab({
    super.key,
    required this.onViewReport,
    required this.onDownloadReport,
  });

  /// Download the asset and show it in the in-app viewer.
  final void Function(BuildContext context, String assetCode, String fileName)
  onViewReport;

  /// Download the asset, save it, and hand it to the OS.
  final Future<void> Function(
    BuildContext context,
    String assetCode,
    String fileName,
  )
  onDownloadReport;

  @override
  State<GeneratedReportsTab> createState() => _GeneratedReportsTabState();
}

class _GeneratedReportsTabState extends State<GeneratedReportsTab>
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
            message:
                state.generatedReportsError ??
                ReportsStrings.failedToLoadReports,
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
                  padding: EdgeInsets.all(AppSizes.md),
                  child: GeneratedReportsListShimmer(),
                );
              }

              // Error state - show error with retry button
              if (data.state == GeneratedReportsLoadingState.error) {
                return _GeneratedReportsErrorState(error: data.error);
              }

              // Empty state - show no reports message
              if (data.reports.isEmpty) {
                return const _GeneratedReportsEmptyState();
              }

              // Loaded with data or refreshing - show data with optional progress
              return Stack(
                children: [
                  _GeneratedReportsListView(
                    reports: data.reports,
                    onViewReport: widget.onViewReport,
                    onDownloadReport: widget.onDownloadReport,
                  ),
                  if (data.state == GeneratedReportsLoadingState.refreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: AppColors.transparentColor,
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

  // ignore: unused_element
}

/// Error panel for the Generated tab. Was `Widget _buildErrorState(String?)`
/// on the State (§6.4).
class _GeneratedReportsErrorState extends StatelessWidget {
  const _GeneratedReportsErrorState({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<ReportsCubit>().loadRecentReports(isRefresh: true);
      },
      // §7.4: this LayoutBuilder responds to the box the TabBarView gives us,
      // not to the screen — which is exactly what the state needs. It replaces
      // `MediaQuery.of(context).size.height - 200`, where the 200 was a guess
      // at the app-bar/tab-bar/nav chrome and `.of` re-ran the whole subtree on
      // every keyboard open (§7.5). It must sit OUTSIDE the scroll view: a
      // SingleChildScrollView hands its child unbounded height, so a
      // LayoutBuilder inside it would measure infinity.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: AppErrorState(
              title: ReportsStrings.failedToLoadReports,
              message: error ?? ReportsStrings.unknownError,
              retryLabel: ReportsStrings.retry,
              onRetry: () {
                context.read<ReportsCubit>().loadRecentReports();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty panel for the Generated tab. Was `Widget _buildEmptyState()` (§6.4).
class _GeneratedReportsEmptyState extends StatelessWidget {
  const _GeneratedReportsEmptyState();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<ReportsCubit>().loadRecentReports(isRefresh: true);
      },
      // §7.4: this LayoutBuilder responds to the box the TabBarView gives us,
      // not to the screen — which is exactly what the state needs. It replaces
      // `MediaQuery.of(context).size.height - 200`, where the 200 was a guess
      // at the app-bar/tab-bar/nav chrome and `.of` re-ran the whole subtree on
      // every keyboard open (§7.5). It must sit OUTSIDE the scroll view: a
      // SingleChildScrollView hands its child unbounded height, so a
      // LayoutBuilder inside it would measure infinity.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: AppColors.reportsMutedColor,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      ReportsStrings.noReportsGeneratedYet,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      ReportsStrings.generateYourFirstReport,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The recent-reports list. Was `Widget _buildReportsList(List<...>)` (§6.4).
class _GeneratedReportsListView extends StatelessWidget {
  const _GeneratedReportsListView({
    required this.reports,
    required this.onViewReport,
    required this.onDownloadReport,
  });

  final List<ReportMetadataEntity> reports;
  final void Function(BuildContext, String, String) onViewReport;
  final Future<void> Function(BuildContext, String, String) onDownloadReport;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<ReportsCubit>().loadRecentReports(isRefresh: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          GeneratedReportsList(
            items: reports.map((report) {
              final fileName =
                  report.fileName ?? ReportsStrings.unknownFileName;
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
                onViewReport(context, item.assetCode!, item.fileName);
              }
            },
            onDownload: (assetCode) async {
              if (assetCode != null) {
                await onDownloadReport(
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
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}
