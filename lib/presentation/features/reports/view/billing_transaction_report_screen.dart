import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class BillingTransactionReportScreen extends StatefulWidget {
  const BillingTransactionReportScreen({super.key});

  static const String routeName = '/reports/billing/transaction';

  @override
  State<BillingTransactionReportScreen> createState() =>
      _BillingTransactionReportScreenState();
}

class _BillingTransactionReportScreenState
    extends State<BillingTransactionReportScreen> {
  static const List<String> _transactionOptions = <String>[
    'All Transactions',
    'Deposit Report',
    'Custom',
  ];

  static const List<String> _transactionTypeOptions = <String>[
    'Cash',
    'Cheque',
    'Online',
    'Others',
  ];

  late DateTime _startDate;
  late DateTime _endDate;
  String _transactionType = 'All Transactions';
  List<String> _selectedTransactionTypes = <String>[];
  String _format = 'PDF';

  bool get _isCustom => _transactionType == 'Custom';

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
    if (_isCustom && _selectedTransactionTypes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one transaction type',
        isError: true,
      );
      return;
    }
    if (mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Report generated successfully',
        isSuccess: true,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return BlocListener<ReportsCubit, ReportsState>(
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
      child: ReportFormLayout(
        title: 'Transaction Report',
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
            CustomDropdown(
              label: 'Transactions',
              hintText: 'Select',
              items: _transactionOptions,
              selectedItem: _transactionType,
              labelStyle: TextStyle(
                fontSize: responsive.labelFontSize,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w400,
                color: const Color(0xff573353),
              ),
              showAsterisk: true,
              labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
              prependHintAsSelectableItem: false,
              onSelect: (val) {
                if (val == null) return;
                setState(() {
                  _transactionType = val;
                  if (!_isCustom) {
                    _selectedTransactionTypes = <String>[];
                  }
                });
              },
            ),
            if (_isCustom) ...[
              SizedBox(height: responsive.verticalSpacing),
              CustomMultiSelectDropdown(
                label: 'Transaction Type',
                hintText: 'Select Transactions Types',
                items: _transactionTypeOptions,
                selectedItems: _selectedTransactionTypes,
                showSelectAll: true,
                onChanged: (s) => setState(() => _selectedTransactionTypes = s),
              ),
            ],
            SizedBox(height: responsive.verticalSpacing),
            ReportFormatSelector(
              selectedFormat: _format,
              onFormatChanged: (value) => setState(() => _format = value),
            ),
          ],
        ),
      ),
    );
  }
}
