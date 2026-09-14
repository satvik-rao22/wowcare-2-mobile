import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class BillingPlanReportScreen extends StatefulWidget {
  const BillingPlanReportScreen({super.key, required this.classrooms});

  static const String routeName = '/reports/billing/billing-plan';

  final List<String> classrooms;

  @override
  State<BillingPlanReportScreen> createState() =>
      _BillingPlanReportScreenState();
}

class _BillingPlanReportScreenState extends State<BillingPlanReportScreen> {
  static const List<String> _frequencyOptions = <String>[
    'Daily',
    'Weekly',
    'Monthly',
  ];

  final ValueNotifier<String> _frequency = ValueNotifier<String>('Monthly');
  late final ValueNotifier<DateTime> _periodMonth;
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _periodMonth = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
  }

  void _onGenerate() {
    if (mounted) {
      context.pop(const ReportGeneratedRefreshList());
    }
  }

  TextStyle _labelStyle(BuildContext context) =>
      AppTextStyles.reportsFieldLabel(
        fontSize: context.responsive(compact: 14.0, medium: 16.0),
      );

  @override
  void dispose() {
    _format.dispose();
    _frequency.dispose();
    _periodMonth.dispose();
    _selectedClassrooms.dispose();
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
      child: ReportFormLayout(
        title: ReportsStrings.billingPlan,
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: ReportsStrings.frequency,
                    hintText: ReportsStrings.select,
                    items: _frequencyOptions,
                    selectedItem: _frequency.value,
                    labelStyle: _labelStyle(context),
                    showAsterisk: true,
                    labelBottomSpacing: context.isTablet ? 8.0 : 6.0,
                    onSelect: (val) {
                      if (val == null) return;
                      _frequency.value = val;
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ReportFieldLabel(label: ReportsStrings.period),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _periodMonth,
                        builder: (_, v, __) => ReportMonthYearField(
                          initialMonth: v,
                          onMonthSelected: (d) => _periodMonth.value = d,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            ValueListenableBuilder<List<String>>(
              valueListenable: _selectedClassrooms,
              builder: (_, v, __) => MultiSelectFilterField<String>(
                label: ReportsStrings.classroom,
                hintText: ReportsStrings.allClassrooms,
                items: widget.classrooms,
                selectedItems: v,
                onChanged: (c) => _selectedClassrooms.value = c,
                showSelectAll: true,
                itemToString: (item) => item,
                singularLabel: ReportsStrings.classroom,
                pluralLabel: ReportsStrings.classrooms,
                enableSearch: true,
                searchHintText: ReportsStrings.searchClassrooms,
                defaultNote:
                    ReportsStrings.noteAllClassroomsIncludedByDefault,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
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
      ),
    );
  }
}
