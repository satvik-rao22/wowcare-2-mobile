import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_amount_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// StudentBillingCard (parent dashboard)
//
// Renders the guardian's family billing ledger — children, current balance and
// the most-recent invoices / payments / refunds. The [ParentBillingCubit] is
// provided (and kept alive) by the parent dashboard coordinator, so the card
// loads once and doesn't re-fetch on every rebuild.
// ---------------------------------------------------------------------------

class StudentBillingCard extends StatelessWidget {
  const StudentBillingCard({super.key});

  @override
  Widget build(BuildContext context) => const _StudentBillingCardBody();
}

/// Opens the full parent billing screen (bottom-nav branch) where invoice
/// details live.
void _openBillingScreen(BuildContext context) {
  context.go(ParentBillingScreen.routeName);
}

/// Opens the Pay Now flow directly (same screen the billing page uses) and
/// refreshes the card's ledger if a payment was made.
Future<void> _openPayNow(BuildContext context) async {
  final cubit = context.read<ParentBillingCubit>();
  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const PayNowAmountScreen()),
  );
  if (paid == true) cubit.refresh();
}

class _StudentBillingCardBody extends StatefulWidget {
  const _StudentBillingCardBody();

  @override
  State<_StudentBillingCardBody> createState() =>
      _StudentBillingCardBodyState();
}

class _StudentBillingCardBodyState extends State<_StudentBillingCardBody> {
  bool _isMinimized = false;

  /// Number of most-recent transactions surfaced on the dashboard card.
  static const int _maxVisibleTransactions = 3;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  bool _isRefund(FamilyLedgerTransactionEntity t) =>
      t.transactionType.toLowerCase().contains('refund');

  bool _isInvoice(FamilyLedgerTransactionEntity t) =>
      t.transactionType.toLowerCase().contains('invoice');

  // ---------------------------------------------------------------------------
  // Student avatar row item
  // ---------------------------------------------------------------------------

  Widget _buildStudentChip({required String name}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DocumentImageWidget(
          fileUuid: '',
          name: name,
          size: 30,
          fontSize: 12,
          disableProfileLookupFallback: true,
          disableAttendanceStatusLookup: true,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Payment tile – Payment type
  // ---------------------------------------------------------------------------

  Widget _buildPaymentTile(FamilyLedgerTransactionEntity transaction) {
    return ExpansionTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
            'Status: ${transaction.status}',
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
            style: const TextStyle(fontSize: 20, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 5),
          Text(
            'Paid On: ${_formatDate(transaction.date)}',
            style: const TextStyle(fontSize: 14, color: AppColors.primaryColor),
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
        _detailRow('Payment Method', transaction.method),
        const SizedBox(height: 10),
        _detailRow('Description', transaction.description, expand: true),
        const SizedBox(height: 10),
        _detailRow(
          'Open balance',
          '\$${transaction.balance.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 10),
        CustomButtonLayout(
          isForm: false,
          showCancelButton: false,
          confirmButtonLabel: 'View Receipt',
          onPressedConfirm: () => _openBillingScreen(context),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Invoice tile
  // ---------------------------------------------------------------------------

  Widget _buildInvoiceTile(FamilyLedgerTransactionEntity invoice) {
    return ExpansionTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
            'Status: ${invoice.status}',
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
            '\$${invoice.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 5),
          Text(
            'Created On: ${_formatDate(invoice.date)}',
            style: const TextStyle(fontSize: 14, color: AppColors.primaryColor),
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
        if (invoice.studentName.trim().isNotEmpty) ...[
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
              _buildStudentChip(name: invoice.studentName),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _detailRow('Description', invoice.description, expand: true),
        const SizedBox(height: 10),
        _detailRow(
          'Open balance',
          '\$${invoice.balance.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 10),
        CustomButtonLayout(
          isForm: false,
          showCancelButton: false,
          confirmButtonLabel: 'View Invoice',
          onPressedConfirm: () => _openBillingScreen(context),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Refund tile
  // ---------------------------------------------------------------------------

  Widget _buildRefundTile(FamilyLedgerTransactionEntity transaction) {
    return ExpansionTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
            'Status: ${transaction.status}',
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
            style: const TextStyle(fontSize: 20, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 5),
          Text(
            'Paid On: ${_formatDate(transaction.date)}',
            style: const TextStyle(fontSize: 14, color: AppColors.primaryColor),
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
        _detailRow('Payment Method', transaction.method),
        const SizedBox(height: 10),
        _detailRow('Description', transaction.description, expand: true),
        const SizedBox(height: 10),
        _detailRow(
          'Open balance',
          '\$${transaction.balance.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Label (left, muted) + value (right) row used inside the expandable tiles.
  Widget _detailRow(String label, String value, {bool expand = false}) {
    final valueWidget = Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.end,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryColor.withValues(alpha: 0.5),
          ),
        ),
        if (expand) Expanded(child: valueWidget) else valueWidget,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build the transaction tiles (top N most-recent items, API order preserved)
  // ---------------------------------------------------------------------------

  List<Widget> _buildTransactionList(
    List<FamilyLedgerTransactionEntity> transactions,
  ) {
    if (transactions.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No Transactions',
              style: TextStyle(fontSize: 16, color: AppColors.primaryColor),
            ),
          ),
        ),
      ];
    }

    final visible = transactions.length > _maxVisibleTransactions
        ? transactions.sublist(0, _maxVisibleTransactions)
        : transactions;

    return visible.map((txn) {
      final Widget tile;
      if (_isInvoice(txn)) {
        tile = _buildInvoiceTile(txn);
      } else if (_isRefund(txn)) {
        tile = _buildRefundTile(txn);
      } else {
        tile = _buildPaymentTile(txn);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: tile,
      );
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
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
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

            if (!_isMinimized)
              BlocBuilder<ParentBillingCubit, ParentBillingState>(
                builder: (context, state) {
                  if (state.isLoading && state.ledger == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: BillingTransactionShimmer(),
                    );
                  }

                  if (state.errorMessage != null && state.ledger == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  AppColors.primaryColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                context.read<ParentBillingCubit>().refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final students = state.students;
                  return Column(
                    children: [
                      const SizedBox(height: 16),

                      // ----------------------------------------------------
                      // Student grid
                      // ----------------------------------------------------
                      if (students.isNotEmpty)
                        GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 0,
                            childAspectRatio: 2,
                            crossAxisSpacing: 10,
                          ),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: _buildStudentChip(name: student.fullName),
                            );
                          },
                        ),

                      const SizedBox(height: 15),

                      // ----------------------------------------------------
                      // Current balance + Pay Now button row
                      // ----------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${state.openBalance.toStringAsFixed(2)}',
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
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: CustomButtonLayout(
                                isForm: false,
                                showCancelButton: false,
                                confirmButtonLabel: 'Pay Now',
                                onPressedConfirm: () => _openPayNow(context),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // ----------------------------------------------------
                      // Recent transactions (invoices, payments, refunds)
                      // ----------------------------------------------------
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            _buildTransactionList(state.visibleTransactions),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
