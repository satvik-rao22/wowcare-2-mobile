import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

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

  String _frequency = 'Monthly';
  late DateTime _periodMonth;
  List<String> _selectedClassrooms = <String>[];
  String _format = 'XLSX';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _periodMonth = DateTime(now.year, now.month, 1);
  }

  void _onGenerate() {
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  TextStyle _labelStyle(ResponsiveHelper r) => TextStyle(
    fontSize: r.labelFontSize,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w400,
    color: const Color(0xff573353),
  );

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

                  // Pop (not context.go) — this screen was pushed via plain
                  // Navigator.push, so only popping actually dismisses it;
                  // the hub's own .then((success) => tab 0) callback reacts
                  // to the pop(true) result.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  Navigator.of(context).pop(true);
                });
              }
            }
          },
        ),
      ],
      child: ReportFormLayout(
        title: 'Billing Plan',
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: 'Frequency',
                    hintText: 'Select',
                    items: _frequencyOptions,
                    selectedItem: _frequency,
                    labelStyle: _labelStyle(responsive),
                    showAsterisk: true,
                    labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                    onSelect: (val) {
                      if (val == null) return;
                      setState(() => _frequency = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ReportFieldLabel(label: 'Period'),
                      ReportMonthYearField(
                        initialMonth: _periodMonth,
                        onMonthSelected: (d) =>
                            setState(() => _periodMonth = d),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.verticalSpacing),
            MultiSelectFilterField<String>(
              label: 'Classroom',
              hintText: 'Select Classrooms',
              items: widget.classrooms,
              selectedItems: _selectedClassrooms,
              onChanged: (c) => setState(() => _selectedClassrooms = c),
              showSelectAll: true,
              itemToString: (item) => item,
              singularLabel: 'Classroom',
              pluralLabel: 'Classrooms',
              // showSelectAll: true,
              enableSearch: true,
              searchHintText: 'Search Classrooms',
              defaultNote: 'Note: All Classrooms will be selected by Default.',
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
