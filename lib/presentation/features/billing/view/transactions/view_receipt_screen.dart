import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/view_receipt_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/utils/date_utils.dart';

/// Locally-derived invoice header shown alongside a receipt/invoice (not
/// parsed from any API response — built from [ViewReceiptScreen.transaction]).
class _ReceiptInvoiceDetails {
  const _ReceiptInvoiceDetails({
    required this.dueDate,
    required this.invoiceNumber,
  });

  final DateTime? dueDate;
  final String invoiceNumber;
}

/// One row of the invoice/receipt items table.
class _ReceiptLineItem {
  const _ReceiptLineItem({
    required this.type,
    required this.description,
    required this.amount,
    required this.deductionAmt,
  });

  final String type;
  final String description;
  final String amount;
  final String deductionAmt;

  bool get _isDeduction => type == 'discount' || type == 'subsidy';

  /// Currency-prefixed, sign-adjusted amount text for the table row.
  String get displayText {
    final value = _isDeduction && deductionAmt != '0' ? deductionAmt : amount;
    return _isDeduction ? '-\$$value' : '\$$value';
  }
}

class ViewReceiptScreen extends StatefulWidget {
  const ViewReceiptScreen({
    super.key,
    required this.transaction,
    this.viewType = 'receipt', // 'receipt' or 'invoice'
  });

  static const String routeName = '/billing/view-receipt';

  final TransactionItem transaction;
  final String viewType;

  @override
  State<ViewReceiptScreen> createState() => _ViewReceiptScreenState();
}

class _ViewReceiptScreenState extends State<ViewReceiptScreen> {
  // Dummy data for UI
  _ReceiptInvoiceDetails? _invoiceDetails;
  List<_ReceiptLineItem>? _invoiceItems;

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
  }

  void _initializeDummyData() {
    _invoiceDetails = _ReceiptInvoiceDetails(
      invoiceNumber: 'INV-2025-${widget.transaction.id}',
      dueDate: widget.transaction.endDate != null
          ? DateTime.parse(widget.transaction.endDate!)
          : widget.transaction.date.add(const Duration(days: 7)),
    );

    // Receipts already render a single payment row (description + mode + amount),
    // so no additional items are needed — leave _invoiceItems null to avoid duplicates.
    if (widget.viewType == 'receipt') {
      _invoiceItems = null;
      return;
    }

    _invoiceItems = [
      _ReceiptLineItem(
        type: 'item',
        description: widget.transaction.description,
        amount: widget.transaction.amount.toString(),
        deductionAmt: '0',
      ),
      if (widget.transaction.amount > 200)
        _ReceiptLineItem(
          type: 'discount',
          description: 'Early Payment Discount',
          amount: '0',
          deductionAmt: (widget.transaction.amount * 0.1).toStringAsFixed(2),
        ),
    ];
  }

  String _getDueDate() {
    final dueDate = _invoiceDetails?.dueDate;
    if (dueDate == null) return BillingStrings.notAvailable;
    return DateUtilsNew.formatToReadableDate(dueDate);
  }

  Widget _buildInvoiceItemsTable() {
    // For receipt view - always show payment mode
    if (widget.viewType == 'receipt') {
      if (_invoiceItems == null || _invoiceItems!.isEmpty) {
        // Simple receipt view without invoice items - but still show headers
        return Column(
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    BillingStrings.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    BillingStrings.mode,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const Expanded(
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 2,
                      thickness: 1,
                      color: AppColors.billingGrey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    BillingStrings.amount,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
            // Data row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    widget.transaction.displayDescription,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.transaction.paymentMode ?? '-',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const Expanded(
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 2,
                      thickness: 1,
                      color: AppColors.billingGrey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${widget.transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        // Receipt view with invoice items - show payment mode in header
        return Column(
          children: [
            // Header row with payment mode
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    BillingStrings.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    BillingStrings.mode,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const Expanded(
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 2,
                      thickness: 1,
                      color: AppColors.billingGrey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    BillingStrings.amount,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
            // Payment mode row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    widget.transaction.displayDescription,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.transaction.paymentMode ?? '-',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const Expanded(
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 2,
                      thickness: 1,
                      color: AppColors.billingGrey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${widget.transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Invoice items below
            ..._invoiceItems!.map((item) => _buildLineItemRow(item)),
          ],
        );
      }
    }

    // For invoice view with items (no payment mode needed)
    if (_invoiceItems == null || _invoiceItems!.isEmpty) {
      return const SizedBox.shrink(); // Return empty widget if no items
    }

    return Column(
      children: [
        // Header row for invoice view
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                BillingStrings.description,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.billingGreyMedium,
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
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
        // Invoice items
        ..._invoiceItems!.map((item) => _buildLineItemRow(item)),
      ],
    );
  }

  Widget _buildLineItemRow(_ReceiptLineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.description,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.start,
            ),
          ),
          Text(
            item.displayText,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForRow() {
    return Row(
      children: [
        Text(
          widget.viewType == 'invoice'
              ? BillingStrings.billedForCapColon
              : BillingStrings.paymentForColon,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        DocumentImageWidget(
          fileUuid: widget.transaction.studentPhotoUuid ?? '',
          name: widget.transaction.studentName,
          size: 50,
        ),
        const SizedBox(width: 5),
        Text(
          widget.transaction.studentName,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailContainer() {
    final date = widget.transaction.date;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.billingGreyLight,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Invoice details section (when available)
          if (_invoiceDetails != null) ...[
            // Show invoice number only for invoice view
            if (widget.viewType == 'invoice') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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
                    _invoiceDetails?.invoiceNumber ?? BillingStrings.na,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
            ],
            // Show due date only for invoice view
            if (widget.viewType == 'invoice') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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
                    _getDueDate(),
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
          // Show payment date only for receipt view
          if (widget.viewType == 'receipt') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  BillingStrings.paymentDateColon,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.billingGreyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateUtilsNew.formatToReadableDate(date),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.billingGreyDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          _buildInvoiceItemsTable(),
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Amount : \$${widget.transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onDownload(BuildContext context) async {
    final cubit = context.read<ViewReceiptCubit>();
    final error = await cubit.downloadReceipt(widget.transaction);
    if (!context.mounted) return;
    if (error != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: error,
        isError: true,
      );
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.downloaded,
        isSuccess: true,
      );
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    return CustomButtonLayout(
      isForm: false,
      confirmButtonLabel: BillingStrings.download,
      onPressedConfirm: () => _onDownload(context),
      showCancelButton: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ViewReceiptCubit>(
      create: (_) => serviceLocator<ViewReceiptCubit>(),
      child: Builder(
        builder: (context) {
          return StaffFormLayout(
            title: widget.viewType == 'invoice'
                ? BillingStrings.viewInvoice
                : BillingStrings.viewReceipt,
            bottomBar: _buildBottomBar(context),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BillingSchoolHeader(),
                  const SizedBox(height: 16),
                  _buildPaymentForRow(),
                  const SizedBox(height: 16),
                  _buildPaymentDetailContainer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
