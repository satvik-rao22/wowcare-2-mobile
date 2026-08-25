import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class ViewInvoiceScreen extends StatefulWidget {
  const ViewInvoiceScreen({super.key, required this.transaction});

  final TransactionItem transaction;

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  String _formatDate(DateTime date) => _dateFormat.format(date);

  // Invoices carry no room field of their own, so the student's current
  // classroom is looked up separately by student code.
  String? _roomName;

  @override
  void initState() {
    super.initState();
    _loadRoomName();
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

  String? get _dueDateLabel {
    final raw = widget.transaction.endDate;
    if (raw != null && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) return _formatDate(parsed);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'View Invoice',
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
        Text(
          'Billed for : ',
          style: AppTextStyles.body.copyWith(color: AppColors.primaryColor),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metaRow('Invoice Date', _formatDate(widget.transaction.date)),
        if (_dueDateLabel != null) ...[
          const SizedBox(height: 6),
          _metaRow('Due Date', _dueDateLabel!),
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
            style: AppTextStyles.body.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.6),
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
                  'Description',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                'Amount',
                style: AppTextStyles.body.copyWith(
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
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Text(
                '\$${widget.transaction.amount.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryColor,
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
                  'Total Amount',
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
              'Send Invoice',
              style: AppTextStyles.title.copyWith(
                color: AppColors.billingButtonTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
