// ignore_for_file: use_string_in_part_of_directives
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Local enums
// ---------------------------------------------------------------------------

enum _PaymentType { invoice, transaction, refund }

// ---------------------------------------------------------------------------
// Local mock-data model classes (plain Dart – no entity imports)
// ---------------------------------------------------------------------------

class _MockStudent {
  const _MockStudent({
    required this.id,
    required this.fullName,
    required this.roomName,
  });

  final int id;
  final String fullName;
  final String roomName;
}

class _MockInvoice {
  const _MockInvoice({
    required this.id,
    required this.date,
    required this.invoiceAmount,
    required this.openBalanceAmount,
    required this.invoiceStatus,
    required this.description,
    required this.studentId,
    this.invoiceNumber = '',
  });

  final int id;
  final String date;
  final double invoiceAmount;
  final double openBalanceAmount;
  final String invoiceStatus;
  final String description;
  final int studentId;
  final String invoiceNumber;
}

class _MockTransaction {
  const _MockTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.transactionType,
    required this.processStatus,
    required this.paymentMode,
    required this.displayDescription,
    required this.localBalanceAmount,
    required this.studentId,
  });

  final int id;
  final String date;
  final double amount;
  final String transactionType;
  final String processStatus;
  final String paymentMode;
  final String displayDescription;
  final double localBalanceAmount;
  final int studentId;
}

class _PaymentItem {
  const _PaymentItem({
    required this.date,
    required this.type,
    required this.data,
  });

  final DateTime date;
  final _PaymentType type;
  final Object data;
}

// ---------------------------------------------------------------------------
// Hardcoded mock data
// ---------------------------------------------------------------------------

const _mockStudents = <_MockStudent>[
  _MockStudent(id: 1, fullName: 'Emma Johnson', roomName: 'Sunshine Room'),
  _MockStudent(id: 2, fullName: 'Liam Johnson', roomName: 'Rainbow Room'),
];

const _mockInvoices = <_MockInvoice>[
  _MockInvoice(
    id: 101,
    date: '2026-05-01',
    invoiceAmount: 850.00,
    openBalanceAmount: 850.00,
    invoiceStatus: 'Pending',
    description: 'Monthly tuition – May 2026',
    studentId: 1,
    invoiceNumber: 'INV-2026-0501',
  ),
  _MockInvoice(
    id: 102,
    date: '2026-04-01',
    invoiceAmount: 850.00,
    openBalanceAmount: 0.00,
    invoiceStatus: 'Paid',
    description: 'Monthly tuition – Apr 2026',
    studentId: 2,
    invoiceNumber: 'INV-2026-0402',
  ),
];

const _mockTransactions = <_MockTransaction>[
  _MockTransaction(
    id: 201,
    date: '2026-04-15',
    amount: 850.00,
    transactionType: 'Payment',
    processStatus: 'Completed',
    paymentMode: 'Credit Card',
    displayDescription: 'April tuition payment',
    localBalanceAmount: 0.00,
    studentId: 2,
  ),
];

const _mockRefunds = <_MockTransaction>[
  _MockTransaction(
    id: 301,
    date: '2026-03-20',
    amount: 120.00,
    transactionType: 'Refund',
    processStatus: 'Completed',
    paymentMode: 'Credit Card',
    displayDescription: 'Refund – unused supply fee',
    localBalanceAmount: 120.00,
    studentId: 1,
  ),
];

/// Total unpaid balance across all children (sum of open invoices).
const double _mockCurrentBalance = 850.00;

// ---------------------------------------------------------------------------
// Helper: format DateTime to a readable string inline (no date_utils import)
// ---------------------------------------------------------------------------

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class StudentBillingCard extends StatefulWidget {
  const StudentBillingCard({super.key});

  @override
  State<StudentBillingCard> createState() => _StudentBillingCardState();
}

class _StudentBillingCardState extends State<StudentBillingCard> {
  bool _isMinimized = false;

  // ---------------------------------------------------------------------------
  // Student avatar row item
  // ---------------------------------------------------------------------------

