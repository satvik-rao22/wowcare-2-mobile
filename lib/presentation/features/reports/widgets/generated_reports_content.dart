import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_list.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// One selectable tag pill in the Generated-reports filter row.
/// Was `Widget _buildTagChip({...})` on the State (§6.4).
class GeneratedReportsTagChip extends StatelessWidget {
  const GeneratedReportsTagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : AppColors.cardColor,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.reportsCardDividerColor,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTextStyles.reportsFieldValue(fontSize: 13).copyWith(
              color: isSelected ? AppColors.cardColor : AppColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Filter by Tag" row. Was `Widget _buildTagFilter()` (§6.4).
class GeneratedReportsTagFilter extends StatelessWidget {
  const GeneratedReportsTagFilter({required this.selectedTag});

  final ValueNotifier<String?> selectedTag;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ReportsCubit, ReportsState, List<String>>(
      selector: (state) => state.dynamicTagNames,
      builder: (context, tags) {
        if (tags.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                ReportsStrings.filterByTag,
                style: AppTextStyles.reportsFieldValue(fontSize: 14),
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: selectedTag,
              builder: (context, selected, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GeneratedReportsTagChip(
                      label: ReportsStrings.all,
                      isSelected: selected == null,
                      onTap: () => selectedTag.value = null,
                    ),
                    for (final tag in tags)
                      GeneratedReportsTagChip(
                        label: tag,
                        isSelected: selected == tag,
                        onTap: () => selectedTag.value = tag,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
        );
      },
    );
  }
}

/// The Generated-reports list plus its auto-refresh listener.
/// Was `Widget _buildReportsContent()` on the State (§6.4).
class GeneratedReportsContent extends StatelessWidget {
  const GeneratedReportsContent({
    required this.onRefresh,
    required this.selectedTag,
    required this.filterReports,
    required this.onDownload,
  });

  final void Function({bool isRefresh}) onRefresh;
  final ValueNotifier<String?> selectedTag;
  final List<ReportMetadataEntity> Function(
    List<ReportMetadataEntity> reports,
    String? selectedTag,
  )
  filterReports;
  final Future<void> Function(BuildContext context, String? assetCode)
  onDownload;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsCubit, ReportsState>(
      listenWhen: (previous, current) =>
          previous.generatedReportsState != current.generatedReportsState ||
          previous.generationSuccess != current.generationSuccess,
      listener: (context, state) {
        // Auto-refresh reports when a new report is generated
        if (state.generationSuccess != null &&
            state.generationSuccess!.isNotEmpty &&
            state.generatedReport != null) {
          AppLogger.d(
            '[RECENT_REPORTS_BACKGROUND_REFRESH] New report generated, refreshing list silently',
          );
          onRefresh(isRefresh: true);

          // Clear the success signal so future generations trigger this listener again
          unawaited(
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                context.read<ReportsCubit>().clearGeneratedReport();
              }
            }),
          );
        }

        // Show error snackbar when loading fails
        if (state.generatedReportsState == GeneratedReportsLoadingState.error &&
            state.generatedReportsError != null) {
          AppLogger.e(
            '[REPORTS-UI] Failed to load reports - ${state.generatedReportsError}',
          );
          CoreUtils.showTopSnackBar(
            context: context,
            message:
                state.generatedReportsError ??
                ReportsStrings.failedToLoadReports,
            isError: true,
          );
        }
      },
      child: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          AppLogger.d(
            '[REPORTS-UI] Build: state=${state.generatedReportsState}, count=${state.recentReports.length}',
          );

          // Show shimmer placeholders while loading initial data
          if (state.generatedReportsState ==
                  GeneratedReportsLoadingState.initial ||
              state.generatedReportsState ==
                  GeneratedReportsLoadingState.loading) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: GeneratedReportsListShimmer(),
            );
          }

          // Show error state with retry button
          if (state.generatedReportsState ==
              GeneratedReportsLoadingState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.reportsRequiredFieldMarkerColor,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      ReportsStrings.failedToLoadReports,
                      style: AppTextStyles.reportsHeading(fontSize: 16)
                          .copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.8,
                            ),
                          ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      state.generatedReportsError ??
                          ReportsStrings.unknownError,
                      style: AppTextStyles.reportsFieldLabel(fontSize: 13)
                          .copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.6,
                            ),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.md),
                    ElevatedButton(
                      onPressed: () => onRefresh(isRefresh: true),
                      child: const Text(ReportsStrings.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show empty state when no reports
          final filtered = filterReports(
            state.recentReports,
            selectedTag.value,
          );

          if (filtered.isEmpty) {
            AppLogger.d(
              '[REPORTS-UI] Showing empty state: ${state.recentReports.length} total, ${filtered.length} filtered',
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      ReportsStrings.noReportsGeneratedYet,
                      style: AppTextStyles.reportsHeading(fontSize: 16)
                          .copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.6,
                            ),
                          ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      ReportsStrings.generateYourFirstReport,
                      style: AppTextStyles.reportsFieldLabel(fontSize: 13)
                          .copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.4,
                            ),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          AppLogger.d(
            '[REPORTS-UI] Showing ${filtered.length} reports in list',
          );

          // Show reports list with pull-to-refresh
          return RefreshIndicator(
            onRefresh: () async {
              AppLogger.d('[REPORTS-UI] Pull-to-refresh triggered');
              await context.read<ReportsCubit>().loadRecentReports(
                isRefresh: true,
              );
              AppLogger.d('[REPORTS-UI] Refresh completed');
            },
            backgroundColor: AppColors.primaryColor,
            color: AppColors.cardColor,
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
                  onDownload: (assetCode) => onDownload(context, assetCode),
                ),
                // Add padding at bottom to allow pull-to-refresh on short lists
                if (filtered.isEmpty)
                  const SizedBox(height: 200)
                else
                  const SizedBox(height: AppSizes.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}
