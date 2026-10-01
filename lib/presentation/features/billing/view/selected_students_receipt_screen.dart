import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/model/invoice_draft.dart';
import 'package:wowcare/presentation/features/billing/model/student_models.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';
import 'package:wowcare/core/utils/core_utils.dart';

class SelectedStudentsReceiptScreen extends StatefulWidget {
  const SelectedStudentsReceiptScreen({
    super.key,
    required this.selectedStudents,
    required this.invoiceData,
    this.onStudentRemoved,
    this.isConfirmation = false,
    this.onSubmit,
  });

  static const String routeName = '/billing/selected-students-receipt';

  final List<Student> selectedStudents;
  final InvoiceDraft invoiceData;
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
  State<SelectedStudentsReceiptScreen> createState() =>
      _SelectedStudentsReceiptScreenState();
}

class _SelectedStudentsReceiptScreenState
    extends State<SelectedStudentsReceiptScreen> {
  bool isProcessing = false;

  /// Local, mutable copy so a student can be removed from the invoice on this
  /// preview step; the trimmed list is what gets submitted.
  late final List<Student> _students = List<Student>.from(
    widget.selectedStudents,
  );

  // Add-Staff text palette (Manrope, #573353).
  static const Color _text = AppColors.billingTextColor;
  static TextStyle _ts(double size, FontWeight weight, {Color? color}) =>
      TextStyle(
        fontFamily: AppFonts.body,
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
    final invoiceItems = widget.invoiceData.invoiceItems;
    for (final item in invoiceItems) {
      final amount = double.tryParse(item.amount) ?? 0.0;
      final type = item.type;
      if (type == 'Discount' || type == 'Subsidy') {
        totalAmount -= amount;
      } else {
        totalAmount += amount;
      }
    }
    return totalAmount;
  }

  Widget _buildInvoiceDetails(ResponsiveHelper responsive) {
    final invoiceData = widget.invoiceData;
    final items = invoiceData.invoiceItems;
    final totalAmount = _computeTotalAmount();

    // Real school header (name + tagline + address).
    const schoolHeader = BillingSchoolHeader();

    String? dueDateString;
    final dueDate = invoiceData.dueDate ?? invoiceData.invoiceDate;
    if (dueDate != null) {
      dueDateString = DateFormat('MMM dd, yyyy').format(dueDate);
    }

    DateTime? serviceStart = invoiceData.serviceDate;
    DateTime? serviceEnd = invoiceData.serviceDateEnd;

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
                BillingStrings.invoiceDetails,
                style: _ts(16, FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (dueDateString != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        BillingStrings.dueDate,
                        style: _ts(
                          14,
                          FontWeight.w400,
                          color: _text.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(dueDateString, style: _ts(14, FontWeight.w600)),
                    ],
                  ),
                ),
              if (serviceStart != null || serviceEnd != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        BillingStrings.servicePeriod,
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
              if (invoiceData.internalNote != null &&
                  invoiceData.internalNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BillingStrings.internalNoteLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.billingGreyMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoiceData.internalNote!,
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
                      BillingStrings.description,
                      style: _ts(
                        15,
                        FontWeight.w400,
                        color: _text.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      BillingStrings.amount,
                      style: _ts(
                        15,
                        FontWeight.w400,
                        color: _text.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
              ...items.map((raw) {
                final description = raw.description;
                final amount = double.tryParse(raw.amount) ?? 0.0;
                final type = raw.type;
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
                          style: _ts(
                            14,
                            FontWeight.w600,
                            color: isDiscount ? AppColors.errorColor : _text,
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
            style: _ts(16, FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (_students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                BillingStrings.noStudentsSelectedGoBack,
                style: _ts(
                  14,
                  FontWeight.w400,
                  color: _text.withValues(alpha: 0.6),
                ),
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
                      fileUuid: '',
                      studentCode: student.code,
                      mediaAssetCode: (student.photoAssetCode ?? '').trim().isNotEmpty
                          ? student.photoAssetCode!.trim()
                          : null,
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
                            style: _ts(16, FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.tags.isNotEmpty
                                ? '${student.tags.first.id} - ${student.tags.first.name} - ${student.roomName ?? 'N/A'}'
                                : student.roomName ??
                                      BillingStrings.noDetailsAvailable,
                            style: _ts(
                              14,
                              FontWeight.w400,
                              color: _text.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Remove this student from the invoice (disabled while saving).
                    IconButton(
                      onPressed: isProcessing
                          ? null
                          : () => _removeStudent(student),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.errorColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(
                      thickness: 0.5,
                      color: AppColors.billingGreyLight,
                    ),
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
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text(BillingStrings.addAtLeastOneStudentToInvoice),
        ),
      );
      return;
    }
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      // No submit wired (e.g. opened purely for preview) — just close.
      final total = _computeTotalAmount();
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(
            'Invoice total: \$${total.toStringAsFixed(2)} — preview only',
          ),
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
      title: widget.isConfirmation
          ? BillingStrings.invoiceReceipt
          : BillingStrings.invoicePreview,
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
    Widget gradientButton(
      String label,
      VoidCallback? onPressed, {
      bool busy = false,
    }) {
      return Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: SkeuKeyBox(
          variant: KeyVariant.primary,
          radius: 12,
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.billingCardOnColorText,
                      ),
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
            ? gradientButton(
                BillingStrings.done,
                () => Navigator.of(context).pop(),
              )
            : Row(
                children: [
                  Expanded(
                    child: gradientButton(
                      // Invoice Preview wording: this saves the invoice as a
                      // draft, as opposed to "Save and Send" beside it.
                      BillingStrings.saveAsDraft,
                      (isProcessing || _students.isEmpty) ? null : _onSave,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: gradientButton(
                      BillingStrings.saveAndSend,
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
