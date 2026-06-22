import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/usecases/issue_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/resend_invoice_usecase.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
  // Dummy data for UI
  Map<String, dynamic>? _invoiceDetails;

  // Form controllers
  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Form data
  String _invoiceNumber = '';

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
    _initializeFormData();
  }

  void _initializeDummyData() {
    // Load dummy data
    Map<String, dynamic>? invoiceData;
    if (widget.transaction.refTable == 'Invoice' && widget.transaction.refTableId != null) {
      invoiceData = {
        'invoiceNumber': 'INV-2025-${widget.transaction.refTableId}',
        'startDate': widget.transaction.date.subtract(const Duration(days: 30)).toIso8601String(),
        'endDate': widget.transaction.date.toIso8601String(),
        'dueDate': widget.transaction.endDate != null
            ? DateTime.parse(widget.transaction.endDate!).toIso8601String()
            : widget.transaction.date.add(const Duration(days: 7)).toIso8601String(),
        'invoiceAmount': widget.transaction.amount,
        'description': widget.transaction.description,
      };
    }

    _invoiceDetails = invoiceData;

    // Update form with invoice data if available
    if (invoiceData != null) {
      _updateFormWithInvoiceData(invoiceData);
    }
  }

  void _initializeFormData() {
    // Generate invoice number based on current date
    final now = DateTime.now();
    _invoiceNumber = 'INV${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _invoiceNumberController.text = _invoiceNumber;

    // Pre-fill with transaction data
    _descriptionController.text = widget.transaction.displayDescription;
    _amountController.text = widget.transaction.amount.toStringAsFixed(2);

    // Set form data
  }

  void _updateFormWithInvoiceData(Map<String, dynamic> invoiceData) {
    // Update invoice number
    if (invoiceData['invoiceNumber'] != null) {
      _invoiceNumberController.text = invoiceData['invoiceNumber'].toString();
      _invoiceNumber = _invoiceNumberController.text;
    }

    // Update due date
    if (invoiceData['dueDate'] != null) {
      try {
        final dueDateParsed = DateTime.parse(invoiceData['dueDate'].toString());
        _dueDateController.text = DateUtilsNew.formatToReadableDate(dueDateParsed);
      } catch (e) {
        // Date parsing failed, keep current value
      }
    }

    // Update amount
    if (invoiceData['invoiceAmount'] != null) {
      final invoiceAmount = double.tryParse(invoiceData['invoiceAmount'].toString()) ?? 0.0;
      _amountController.text = invoiceAmount.toStringAsFixed(2);
    }

    // Update description if available
    if (invoiceData['description'] != null && invoiceData['description'].toString().isNotEmpty) {
      _descriptionController.text = invoiceData['description'].toString();
    }
  }

  String _getInvoicePeriodText() {
    // Only show data from dummy invoice details, no hardcoded fallbacks
    if (_invoiceDetails == null) {
      // Check if this is because the transaction doesn't reference an invoice
      if (widget.transaction.refTable != 'Invoice') {
        return 'Not applicable - Transaction references ${widget.transaction.refTable}';
      }
      return 'N/A';
    }

    final startDate = _invoiceDetails!['startDate'];
    final endDate = _invoiceDetails!['endDate'];

    if (startDate == null && endDate == null) {
      return 'Not specified in invoice';
    }

    try {
      String startText = 'Not specified';
      String endText = 'Not specified';

      if (startDate != null) {
        final startParsed = DateTime.parse(startDate.toString());
        startText = DateUtilsNew.formatToReadableDate(startParsed);
      }

      if (endDate != null) {
        final endParsed = DateTime.parse(endDate.toString());
        endText = DateUtilsNew.formatToReadableDate(endParsed);
      }

      return '$startText - $endText';
    } catch (e) {
      return 'Date format error';
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dueDateController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _isSending = false;

  /// A draft is issued (POST /issue); an already-issued invoice is re-sent
  /// (PATCH /resend).
  bool get _isDraft => widget.transaction.status.toUpperCase().contains('DRAFT');

  Future<void> _sendInvoice() async {
    if (_isSending) return;
    final code = widget.transaction.invoiceCode?.trim();
    if (code == null || code.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'This invoice cannot be sent.',
        isWarning: true,
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      if (_isDraft) {
        await serviceLocator<IssueInvoiceUseCase>()(code);
      } else {
        await serviceLocator<ResendInvoiceUseCase>()(code);
      }
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _isDraft
            ? 'Invoice sent successfully.'
            : 'Invoice re-sent successfully.',
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  Widget _buildBilledForRow() {
    return Row(
      children: [
        Text(
          'Billed for : ',
          style: AppTextStyles.title.copyWith(
            fontSize: 16,
            color: AppColors.primaryColor,
          ),
        ),
        DocumentImageWidget(
          fileUuid: widget.transaction.studentPhotoUuid ?? '',
          name: widget.transaction.studentName,
          size: 50,
        ),
        const SizedBox(width: 5),
        Text(
          widget.transaction.studentName,
          style: AppTextStyles.value.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        if (widget.transaction.classroom.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            widget.transaction.classroom,
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return Column(
      children: [
        Row(
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
              _invoiceNumberController.text,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.billingGreyDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Invoice Period : ',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.billingGreyMedium,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 4),
              Text(
                _getInvoicePeriodText(),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.billingGreyDark,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
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
              _dueDateController.text.isEmpty ? 'Not set' : _dueDateController.text,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.billingGreyDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.billingGreyLight,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Table Headers
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.billingGreyMedium,
                    fontWeight: FontWeight.w500,
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
                    color: AppColors.billingGreyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Divider(
            thickness: 0.5,
            color: AppColors.billingGreyTransparent,
          ),
          // Table Row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  _descriptionController.text.isEmpty ? '-' : _descriptionController.text,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '\$${_amountController.text}',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Divider(
            thickness: 0.5,
            color: AppColors.billingGreyTransparent,
          ),
          // Total Row with highlighted background
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${_amountController.text}',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Send Invoice',
      bottomBar: _buildBottomBar(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BillingSchoolHeader(),
            const SizedBox(height: 20),
            _buildBilledForRow(),
            const SizedBox(height: 16),
            _buildInvoiceDetailsSection(),
            const SizedBox(height: 16),
            _buildInvoiceTable(),
          ],
        ),
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
            onPressed: _isSending ? null : _sendInvoice,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isDraft ? 'Send Invoice' : 'Resend Invoice',
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

