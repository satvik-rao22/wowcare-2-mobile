import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class TransactionItem {
  TransactionItem({
    required this.id,
    required this.transactionType,
    required this.date,
    required this.amount,
    required this.status,
    required this.description,
    required this.studentName,
    required this.classroom,
    this.studentId,
    this.studentPhotoUuid,
    this.refTable,
    this.refTableId,
    this.balance,
    this.note,
    this.endDate,
    this.paymentMode,
    this.studentOpenBalance,
  });

  final int id;
  final String transactionType;
  final DateTime date;
  final double amount;
  final String status;
  final String description;
  final String studentName;
  final String classroom;
  final int? studentId;
  final String? studentPhotoUuid;
  final String? refTable;
  final int? refTableId;
  final double? balance;
  final String? note;
  final String? endDate;
  final String? paymentMode;
  final double? studentOpenBalance;

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    final List<dynamic> students = (map['students'] as List<dynamic>? ?? <dynamic>[]);
    final Map<String, dynamic>? firstStudent =
        students.isNotEmpty ? students.first as Map<String, dynamic> : null;

    return TransactionItem(
      id: map['id'] as int,
      transactionType: (map['transactionType'] ?? '').toString(),
      date: DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: (map['processStatus'] ?? map['status'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      studentName: (firstStudent?['fullName'] ?? 'Unknown').toString(),
      classroom: (firstStudent?['roomName'] ?? '').toString(),
      studentId: firstStudent?['id'] as int?,
      studentPhotoUuid: firstStudent?['photoUuid'] as String?,
      refTable: map['refTable'] as String?,
      refTableId: map['refTableId'] as int?,
      balance: (map['balance'] as num?)?.toDouble(),
      note: map['note'] as String?,
      endDate: map['endDate'] as String?,
      paymentMode: map['paymentMode'] as String?,
      studentOpenBalance: (firstStudent?['balance'] as num?)?.toDouble(),
    );
  }

  String get displayDescription => description.isEmpty ? '-' : description;
}

class TransactionDiffCard extends StatefulWidget {
  const TransactionDiffCard({
    super.key,
    required this.transaction,
    this.onSendInvoice,
    this.onReceivePayment,
    this.onView,
    this.onLongPress,
    this.onDelete,
    this.onViewReceipt,
    this.onIssueRefund,
  });

  final TransactionItem transaction;
  final VoidCallback? onSendInvoice;
  final VoidCallback? onReceivePayment;
  final VoidCallback? onView;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onIssueRefund;

  @override
  State<TransactionDiffCard> createState() => _TransactionDiffCardState();
}

class _TransactionDiffCardState extends State<TransactionDiffCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final TransactionItem transaction = widget.transaction;
    final String statusLower = transaction.status.toLowerCase();
    final String formattedAmount = _formatCurrency(transaction.amount);

    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1A162831), width: 1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            onLongPress: widget.onLongPress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(transaction),
                if (_isExpanded) ...<Widget>[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFE9ECEF),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _detailRow('Type', transaction.transactionType),
                        const SizedBox(height: 12),
                        _detailRow('Date', _formatDateTime(transaction.date)),
                        const SizedBox(height: 12),
                        _detailRow('Description', transaction.displayDescription),
                        const SizedBox(height: 12),
                        _statusRow(transaction.status),
                        const SizedBox(height: 12),
                        _detailRow('Amount', formattedAmount),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildActions(statusLower),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TransactionItem tx) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          DocumentImageWidget(
            fileUuid: tx.studentPhotoUuid ?? '',
            name: tx.studentName,
            size: 38,
            shape: BoxShape.circle,
            fit: BoxFit.cover,
            fontSize: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tx.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xff573353),
                    height: 19 / 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tx.classroom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF5978F7),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Text(
          'Status',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff573353),
            height: 20 / 14,
          ),
        ),
        _buildStatusTag(status),
      ],
    );
  }

  Widget _buildActions(String statusLower) {
    if (statusLower == 'sent' || statusLower == 'draft') {
      return Row(
        children: <Widget>[
          Expanded(child: _outlinedButton('View', widget.onView)),
          const SizedBox(width: 12),
          Expanded(child: _outlinedButton('Send Invoice', widget.onSendInvoice)),
          const SizedBox(width: 12),
          Expanded(child: _gradientButton('Receive Payment', widget.onReceivePayment)),
        ],
      );
    }

    if (statusLower == 'success') {
      return Row(
        children: <Widget>[
          Expanded(child: _outlinedButton('View Receipt', widget.onViewReceipt)),
          const SizedBox(width: 12),
          Expanded(child: _gradientButton('Issue Refund', widget.onIssueRefund)),
        ],
      );
    }

    if (statusLower == 'in-process') {
      return Row(
        children: <Widget>[
          Expanded(child: _outlinedButton('View Receipt', widget.onViewReceipt)),
          const SizedBox(width: 12),
          Expanded(child: _gradientButton('Issue Refund', widget.onIssueRefund, enabled: false)),
        ],
      );
    }

    return _outlinedButton('View', widget.onView);
  }

  Widget _outlinedButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF6C7FD8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: onPressed == null ? const Color(0xFF9E9E9E) : const Color(0xFF6C7FD8),
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _gradientButton(String label, VoidCallback? onPressed, {bool enabled = true}) {
    final bool isEnabled = enabled && onPressed != null;
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: isEnabled ? null : const Color(0xFFE0E0E0),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isEnabled
                ? AppColors.buildPrimaryGradient()
                : const LinearGradient(colors: <Color>[Color(0xFFE0E0E0), Color(0xFFE0E0E0)]),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : const Color(0xFF9E9E9E),
                height: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBackgroundColor(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF4B5B7A),
        ),
      ),
    );
  }

  Color _statusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return const Color(0x4D4CAF50);
      case 'failed':
        return const Color(0x4DF44336);
      case 'cancelled':
        return const Color(0x4D9E9E9E);
      case 'in-process':
      case 'processing':
        return const Color(0x4DFF9800);
      case 'sent':
      case 'draft':
        return const Color(0xFFE4E7F5);
      default:
        return AppColors.fieldBackgroundColor;
    }
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
              height: 16 / 12,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff573353),
              height: 19 / 14,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) => DateFormat('MMM dd, h:mm a').format(dateTime);

  String _formatCurrency(double value) {
    final String amount = value.toStringAsFixed(2);
    return String.fromCharCode(36) + amount;
  }
}
