import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/domain/features/billing/entities/billing_statement_entity.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_receipt_screen.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/utils/date_utils.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';

/// Transaction card backed by [FamilyLedgerTransactionEntity] from the API.
class ParentTransactionCard extends StatelessWidget {
  final FamilyLedgerTransactionEntity transaction;

  /// Family name, used as the row label for guardian-level rows (e.g. a card
  /// payment) that carry no student.
  final String familyName;

  const ParentTransactionCard({
    super.key,
    required this.transaction,
    this.familyName = '',
  });

  String get _type => transaction.transactionType.toLowerCase();

  /// Header label: the student when present, otherwise the family name (for
  /// guardian-level rows such as a card payment). The status is shown on the
  /// right, not appended here.
  String get _displayName {
    if (transaction.studentName.trim().isNotEmpty) {
      return transaction.studentName;
    }
    return familyName.trim().isNotEmpty
        ? familyName.trim()
        : transaction.studentName;
  }

  /// Title-cases a raw backend status, treating underscores as word breaks so
  /// `IN_PROCESS` renders as `In Process` rather than `In_process`.
  String _formatStatus(String status) {
    if (status.isEmpty) return status;
    return status
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _dateLabel() {
    if (transaction.date == null) return '';
    // Labels (Due Date / Paid On / Refunded On) are dropped to save horizontal
    // space; the badge already conveys the transaction type.
    return DateUtilsNew.formatToReadableDate(transaction.date!);
  }

  /// Badge text: the transaction type with the status in brackets, e.g.
  /// `Payment (In Process)` / `Invoice (Sent)`.
  String _badgeLabel(String type) {
    final status = _formatStatus(transaction.status);
    return status.isEmpty ? type : '$type ($status)';
  }

  ({String label, Color color, Color textColor}) _badge() {
    switch (_type) {
      case 'invoice':
        return (
          label: BillingStrings.invoice,
          color: AppColors.billingInvoiceBadgeColor,
          textColor: AppColors.secondaryColor,
        );
      case 'refund':
        return (
          label: BillingStrings.refund,
          color: AppColors.billingRefundBadgeColor,
          textColor: AppColors.billingGreyDark,
        );
      default:
        return (
          label: BillingStrings.payment,
          color: AppColors.billingPaymentBadgeColor,
          textColor: AppColors.secondaryColor,
        );
    }
  }

  /// Adapts the family-ledger row into the [TransactionItem] the shared
  /// View Receipt / View Invoice screens expect. `id` is display-only (those
  /// screens address invoices by [TransactionItem.invoiceCode]), so a numeric
  /// id isn't required — we derive one from the ledger id's digits.
  TransactionItem _toTransactionItem() {
    return TransactionItem(
      id: int.tryParse(transaction.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      transactionType: transaction.transactionType,
      date: transaction.date ?? billingSchoolNow(),
      amount: transaction.amount,
      status: transaction.status,
      description: transaction.description,
      studentName: transaction.studentName,
      classroom: '',
      studentCode:
          transaction.studentCode.isNotEmpty ? transaction.studentCode : null,
      paidAmount: transaction.paidAmount,
      refundedAmount: transaction.refundedAmount,
      invoiceCode: transaction.invoiceCode,
      balance: transaction.balance,
      paymentMode: transaction.method,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final badge = _badge();

    final expanded = <Widget>[];
    if (transaction.method.isNotEmpty && _type != 'invoice') {
      expanded
        ..add(StaffCardDetailRow(
          label: BillingStrings.paymentMethod,
          value: transaction.method,
        ))
        ..add(const SizedBox(height: 10));
    }
    expanded.add(StaffCardDetailRow(
      label: BillingStrings.status,
      value: _formatStatus(transaction.status),
    ));
    expanded.add(const SizedBox(height: 10));
    if (transaction.description.isNotEmpty) {
      expanded.add(StaffCardDetailRow(
        label: BillingStrings.description,
        value: transaction.description,
      ));
      expanded.add(const SizedBox(height: 10));
    }
    if (transaction.items.isNotEmpty) {
      expanded.add(StaffCardDetailRow(
        label: BillingStrings.items,
        value: transaction.items.join(', '),
      ));
      expanded.add(const SizedBox(height: 10));
    }
    expanded.add(StaffCardDetailRow(
      label: BillingStrings.amount,
      value: '\$${transaction.amount.toStringAsFixed(2)}',
    ));
    if (_type == 'payment') {
      expanded
        ..add(const SizedBox(height: 16))
        ..add(StaffCardActions(
          primaryLabel: BillingStrings.viewReceipt,
          onPrimary: () => context.push(
            ViewReceiptScreen.routeName,
            extra: ViewReceiptArgs(
              transaction: _toTransactionItem(),
              viewType: 'receipt',
            ),
          ),
        ));
    } else if (_type == 'invoice') {
      expanded
        ..add(const SizedBox(height: 16))
        ..add(StaffCardActions(
          primaryLabel: BillingStrings.viewInvoice,
          onPrimary: () => context.push(
            ViewInvoiceScreen.routeName,
            extra: ViewInvoiceArgs(
              transaction: _toTransactionItem(),
            ),
          ),
        ));
    }

    return StaffStyleCard(
      leading: DocumentImageWidget(
        fileUuid: '',
        name: _displayName,
        size: 50,
      ),
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: BillingCardText.name(isTablet),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                _Badge(
                  label: _badgeLabel(badge.label),
                  color: badge.color,
                  textColor: badge.textColor,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: BillingCardText.name(isTablet)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLabel(),
                style: BillingCardText.note,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
      expandedChildren: expanded,
    );
  }
}

/// Statement card — styled to match the staff card. Backed by a real
/// [BillingStatementEntity]; Download (and View) fetch the statement PDF and
/// open it on the device.
class ParentStatementCard extends StatelessWidget {
  final BillingStatementEntity statement;

  /// Names of the children this statement covers (shown as the card title).
  final String studentNames;

  /// Whether this statement's PDF is currently downloading.
  final bool isDownloading;

  final VoidCallback onDownload;
  final VoidCallback? onView;

  const ParentStatementCard({
    super.key,
    required this.statement,
    required this.studentNames,
    required this.isDownloading,
    required this.onDownload,
    this.onView,
  });

  String get _title => studentNames.isNotEmpty ? studentNames : BillingStrings.statement;

  String get _formattedType => statement.statementType.isEmpty
      ? '—'
      : statement.statementType[0].toUpperCase() +
          statement.statementType.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final generatedAt = statement.generatedAt;
    return StaffStyleCard(
      leading: DocumentImageWidget(
        fileUuid: '',
        name: _title,
        size: 50,
      ),
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              _title,
              style: BillingCardText.name(isTablet),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _Badge(
            label: BillingStrings.statement,
            color: AppColors.billingPaymentBadgeColor,
            textColor: AppColors.secondaryColor,
          ),
        ],
      ),
      expandedChildren: [
        StaffCardDetailRow(
          label: BillingStrings.statementType,
          value: _formattedType,
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: BillingStrings.generatedOn,
          value: generatedAt != null
              ? DateUtilsNew.formatToReadableDate(generatedAt)
              : '—',
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: BillingStrings.statementPeriod,
          value:
              '${DateUtilsNew.formatToReadableDate(statement.periodStart)} - ${DateUtilsNew.formatToReadableDate(statement.periodEnd)}',
        ),
        const SizedBox(height: 16),
        StaffCardActions(
          // Both actions share the same fetch-in-flight flag, so the label
          // stays generic rather than claiming "Downloading…" while a View
          // fetch is actually what's in flight.
          secondaryLabel: isDownloading ? BillingStrings.loading : BillingStrings.view,
          onSecondary: isDownloading ? null : onView,
          primaryLabel: isDownloading ? BillingStrings.loading : BillingStrings.download,
          onPrimary: isDownloading ? null : onDownload,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: BillingCardText.label.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
