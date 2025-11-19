import 'package:flutter/material.dart';
import 'package:wowcare/core/common/widgets/expandable_info_card.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_student_vertical_popup.dart';

class BillingStudentCard extends StatefulWidget {
  const BillingStudentCard({
    Key? key,
    required this.name,
    required this.classroom,
    this.fileUuid,
    required this.amount,
    required this.paidOn,
    required this.paymentMethod,
    required this.paymentNote,
    required this.lastPaymentStatus,
    required this.lastInvoiceAmount,
    required this.lastInvoiceSent,
    required this.lastInvoiceDue,
    required this.openBalance,
    this.onLongPress,
    this.showSelection = true,
    this.isSelected = false,
    this.onSelected,
    this.onMessage,
    this.onBillingProfile,
    this.onToggleSelection,
  }) : super(key: key);

  final String name;
  final String classroom;
  final String? fileUuid;
  final double amount;
  final String paidOn;
  final String paymentMethod;
  final String paymentNote;
  final String lastPaymentStatus;
  final double lastInvoiceAmount;
  final String lastInvoiceSent;
  final String lastInvoiceDue;
  final double openBalance;
  final VoidCallback? onLongPress;
  final bool showSelection;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;
  final VoidCallback? onMessage;
  final VoidCallback? onBillingProfile;
  final ValueChanged<bool>? onToggleSelection;

  @override
  State<BillingStudentCard> createState() => _BillingStudentCardState();
}

class _BillingStudentCardState extends State<BillingStudentCard> {
  late bool _localSelected;

  bool get _isSelectionControlled => widget.onSelected != null;

  bool get _checkboxValue => _isSelectionControlled ? widget.isSelected : _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(covariant BillingStudentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSelectionControlled && widget.isSelected != oldWidget.isSelected) {
      _localSelected = widget.isSelected;
    }
  }

  void _handleSelectionChanged(BuildContext context, bool? value) {
    if (!_isSelectionControlled) {
      setState(() {
        _localSelected = value ?? false;
      });
    }
    widget.onSelected?.call(value);
    widget.onToggleSelection?.call(_checkboxValue);
    _showActionsMenu(context);
  }

  void _clearSelection() {
    if (!_isSelectionControlled) {
      setState(() {
        _localSelected = false;
      });
    }
    widget.onSelected?.call(false);
    widget.onToggleSelection?.call(false);
  }

  void _showActionsMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BillingStudentVerticalPopUp(
              onMessageTap: () {
                Navigator.of(dialogContext).pop();
                widget.onMessage?.call();
              },
              onBillingProfileTap: () {
                Navigator.of(dialogContext).pop();
                widget.onBillingProfile?.call();
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    ).then((_) => _clearSelection());
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (widget.lastPaymentStatus) {
      case 'Success':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = const Color(0xff573353);
    }

    return ExpandableInfoCard(
      collapsedPrefix: widget.showSelection
          ? Builder(
              builder: (context) => CustomCheckbox(
                value: _checkboxValue,
                onChanged: (value) => _handleSelectionChanged(context, value),
                scale: 1.2,
                borderColor: null,
                label: null,
              ),
            )
          : null,
      leading: DocumentImageWidget(
        fileUuid: widget.fileUuid ?? '',
        name: widget.name,
        size: 48,
        shape: BoxShape.circle,
        fit: BoxFit.cover,
        fontSize: 14,
        statusColor: statusColor,
      ),
      titleText: widget.name,
      titleStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Color(0xff573353),
        height: 22 / 16,
      ),
      subtitleText: widget.classroom,
      onLongPress: widget.onLongPress,
      rows: [
        InfoRowItem(
          label: 'Payment Method',
          valueText: widget.paymentMethod,
          noteText: widget.paymentNote,
        ),
        InfoRowItem(
          label: 'Last Payment Status',
          valueText: widget.lastPaymentStatus,
          valueStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
        InfoRowItem(
          label: 'Last Invoice',
          valueText: '\$${widget.lastInvoiceAmount.toStringAsFixed(0)}',
          noteText: 'SENT: ${widget.lastInvoiceSent}   DUE: ${widget.lastInvoiceDue}',
        ),
        InfoRowItem(
          label: 'Open Balance',
          valueText: '\$${widget.openBalance.toStringAsFixed(0)}',
        ),
      ],
    );
  }
}