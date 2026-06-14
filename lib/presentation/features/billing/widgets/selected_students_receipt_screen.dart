import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class SelectedStudentsReceiptScreen extends StatefulWidget {
  const SelectedStudentsReceiptScreen({
    super.key,
    required this.selectedStudents,
    required this.invoiceData,
    this.onStudentRemoved,
    this.isConfirmation = false,
  });

  final List<Student> selectedStudents;
  final Map<String, dynamic> invoiceData;
  final void Function(Student student)? onStudentRemoved;

  /// When true the invoice has already been created — the screen is a read-only
  /// confirmation, so the bottom bar shows a single "Done" button.
  final bool isConfirmation;

  @override
  State<SelectedStudentsReceiptScreen> createState() => _SelectedStudentsReceiptScreenState();
}

class _SelectedStudentsReceiptScreenState extends State<SelectedStudentsReceiptScreen> {
  bool isProcessing = false;

  double _computeTotalAmount() {
    double totalAmount = 0.0;
    final invoiceItems = widget.invoiceData['invoiceItems'] as List<dynamic>? ?? [];
    for (var item in invoiceItems) {
      if (item is Map<String, dynamic>) {
        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final type = item['type']?.toString() ?? '';
        if (type == 'Discount' || type == 'Subsidy') {
          totalAmount -= amount;
        } else {
          totalAmount += amount;
        }
      }
    }
    return totalAmount;
  }

  Widget _buildInvoiceDetails(ResponsiveHelper responsive) {
    final invoiceData = widget.invoiceData;
    final items = invoiceData['invoiceItems'] as List<dynamic>? ?? const [];
    final totalAmount = _computeTotalAmount();

    // School header (UI-only; uses initials avatar)
    final schoolHeader = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentImageWidget(
          fileUuid: 'demo-school', // UI only
          name: 'Demo School',
          size: 56,
          fontSize: 18,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demo School',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'The Ultimate Childcare Platform!',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    String? dueDateString;
    final dueDate = invoiceData['dueDate'] is DateTime
        ? invoiceData['dueDate'] as DateTime
        : (invoiceData['invoiceDate'] is DateTime
            ? invoiceData['invoiceDate'] as DateTime
            : null);
    if (dueDate != null) {
      dueDateString = DateFormat('MMM dd, yyyy').format(dueDate);
    } else if (invoiceData['dueDate'] is String) {
      dueDateString = invoiceData['dueDate'] as String;
    }

    DateTime? serviceStart = invoiceData['serviceDate'] is DateTime ? invoiceData['serviceDate'] as DateTime : null;
    DateTime? serviceEnd = invoiceData['serviceDateEnd'] is DateTime ? invoiceData['serviceDateEnd'] as DateTime : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        schoolHeader,
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: responsive.isTablet ? 16.0 : 12.0,
            horizontal: responsive.isTablet ? 20.0 : 12.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.billingGreyLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoice Details',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.billingGreyDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
          if (dueDateString != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    'Due Date: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.billingGreyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dueDateString,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (serviceStart != null || serviceEnd != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    'Service Period: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.billingGreyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${serviceStart != null ? DateFormat('MMM dd, yyyy').format(serviceStart) : 'N/A'} - ${serviceEnd != null ? DateFormat('MMM dd, yyyy').format(serviceEnd) : 'N/A'}',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (invoiceData['internalNote'] != null && invoiceData['internalNote'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Internal Note:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.billingGreyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoiceData['internalNote'].toString(),
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
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
                flex: 1,
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
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          ...items.map((raw) {
            if (raw is! Map<String, dynamic>) return const SizedBox.shrink();
            final description = raw['description']?.toString() ?? 'No description';
            final amount = double.tryParse(raw['amount']?.toString() ?? '0') ?? 0.0;
            final type = raw['type']?.toString() ?? '';
            final isDiscount = type == 'Discount' || type == 'Subsidy';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${isDiscount ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isDiscount ? Colors.red : AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 10),
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Amount: \$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedStudents() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.billingGreyLight),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Students (${widget.selectedStudents.length})',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.selectedStudents.asMap().entries.map((entry) {
            final student = entry.value;
            final isLast = entry.key == widget.selectedStudents.length - 1;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DocumentImageWidget(
                      fileUuid: student.fullName, // UI-only seed
                      name: student.fullName,
                      size: 40,
                      fontSize: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.billingGreyDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.tags.isNotEmpty
                                ? '${student.tags.first.id} - ${student.tags.first.name} - ${student.roomName ?? 'N/A'}'
                                : student.roomName ?? 'No details available',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.billingGreyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onStudentRemoved != null)
                      IconButton(
                        onPressed: () => widget.onStudentRemoved!(student),
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(thickness: 0.5, color: AppColors.billingGreyLight),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  void _onSave() {
    if (isProcessing) return;
    final total = _computeTotalAmount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved invoice for ${widget.selectedStudents.length} student(s). Total: \$${total.toStringAsFixed(2)}')),
    );
  }

  void _onSaveAndSend() {
    if (isProcessing) return;
    final total = _computeTotalAmount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved & sent invoice. Total: \$${total.toStringAsFixed(2)} — UI only')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final containerWidth = isLargeTablet
        ? (screenWidth * 0.95).clamp(800.0, 1400.0)
        : isTablet
            ? screenWidth * 0.95
            : screenWidth - 16.0;
    final horizontalSpacing = isLargeTablet
        ? (screenWidth * 0.025).clamp(16.0, 32.0)
        : isTablet
            ? 16.0
            : 8.0;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16.0;

    return Scaffold(
      backgroundColor: AppColors.billingCardColor,
      appBar: const CustomAppBar(hasBackButton: true),
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
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8.0 : 4.0, vertical: isTablet ? 16.0 : 8.0),
            child: Center(
              child: Container(
                width: containerWidth,
                margin: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            'Invoice Receipt',
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
                        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInvoiceDetails(responsive),
                            const SizedBox(height: 15),
                            _buildSelectedStudents(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
        decoration: BoxDecoration(
          color: AppColors.billingCardColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.billingShadowColorLight,
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 40.0 : 24.0),
            topRight: Radius.circular(isTablet ? 40.0 : 24.0),
          ),
        ),
        child: widget.isConfirmation
            ? Container(
                height: isTablet ? 56.0 : 48.0,
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  borderRadius: BorderRadius.circular(isTablet ? 16.0 : 8.0),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 20.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.billingCardColor,
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: Container(
                      height: isTablet ? 56.0 : 48.0,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius:
                            BorderRadius.circular(isTablet ? 16.0 : 8.0),
                      ),
                      child: TextButton(
                        onPressed: _onSave,
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: isTablet ? 20.0 : 16.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.billingCardColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: isTablet ? 56.0 : 48.0,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius:
                            BorderRadius.circular(isTablet ? 16.0 : 8.0),
                      ),
                      child: TextButton(
                        onPressed: _onSaveAndSend,
                        child: Text(
                          'Save & Send',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: isTablet ? 20.0 : 16.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.billingCardColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

