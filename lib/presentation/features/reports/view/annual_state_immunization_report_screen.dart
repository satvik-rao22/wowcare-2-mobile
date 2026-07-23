import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/annual_state_immunization_report_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AnnualStateImmunizationReportScreen extends StatefulWidget {
  const AnnualStateImmunizationReportScreen({super.key});

  static const String routeName =
      '/reports/compliance/annual-state-immunization';

  @override
  State<AnnualStateImmunizationReportScreen> createState() =>
      _AnnualStateImmunizationReportScreenState();
}

class _AnnualStateImmunizationReportScreenState
    extends State<AnnualStateImmunizationReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = DateTime(now.year, 1, 1);
    _endDate = DateTime(now.year, 12, 31);
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

    final params = AnnualStateImmunizationReportParams(
      reportType: ReportType.annualStateImmunization,
      startDate: _startDate,
      endDate: _endDate,
      format: _format,
    );
    context.read<ReportsCubit>().generateReport(params);
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
                state.generationSuccess!.isNotEmpty &&
                state.generatedReport != null) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: 'Report generated successfully',
                isSuccess: true,
              );

              if (mounted) {
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
      child: BlocSelector<ReportsCubit, ReportsState, bool>(
        selector: (state) => state.isGenerating,
        builder: (context, isGenerating) {
          return ReportFormLayout(
            title: 'Annual State Immunization Report',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
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
          );
        },
      ),
    );
  }
}