  Widget _buildStudentChip(_MockStudent student) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DocumentImageWidget(
          fileUuid: '',
          name: student.fullName,
          size: 30,
          fontSize: 12,
          disableProfileLookupFallback: true,
          disableAttendanceStatusLookup: true,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                student.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                student.roomName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Payment tile – Payment type
  // ---------------------------------------------------------------------------

  Widget _buildPaymentTile(_MockTransaction transaction) {
    final paidOn = DateTime.parse(transaction.date);
    return ExpansionTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.billingPaymentBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Payment',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${transaction.processStatus}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Paid On: ${_formatDate(paidOn)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.billingCardColor,
      collapsedBackgroundColor: AppColors.billingCardColor,
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.billingCardBorderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.billingCardBorderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Divider(color: AppColors.billingDividerColor),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              transaction.paymentMode,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.displayDescription,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Open balance',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '\$${transaction.localBalanceAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.billingBorderMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'View Receipt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Invoice tile
  // ---------------------------------------------------------------------------

  Widget _buildInvoiceTile(_MockInvoice invoice) {
    final student = _mockStudents.firstWhere(
      (s) => s.id == invoice.studentId,
      orElse: () => _mockStudents.first,
    );
    final dueDate = DateTime.parse(invoice.date);
    return ExpansionTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.billingInvoiceBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Invoice',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${invoice.invoiceStatus}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${invoice.invoiceAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Created On: ${_formatDate(dueDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.billingCardColor,
      collapsedBackgroundColor: AppColors.billingCardColor,
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.billingCardBorderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.billingCardBorderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Divider(color: AppColors.billingDividerColor),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Name',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 5),
            _buildStudentChip(student),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                invoice.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Open balance',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '\$${invoice.openBalanceAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.billingBorderMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'View Invoice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Refund tile
  // ---------------------------------------------------------------------------

  Widget _buildRefundTile(_MockTransaction transaction) {
    final paidOn = DateTime.parse(transaction.date);
    return ExpansionTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.billingRefundBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Refund',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromRGBO(55, 65, 88, 1),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${transaction.processStatus}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Paid On: ${_formatDate(paidOn)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.billingCardColor,
      collapsedBackgroundColor: AppColors.billingCardColor,
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.billingCardBorderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.billingCardBorderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Divider(color: AppColors.billingDividerColor),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              transaction.paymentMode,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.displayDescription,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Open balance',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '\$${transaction.localBalanceAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build the sorted/merged payment list (top 3 most-recent items)
  // ---------------------------------------------------------------------------

  List<Widget> _buildPaymentList() {
    final List<_PaymentItem> items = [
      ..._mockInvoices.map(
        (inv) => _PaymentItem(
          date: DateTime.parse(inv.date),
          type: _PaymentType.invoice,
          data: inv,
        ),
      ),
      ..._mockTransactions.map(
        (txn) => _PaymentItem(
          date: DateTime.parse(txn.date),
          type: _PaymentType.transaction,
          data: txn,
        ),
      ),
      ..._mockRefunds.map(
        (ref) => _PaymentItem(
          date: DateTime.parse(ref.date),
          type: _PaymentType.refund,
          data: ref,
        ),
      ),
    ];

    if (items.isEmpty) {
      return [
        const Center(
          child: Text(
            'No Transactions',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ];
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    final visible = items.length > 3 ? items.sublist(0, 3) : items;

    return visible.map((item) {
      switch (item.type) {
        case _PaymentType.invoice:
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildInvoiceTile(item.data as _MockInvoice),
          );
        case _PaymentType.transaction:
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildPaymentTile(item.data as _MockTransaction),
          );
        case _PaymentType.refund:
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildRefundTile(item.data as _MockTransaction),
          );
      }
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ----------------------------------------------------------------
            // Header
            // ----------------------------------------------------------------
            DashboardCardHeader(
              title: 'Billing',
              minimized: _isMinimized,
              onToggle: () => setState(() => _isMinimized = !_isMinimized),
              showRedirect: true,
              onRedirect: () {},
            ),

            if (!_isMinimized) ...[
              const SizedBox(height: 16),

              // --------------------------------------------------------------
              // Student grid
              // --------------------------------------------------------------
              GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0,
                  childAspectRatio: 2,
                  crossAxisSpacing: 10,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mockStudents.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final student = _mockStudents[index];
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStudentChip(student),
                  );
                },
              ),

              const SizedBox(height: 15),

              // --------------------------------------------------------------
              // Current balance + Pay Now button row
              // --------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Current balance column
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_mockCurrentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.themeColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Current\nBalance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromRGBO(65, 65, 76, 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Pay Now button
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      child: CustomButtonLayout(
                        isForm: false,
                        showCancelButton: false,
                        confirmButtonLabel: 'Pay Now',
                        onPressedConfirm: () {},
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // --------------------------------------------------------------
              // Recent transactions list (invoices, payments, refunds)
              // --------------------------------------------------------------
              Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildPaymentList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
