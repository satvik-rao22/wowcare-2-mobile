import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Generic date-range + format form for the billing reports that don't need extra filters
/// (Invoice, Payment Summary, Outstanding, Refund, Students & Billing Mapping).
class BillingReportFormScreen extends StatefulWidget {
  const BillingReportFormScreen({
    super.key,
    required this.reportType,
    required this.title,
  });

  final ReportType reportType;
  final String title;

  @override
  State<BillingReportFormScreen> createState() =>
      _BillingReportFormScreenState();
}

class _BillingReportFormScreenState extends State<BillingReportFormScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _onGenerate() {
    if (_endDate.isBefore(_startDate)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'End date cannot be before Start date',
        isError: true,
      );
      return;
    }
    context.read<ReportsCubit>().generateReport(
          ReportRequestParams(
            reportType: widget.reportType,
            startDate: _startDate,
            endDate: _endDate,
            format: _format,
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
                state.generationSuccess!.isNotEmpty) {
              // generatedReport == null means the byte fallback already opened the file.
              final openedDirectly = state.generatedReport == null;
              CoreUtils.showTopSnackBar(
                context: context,
                message: openedDirectly
                    ? 'Report downloaded'
                    : 'Report generated successfully',
                isSuccess: true,
              );
              if (!openedDirectly && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  context.go('/dashboard/reports?tab=0');
                  context.read<ReportsCubit>().clearGeneratedReport();
                });
              }
            }
          },
        ),
      ],
      child: ReportFormLayout(
        title: widget.title,
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportFieldLabel(label: 'Start Date'),
            CustomDateTimeField(
              hasLabel: false,
              fetchInitialTime: false,
              initialDate: _startDate,
              onDateSelected: (d) => setState(() => _startDate = d),
            ),
            SizedBox(height: responsive.verticalSpacing),
            const ReportFieldLabel(label: 'End Date'),
            CustomDateTimeField(
              hasLabel: false,
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
          ],
        ),
      ),
    );
  }
}
