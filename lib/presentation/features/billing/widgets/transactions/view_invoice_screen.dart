import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/date_utils.dart';

class ViewInvoiceScreen extends StatefulWidget {
  const ViewInvoiceScreen({
    super.key,
    required this.transaction,
  });

  final TransactionItem transaction;

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  // Dummy data for UI
  Map<String, dynamic>? _addressEntity;
  bool _isAddressLoading = false;
  bool _isInvoiceLoading = false;
  bool _isInvoiceItemsLoading = false;
  Map<String, dynamic>? _invoiceDetails;
  List<Map<String, dynamic>>? _invoiceItems;

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
  }

  Future<void> _initializeDummyData() async {
    // Simulate loading
    setState(() {
      _isAddressLoading = true;
      _isInvoiceLoading = true;
      _isInvoiceItemsLoading = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Load dummy data
    setState(() {
      _addressEntity = {
        'line': '123 Main Street',
        'city': 'New York',
        'state': 'NY',
        'country': 'USA',
        'zipcode': '10001',
      };

      // Generate dummy invoice details
      _invoiceDetails = {
        'invoiceNumber': widget.transaction.refTableId != null
            ? 'INV-2025-${widget.transaction.refTableId}'
            : 'INV-2025-${widget.transaction.id}',
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
          'amount': widget.transaction.amount,
          'deductionAmt': 0,
        },
        if (widget.transaction.amount > 200) ...[
          {
            'type': 'discount',
            'description': 'Early Payment Discount',
            'amount': 0,
            'deductionAmt': widget.transaction.amount * 0.1,
          },
        ],
      ];

      _isAddressLoading = false;
      _isInvoiceLoading = false;
      _isInvoiceItemsLoading = false;
    });
  }

  // Helper method to get formatted amount with proper sign
  String _getFormattedAmount(Map<String, dynamic> item) {
    final type = item['type']?.toString().toLowerCase() ?? '';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final deductionAmt = (item['deductionAmt'] as num?)?.toDouble();

    if (type.contains('discount') || type.contains('subsidy')) {
      // For discounts/subsidies, show as negative
      final displayAmount = deductionAmt ?? amount;
      return '-\$${displayAmount.toStringAsFixed(2)}';
    } else {
      // For regular items, show as positive
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  // Helper method to get item description with type indicator
  String _getItemDescription(Map<String, dynamic> item) {
    final description = item['description']?.toString() ?? '';
    final type = item['type']?.toString().toLowerCase() ?? '';

    if (description.isEmpty) {
      return type.contains('discount') ? 'Discount' : type.contains('subsidy') ? 'Subsidy' : 'Item';
    }
    return description;
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

  Widget _buildBilledForRow() {
    return Row(
      children: [
        const Text(
          'Billed For : ',
          style: TextStyle(
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Invoice loading indicator
          if (_isInvoiceLoading || _isInvoiceItemsLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading invoice details...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Invoice items table (simple format like receipt screen)
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
              const Expanded(
                child: SizedBox(
                  height: 20,
                  child: VerticalDivider(
                    width: 2,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Divider(
            thickness: 0.5,
            color: Colors.grey.withOpacity(0.3),
          ),

          // Show invoice items if available, otherwise show basic invoice info
          if (_invoiceItems != null && _invoiceItems!.isNotEmpty) ...[
            // Show each invoice item (filter out discounts/subsidies)
            ..._invoiceItems!
                .where((item) {
                  final type = item['type']?.toString().toLowerCase() ?? '';
                  return !type.contains('discount') && !type.contains('subsidy');
                })
                .map((item) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          _getItemDescription(item),
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            width: 2,
                            thickness: 1,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        _getFormattedAmount(item),
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                })
                .toList(),
          ] else ...[
            // Fallback to basic invoice info
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
                const Expanded(
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 2,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  '\$${widget.transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],

          Divider(
            thickness: 0.5,
            color: Colors.grey.withOpacity(0.3),
          ),

          // Total Amount
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
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      'View Invoice',
                      style: TextStyle(
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
                        child: _buildBilledForRow(),
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

