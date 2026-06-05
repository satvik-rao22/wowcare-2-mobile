import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AnnualStateImmunizationReportScreen extends StatefulWidget {
  const AnnualStateImmunizationReportScreen({super.key});

  static const String routeName = '/reports/compliance/annual-state-immunization';

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
    final now = DateTime.now();
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
    if (mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Report generated successfully',
        isError: false,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return ReportFormLayout(
      title: 'Annual State Immunization Report',
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
          ReportFormatSelector(
            selectedFormat: _format,
            onFormatChanged: (value) => setState(() => _format = value),
          ),
        ],
      ),
    );
  }
}
