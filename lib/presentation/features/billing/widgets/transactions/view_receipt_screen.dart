import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/date_utils.dart';

class ViewReceiptScreen extends StatefulWidget {
  const ViewReceiptScreen({
    super.key,
    required this.transaction,
    this.viewType = 'receipt', // 'receipt' or 'invoice'
  });

  final TransactionItem transaction;
  final String viewType;

  @override
  State<ViewReceiptScreen> createState() => _ViewReceiptScreenState();
}

class _ViewReceiptScreenState extends State<ViewReceiptScreen> {
  // Dummy data for UI
  Map<String, dynamic>? _addressEntity;
  Map<String, dynamic>? _invoiceDetails;
  List<Map<String, dynamic>>? _invoiceItems;

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
  }

  void _initializeDummyData() {
    // Load dummy data
    setState(() {
      _addressEntity = {
        'line': '123 Main Street',
        'city': 'New York',
        'state': 'NY',
        'country': 'USA',
        'zipcode': '10001',
      };

      _invoiceDetails = {
        'invoiceNumber': 'INV-2025-${widget.transaction.id}',
        'date': widget.transaction.date.toIso8601String(),
        'startDate': widget.transaction.date.subtract(const Duration(days: 30)).toIso8601String(),
        'endDate': widget.transaction.date.toIso8601String(),
        'dueDate': widget.transaction.endDate != null
            ? DateTime.parse(widget.transaction.endDate!).toIso8601String()
            : widget.transaction.date.add(const Duration(days: 7)).toIso8601String(),
      };

      // Generate dummy invoice items
      _invoiceItems = [
        {
          'type': 'item',
          'description': widget.transaction.description,
          'amount': widget.transaction.amount.toString(),
          'deductionAmt': '0',
        },
        if (widget.transaction.amount > 200) ...[
          {
            'type': 'discount',
            'description': 'Early Payment Discount',
            'amount': '0',
            'deductionAmt': (widget.transaction.amount * 0.1).toStringAsFixed(2),
          },
        ],
      ];
    });
  }

  String _getDueDate() {
    if (_invoiceDetails != null && _invoiceDetails!['dueDate'] != null) {
      try {
        final dueDateParsed = DateTime.parse(_invoiceDetails!['dueDate'].toString());
        return DateUtilsNew.formatToReadableDate(dueDateParsed);
      } catch (e) {
        // Fall through
      }
    }
    return 'Not available';
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
                    'Description',
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
                    'Mode',
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
                    'Amount',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Divider(
              thickness: 0.5,
              color: AppColors.billingGreyTransparent,
            ),
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
                    widget.transaction.paymentMode ?? 'N/A',
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
                    'Description',
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
                    'Mode',
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
                    'Amount',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Divider(
              thickness: 0.5,
              color: AppColors.billingGreyTransparent,
            ),
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
                    widget.transaction.paymentMode ?? 'N/A',
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
            ..._invoiceItems!.map((item) {
              final type = item['type']?.toString() ?? '';
              final description = item['description']?.toString() ?? '';
              final amount = item['amount']?.toString() ?? '0';
              final deductionAmt = item['deductionAmt']?.toString() ?? '0';
              const currencySign = '\$';

              String displayAmount = '';
              bool isNegative = false;

              if (type == 'discount' || type == 'subsidy') {
                displayAmount = deductionAmt != '0' ? deductionAmt : amount;
                isNegative = true;
              } else {
                displayAmount = amount;
                isNegative = false;
              }

              String displayText = '';
              if (isNegative) {
                displayText = '-$currencySign$displayAmount';
              } else {
                displayText = '$currencySign$displayAmount';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Text(
                      displayText,
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
            }).toList(),
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
                'Description',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Amount',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        Divider(
          thickness: 0.5,
          color: Colors.grey.withOpacity(0.3),
        ),
        // Invoice items
        ..._invoiceItems!.map((item) {
          final type = item['type']?.toString() ?? '';
          final description = item['description']?.toString() ?? '';
          final amount = item['amount']?.toString() ?? '0';
          final deductionAmt = item['deductionAmt']?.toString() ?? '0';
          const currencySign = '\$';

          String displayAmount = '';
          bool isNegative = false;

          if (type == 'discount' || type == 'subsidy') {
            displayAmount = deductionAmt != '0' ? deductionAmt : amount;
            isNegative = true;
          } else {
            displayAmount = amount;
            isNegative = false;
          }

          String displayText = '';
          if (isNegative) {
            displayText = '-$currencySign$displayAmount';
          } else {
            displayText = '$currencySign$displayAmount';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Text(
                  displayText,
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
        }).toList(),
      ],
    );
  }

  Widget _buildCurrentSchoolDetail() {
    // Dummy school data
    const schoolName = 'WowCare School';
    const schoolDescription = 'Excellence in Education';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentImageWidget(
          fileUuid: '',
          size: 60,
          name: schoolName,
          fontSize: 18,
        ),
        const SizedBox(height: 8),
        Text(
          schoolName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          schoolDescription,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
        if (_addressEntity != null)
          Text(
            '${_addressEntity!['line']}, ${_addressEntity!['city']}, ${_addressEntity!['state']}, ${_addressEntity!['country']}, ${_addressEntity!['zipcode']}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentForRow() {
    return Row(
      children: [
        Text(
          widget.viewType == 'invoice' ? 'Billed For : ' : 'Payment For : ',
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        DocumentImageWidget(
          fileUuid: widget.transaction.studentPhotoUuid ?? '',
          name: widget.transaction.studentName,
          size: 32,
          fontSize: 14,
        ),
        const SizedBox(width: 5),
        Text(
          widget.transaction.studentName,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
                    'Invoice Number : ',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _invoiceDetails!['invoiceNumber']?.toString() ?? 'N/A',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.billingGreyDark,
                      fontWeight: FontWeight.bold,
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
                    'Due Date : ',
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
                      fontWeight: FontWeight.bold,
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
                  'Payment Date : ',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateUtilsNew.formatToReadableDate(date),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          _buildInvoiceItemsTable(),
          Divider(
            thickness: 0.5,
            color: Colors.grey.withOpacity(0.3),
          ),
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
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      widget.viewType == 'invoice' ? 'View Invoice' : 'View Receipt',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          top: 8,
                        ),
                        child: _buildCurrentSchoolDetail(),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildPaymentForRow(),
                      ),
                      const SizedBox(height: 15),
                      _buildPaymentDetailContainer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

