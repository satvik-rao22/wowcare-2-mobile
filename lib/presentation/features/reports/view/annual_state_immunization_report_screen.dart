import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/annual_state_immunization_report_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/resolve_school_name.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

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
  late final ValueNotifier<DateTime> _startDate;
  late final ValueNotifier<DateTime> _endDate;
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = ValueNotifier<DateTime>(DateTime(now.year, 1, 1));
    _endDate = ValueNotifier<DateTime>(DateTime(now.year, 12, 31));
  }

  void _onGenerate() async {
    if (_endDate.value.isBefore(_startDate.value)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.endDateCannotBeBeforeStartDate,
        isError: true,
      );
      return;
    }

    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;

    final params = AnnualStateImmunizationReportParams(
      reportType: ReportType.annualStateImmunization,
      startDate: _startDate.value,
      endDate: _endDate.value,
      format: _format.value,
      schoolName: schoolName,
    );
    context.read<ReportsCubit>().generateReport(params);
  }

  @override
  void dispose() {
    _endDate.dispose();
    _format.dispose();
    _startDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                message: ReportsStrings.reportGeneratedSuccessfully,
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // Hand the hub a typed result. The report is generated
                  // but the file is not attached, so the hub animates to the
                  // Generated tab -- the outcome pop(true) used to encode.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  context.pop(const ReportGeneratedRefreshList());
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
            title: ReportsStrings.annualStateImmunizationName,
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: ReportsStrings.startDate),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _startDate,
                  builder: (_, v, __) => CustomDateTimeField(
                    hasLabel: false,
                    fetchInitialTime: false,
                    initialDate: v,
                    onDateSelected: (d) => _startDate.value = d,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportFieldLabel(label: ReportsStrings.endDate),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _endDate,
                  builder: (_, v, __) => CustomDateTimeField(
                    hasLabel: false,
                    fetchInitialTime: false,
                    initialDate: v,
                    onDateSelected: (d) => _endDate.value = d,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportFieldLabel(label: ReportsStrings.exportFormat),
                ValueListenableBuilder<String>(
                  valueListenable: _format,
                  builder: (_, v, __) => ReportFormatSelector(
                    selectedFormat: v,
                    onFormatChanged: (value) => _format.value = value,
                    showLabel: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
