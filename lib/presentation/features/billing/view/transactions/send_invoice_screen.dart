import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/send_invoice_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/core/utils/date_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Locally-derived invoice header shown on the Send Invoice form (not parsed
/// from any API response — built from [SendInvoiceScreen.transaction]).
class _SendInvoiceDummyData {
  const _SendInvoiceDummyData({
    required this.invoiceNumber,
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.description,
  });

  final String invoiceNumber;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime dueDate;
  final double invoiceAmount;
  final String description;
}

class SendInvoiceScreen extends StatelessWidget {
  const SendInvoiceScreen({super.key, required this.transaction});

  static const String routeName = '/billing/send-invoice';

  final TransactionItem transaction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SendInvoiceCubit>(
      create: (_) =>
          serviceLocator<SendInvoiceCubit>()
            ..loadRoomName(transaction.studentCode),
      child: _SendInvoiceForm(transaction: transaction),
    );
  }
}

class _SendInvoiceForm extends StatefulWidget {
  const _SendInvoiceForm({required this.transaction});

  final TransactionItem transaction;

  @override
  State<_SendInvoiceForm> createState() => _SendInvoiceFormState();
}

class _SendInvoiceFormState extends State<_SendInvoiceForm> {
  // Dummy data for UI
  _SendInvoiceDummyData? _invoiceDetails;

  // Form controllers
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Form data
  String _invoiceNumber = '';

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
    _initializeFormData();
  }

  void _initializeDummyData() {
    // Load dummy data
    _SendInvoiceDummyData? invoiceData;
    if (widget.transaction.refTable == 'Invoice' &&
        widget.transaction.refTableId != null) {
      invoiceData = _SendInvoiceDummyData(
        invoiceNumber: 'INV-2025-${widget.transaction.refTableId}',
        startDate: widget.transaction.date.subtract(const Duration(days: 30)),
        endDate: widget.transaction.date,
        dueDate: widget.transaction.endDate != null
            ? DateTime.parse(widget.transaction.endDate!)
            : widget.transaction.date.add(const Duration(days: 7)),
        invoiceAmount: widget.transaction.amount,
        description: widget.transaction.description,
      );
    }

    _invoiceDetails = invoiceData;

    // Update form with invoice data if available
    if (invoiceData != null) {
      _updateFormWithInvoiceData(invoiceData);
    }
  }

  void _initializeFormData() {
    // Generate invoice number based on the current SCHOOL date, so the number
    // doesn't jump a day for a device in another zone.
    final now = billingSchoolToday();
    _invoiceNumber =
        'INV${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _invoiceNumberController.text = _invoiceNumber;

    // Pre-fill with transaction data
    _descriptionController.text = widget.transaction.displayDescription;
    _amountController.text = widget.transaction.amount.toStringAsFixed(2);

    // Set form data
  }

  void _updateFormWithInvoiceData(_SendInvoiceDummyData invoiceData) {
    // Update invoice number
    _invoiceNumberController.text = invoiceData.invoiceNumber;
    _invoiceNumber = _invoiceNumberController.text;

    // Update due date
    _dueDateController.text = DateUtilsNew.formatToReadableDate(
      invoiceData.dueDate,
    );

    // Update amount
    _amountController.text = invoiceData.invoiceAmount.toStringAsFixed(2);

    // Update description if available
    if (invoiceData.description.isNotEmpty) {
      _descriptionController.text = invoiceData.description;
    }
  }

  String _getInvoicePeriodText() {
    // Only show data from dummy invoice details, no hardcoded fallbacks
    if (_invoiceDetails == null) {
      // Check if this is because the transaction doesn't reference an invoice
      if (widget.transaction.refTable != 'Invoice') {
        return 'Not applicable - Transaction references ${widget.transaction.refTable}';
      }
      return BillingStrings.na;
    }

    final startText = DateUtilsNew.formatToReadableDate(
      _invoiceDetails!.startDate,
    );
    final endText = DateUtilsNew.formatToReadableDate(_invoiceDetails!.endDate);
    return '$startText - $endText';
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dueDateController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// A draft is issued (POST /issue); an already-issued invoice is re-sent
  /// (PATCH /resend).
  bool get _isDraft =>
      widget.transaction.status.toUpperCase().contains('DRAFT');

  Future<void> _sendInvoice() async {
    final cubit = context.read<SendInvoiceCubit>();
    final outcome = await cubit.send(
      invoiceCode: widget.transaction.invoiceCode,
      isDraft: _isDraft,
    );
    if (!mounted) return;
    switch (outcome) {
      case SendInvoiceOutcome.missingCode:
        CoreUtils.showTopSnackBar(
          context: context,
          message: BillingStrings.invoiceCannotBeSent,
          isWarning: true,
        );
      case SendInvoiceOutcome.success:
        CoreUtils.showTopSnackBar(
          context: context,
          message: _isDraft
              ? BillingStrings.invoiceSentSuccessfully
              : BillingStrings.invoiceResentSuccessfully,
          isSuccess: true,
        );
        Navigator.pop(context, true);
      case SendInvoiceOutcome.failure:
        CoreUtils.showTopSnackBar(
          context: context,
          message: cubit.state.errorMessage ?? '',
          isError: true,
        );
    }
  }

  Widget _buildBilledForRow(String? roomName) {
    final classroom = (roomName ?? widget.transaction.classroom).trim();
    return Row(
      children: [
        Text(
          BillingStrings.billedForColon,
          style: AppTextStyles.title.copyWith(
            fontSize: 16,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          widget.transaction.studentName,
          style: AppTextStyles.value.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        if (classroom.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            classroom,
            style: AppTextStyles.small.copyWith(color: AppColors.primaryColor),
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              BillingStrings.invoiceNumberColon,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.billingGreyMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _invoiceNumberController.text,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.billingGreyDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                BillingStrings.invoicePeriodColon,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.billingGreyMedium,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 4),
              Text(
                _getInvoicePeriodText(),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.billingGreyDark,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              BillingStrings.dueDateColon,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.billingGreyMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _dueDateController.text.isEmpty
                  ? BillingStrings.notSet
                  : _dueDateController.text,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.billingGreyDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.billingGreyLight,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Table Headers
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  BillingStrings.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.billingGreyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  BillingStrings.amount,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.billingGreyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          // Table Row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  _descriptionController.text.isEmpty
                      ? '-'
                      : _descriptionController.text,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '\$${_amountController.text}',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          // Total Row with highlighted background
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    BillingStrings.totalAmount,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${_amountController.text}',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SendInvoiceCubit, SendInvoiceState>(
      builder: (context, state) {
        return StaffFormLayout(
          title: BillingStrings.sendInvoice,
          bottomBar: _buildBottomBar(state.isSending),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BillingSchoolHeader(),
                const SizedBox(height: 20),
                _buildBilledForRow(state.roomName),
                const SizedBox(height: 16),
                _buildInvoiceDetailsSection(),
                const SizedBox(height: 16),
                _buildInvoiceTable(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(bool isSending) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SkeuKeyBox(
          variant: KeyVariant.primary,
          radius: 12,
          child: TextButton(
            onPressed: isSending ? null : _sendInvoice,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.billingCardOnColorText,
                    ),
                  )
                : Text(
                    _isDraft
                        ? BillingStrings.sendInvoice
                        : BillingStrings.resendInvoice,
                    style: TextStyle(
                      color: AppColors.billingButtonTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
