import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

class ViewInvoiceScreen extends StatefulWidget {
  const ViewInvoiceScreen({
    super.key,
    required this.transaction,
  });

  static const String routeName = '/billing/view-invoice';

  final TransactionItem transaction;

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  // Unpadded day (e.g. "Aug 9, 2026") to match the web invoice modal.
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  String _formatDate(DateTime date) => _dateFormat.format(date);

  // Invoices carry no room field of their own, so the student's current
  // classroom is looked up separately by student code.
  String? _roomName;

  // The transaction row (esp. the family-ledger "Family Transaction" list)
  // only carries a summary shape with no invoice number/due date/service
  // period — the web app's invoice modal shows all three, so the full
  // invoice is fetched by code here to match it, regardless of which list
  // this screen was opened from.
  InvoiceListItemEntity? _invoiceDetail;

  @override
  void initState() {
    super.initState();
    _loadRoomName();
    _loadInvoiceDetail();
  }

  Future<void> _loadRoomName() async {
    final code = widget.transaction.studentCode?.trim();
    if (code == null || code.isEmpty) return;
    try {
      final profile = await serviceLocator<GetStudentProfileUseCase>()(
        code: code,
      );
      if (!mounted) return;
      setState(() => _roomName = profile.classroomName);
    } catch (_) {
      // No room fallback — the row is simply omitted.
    }
  }

  Future<void> _loadInvoiceDetail() async {
    final code = widget.transaction.invoiceCode?.trim();
    if (code == null || code.isEmpty) {
      debugPrint(
        '[ViewInvoiceScreen] No invoiceCode on this transaction row — '
        'Invoice Number/Due Date/Invoice Period will fall back to the '
        'summary the list screen passed in.',
      );
      return;
    }
    try {
      final detail = await serviceLocator<GetInvoiceByCodeUseCase>()(code);
      if (!mounted) return;
      setState(() => _invoiceDetail = detail);
    } catch (e) {
      // Fall back to whatever summary fields the transaction row carried.
      CoreUtils.logApiError('[ViewInvoiceScreen] getInvoiceByCode($code) failed: $e');
    }
  }

  String? get _invoiceNumberLabel {
    final code = (_invoiceDetail?.code ?? widget.transaction.invoiceCode ?? '')
        .trim();
    return code.isEmpty ? null : code;
  }

  String? get _dueDateLabel {
    final resolved = _invoiceDetail?.dueDate;
    if (resolved != null) return _formatDate(resolved);
    final raw = widget.transaction.endDate;
    if (raw != null && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) return _formatDate(parsed);
    }
    return null;
  }

  String? get _invoicePeriodLabel {
    final start = _invoiceDetail?.periodStart;
    final end = _invoiceDetail?.periodEnd;
    if (start == null || end == null) return null;
    return '${_formatDate(start)} to ${_formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: BillingStrings.viewInvoice,
      bottomBar: _buildBottomBar(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BillingSchoolHeader(),
            const SizedBox(height: 20),
            _buildBilledForRow(),
            const SizedBox(height: 16),
            _buildInvoiceMeta(),
            const SizedBox(height: 12),
            _buildItemsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildBilledForRow() {
    final classroom = (_roomName ?? widget.transaction.classroom).trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          BillingStrings.billedForColon,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.transaction.studentName,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (classroom.isNotEmpty)
                Text(
                  classroom,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceMeta() {
    // Matches the web invoice modal's field set (Invoice Number / Due Date /
    // Invoice Period). Falls back to the issue date only if none of those
    // resolved (e.g. the invoice-detail fetch failed and the row carried no
    // invoiceCode), so the screen never renders with no date at all.
    final rows = <Widget>[
      if (_invoiceNumberLabel != null)
        _metaRow(BillingStrings.invoiceNumber, _invoiceNumberLabel!),
      if (_dueDateLabel != null)
        _metaRow(BillingStrings.dueDate, _dueDateLabel!),
      if (_invoicePeriodLabel != null)
        _metaRow(BillingStrings.invoicePeriod, _invoicePeriodLabel!),
    ];
    if (rows.isEmpty) {
      rows.add(_metaRow(
          BillingStrings.invoiceDate, _formatDate(widget.transaction.date)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          rows[i],
        ],
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.billingGreyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  BillingStrings.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                BillingStrings.amount,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  widget.transaction.displayDescription,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '\$${widget.transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  BillingStrings.totalAmount,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$${widget.transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.buildPrimaryGradient(),
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              BillingStrings.sendInvoice,
              style: TextStyle(
                color: AppColors.billingButtonTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
