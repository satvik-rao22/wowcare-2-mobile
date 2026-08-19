import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class SelectedStudentsReceiptScreen extends StatefulWidget {
  const SelectedStudentsReceiptScreen({
    super.key,
    required this.selectedStudents,
    required this.invoiceData,
    this.onStudentRemoved,
    this.isConfirmation = false,
    this.onSubmit,
  });

  final List<Student> selectedStudents;
  final Map<String, dynamic> invoiceData;
  final void Function(Student student)? onStudentRemoved;

  /// When true the invoice has already been created — the screen is a read-only
  /// confirmation, so the bottom bar shows a single "Done" button.
  final bool isConfirmation;

  /// Preview step (Step 3/3): performs the actual save. Called with `'draft'`
  /// (Save) or `'send'` (Save & Send) plus the current (possibly trimmed)
  /// student list, and returns true on success so this screen can pop back up
  /// the create-invoice flow.
  final Future<bool> Function(String mode, List<Student> students)? onSubmit;

  @override
  State<SelectedStudentsReceiptScreen> createState() => _SelectedStudentsReceiptScreenState();
}

class _SelectedStudentsReceiptScreenState extends State<SelectedStudentsReceiptScreen> {
  bool isProcessing = false;

  /// Local, mutable copy so a student can be removed from the invoice on this
  /// preview step; the trimmed list is what gets submitted.
  late final List<Student> _students =
      List<Student>.from(widget.selectedStudents);

  // Add-Staff text palette (Manrope, #573353).
  static const Color _text = Color(0xFF0A1C5D);
  static TextStyle _ts(double size, FontWeight weight, {Color? color}) =>
      TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        fontWeight: weight,
        color: color ?? _text,
      );

  void _removeStudent(Student student) {
    setState(() => _students.remove(student));
    widget.onStudentRemoved?.call(student);
  }

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

    // Real school header (name + tagline + address).
    const schoolHeader = BillingSchoolHeader();

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
                style: _ts(16, FontWeight.w700),
              ),
              const SizedBox(height: 12),
          if (dueDateString != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    'Due Date: ',
                    style: _ts(14, FontWeight.w400,
                        color: _text.withValues(alpha: 0.6)),
                  ),
                  Text(
                    dueDateString,
                    style: _ts(14, FontWeight.w600),
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
                  style: _ts(15, FontWeight.w400,
                      color: _text.withValues(alpha: 0.6)),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Amount',
                  style: _ts(15, FontWeight.w400,
                      color: _text.withValues(alpha: 0.6)),
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
                      style: _ts(14, FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${isDiscount ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
                      style: _ts(14, FontWeight.w600,
                          color: isDiscount ? Colors.red : _text),
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
                style: _ts(16, FontWeight.w700),
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
            'Selected Students (${_students.length})',
            style: _ts(16, FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (_students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No students selected. Go back to add a student.',
                style: _ts(14, FontWeight.w400,
                    color: _text.withValues(alpha: 0.6)),
              ),
            ),
          ..._students.asMap().entries.map((entry) {
            final student = entry.value;
            final isLast = entry.key == _students.length - 1;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DocumentImageWidget(
                      fileUuid: student.fullName, // UI-only seed
                      name: student.fullName,
                      size: 50,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: _ts(16, FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.tags.isNotEmpty
                                ? '${student.tags.first.id} - ${student.tags.first.name} - ${student.roomName ?? 'N/A'}'
                                : student.roomName ?? 'No details available',
                            style: _ts(14, FontWeight.w400,
                                color: _text.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    // Remove this student from the invoice (disabled while saving).
                    IconButton(
                      onPressed:
                          isProcessing ? null : () => _removeStudent(student),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
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

  void _onSave() => _submit('draft');

  void _onSaveAndSend() => _submit('send');

  Future<void> _submit(String mode) async {
    if (isProcessing) return;
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one student to the invoice.')),
      );
      return;
    }
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      // No submit wired (e.g. opened purely for preview) — just close.
      final total = _computeTotalAmount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Invoice total: \$${total.toStringAsFixed(2)} — preview only'),
        ),
      );
      return;
    }
    setState(() => isProcessing = true);
    final ok = await onSubmit(mode, _students);
    if (!mounted) return;
    setState(() => isProcessing = false);
    // On success the parent shows the snackbar; bubble the result up so the
    // whole create-invoice flow closes back to the billing list.
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: widget.isConfirmation ? 'Invoice Receipt' : 'Invoice Preview',
      bottomBar: _buildBottomBar(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvoiceDetails(responsive),
            const SizedBox(height: 15),
            _buildSelectedStudents(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    Widget gradientButton(String label, VoidCallback? onPressed,
        {bool busy = false}) {
      return Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.buildPrimaryGradient(),
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.billingCardColor,
                    ),
                  ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: widget.isConfirmation
            ? gradientButton('Done', () => Navigator.of(context).pop())
            : Row(
                children: [
                  Expanded(
                    child: gradientButton(
                      'Save',
                      (isProcessing || _students.isEmpty) ? null : _onSave,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: gradientButton(
                      'Save and Send',
                      (isProcessing || _students.isEmpty)
                          ? null
                          : _onSaveAndSend,
                      busy: isProcessing,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

