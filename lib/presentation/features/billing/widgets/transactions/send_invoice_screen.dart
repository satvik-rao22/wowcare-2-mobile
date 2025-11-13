import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class SendInvoiceScreen extends StatefulWidget {
  const SendInvoiceScreen({
    super.key,
    required this.transaction,
  });

  final TransactionItem transaction;

  @override
  State<SendInvoiceScreen> createState() => _SendInvoiceScreenState();
}

class _SendInvoiceScreenState extends State<SendInvoiceScreen> {
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _invoiceNumberController = TextEditingController(
      text: 'INV${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    _dueDateController = TextEditingController(text: '');
    _descriptionController = TextEditingController(text: widget.transaction.displayDescription.isEmpty ? '-' : widget.transaction.displayDescription);
    _amountController = TextEditingController(text: widget.transaction.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dueDateController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 600;
    final EdgeInsets outerPadding = EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16);
    final double cardRadius = isTablet ? 30 : 22;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 12, left: outerPadding.left, right: outerPadding.right),
                  child: Row(
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Send Invoice',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        onPressed: () {},
                        icon: const Icon(Icons.forum_outlined, color: AppColors.primaryColor),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none, color: AppColors.primaryColor),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: outerPadding,
                    child: Column(
                      children: [
                        _buildInvoiceCard(cardRadius),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, isTablet),
    );
  }

  Widget _buildInvoiceCard(double radius) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocumentImageWidget(
                fileUuid: '',
                name: 'Wise Owl Academy',
                size: 48,
                fontSize: 16,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Wise Owl Academy',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Smart Children. Bright Future.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6F5F78),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Nashua, Indiana, India, 03062',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9587A2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Billed for : ',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              DocumentImageWidget(
                fileUuid: widget.transaction.studentPhotoUuid ?? '',
                name: widget.transaction.studentName,
                size: 32,
                fontSize: 13,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.transaction.studentName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              if (widget.transaction.classroom.isNotEmpty)
                Text(
                  widget.transaction.classroom,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9686A0),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow('Invoice Number :', _invoiceNumberController.text),
          const SizedBox(height: 8),
          _infoRow('Invoice Period :', 'N/A'),
          const SizedBox(height: 8),
          _infoRow('Due Date :', _dueDateController.text),
          const SizedBox(height: 20),
          _buildInvoiceTable(),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9F94B4),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDFF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Column(
        children: [
          _tableRow('Description', 'Amount', isHeader: true),
          const SizedBox(height: 10),
          _tableRow(
            _descriptionController.text.isEmpty ? '-' : _descriptionController.text,
            _formatCurrency(double.tryParse(_amountController.text) ?? 0),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE3DBF7),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: _tableRow(
              'Total Amount',
              _formatCurrency(double.tryParse(_amountController.text) ?? 0),
              emphasize: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(String left, String right, {bool isHeader = false, bool emphasize = false}) {
    final TextStyle baseStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: isHeader ? 13 : 14,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
      color: isHeader ? const Color(0xFF8B7BA3) : AppColors.primaryColor,
    );
    final TextStyle valueStyle = baseStyle.copyWith(
      fontWeight: emphasize ? FontWeight.w700 : baseStyle.fontWeight,
      color: emphasize ? AppColors.primaryColor : baseStyle.color,
      fontSize: emphasize ? 15 : baseStyle.fontSize,
    );
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(left, style: baseStyle),
        ),
        Expanded(
          flex: 2,
          child: Text(
            right,
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isTablet) {
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    final double buttonHeight = isTablet ? 56 : 48;
    final double buttonFontSize = isTablet ? 18 : 16;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, safeBottom > 0 ? safeBottom : 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox(
        height: buttonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.buildPrimaryGradient(),
            borderRadius: BorderRadius.circular(isTablet ? 18 : 12),
          ),
          child: TextButton(
            onPressed: _isSending
                ? null
                : () async {
                    setState(() => _isSending = true);
                    await Future<void>.delayed(const Duration(seconds: 1));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice sent (mock).')),
                    );
                    setState(() => _isSending = false);
                    if (mounted) {
                      Navigator.of(context).maybePop(true);
                    }
                  },
            child: _isSending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sending... ',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Send Invoice',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(1)}';
  }
}
