import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_card.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/cubit/student_cubit.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/core/constants/app_sizes.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({
    required this.tabIndex,
    required this.reports,
    required this.formats,
    required this.onGenerate,
  });

  final int tabIndex;
  final List<ReportItem> reports;
  final List<ReportExportFormat> formats;
  final void Function(BuildContext context, ReportItem item) onGenerate;

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
              padding: const EdgeInsets.only(top: AppSizes.xxs),
              child: GeneratedReportsListShimmer(
                rowCount: reports.isEmpty ? 4 : reports.length,
              ),
            )
          : _ReportsCardList(
              reports: reports,
              formats: formats,
              onGenerate: (item, _) {
                onGenerate(context, item);
              },
            ),
    );
  }
}

class _ReportsCardList extends StatelessWidget {
  const _ReportsCardList({
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
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
        child: Center(
          child: Text(
            ReportsStrings.noReportsAvailableYet,
            style: AppTextStyles.reportsEmptyListText,
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
          if (i != reports.length - 1) const SizedBox(height: AppSizes.xsPlus),
        ],
      ],
    );
  }
}
