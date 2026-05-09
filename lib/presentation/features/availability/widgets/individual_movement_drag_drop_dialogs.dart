import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/classrooom/forms/date_picker_normal.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';

class MovementDragDropDecision {
  const MovementDragDropDecision({
    required this.confirmed,
    this.comment = '',
    this.selectedDate,
  });

  final bool confirmed;
  final String comment;
  final DateTime? selectedDate;
}

Future<MovementDragDropDecision?> showMovementConfirmDropDialog(
  BuildContext context, {
  required String movementTitle,
}) {
  return showDialog<MovementDragDropDecision>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return _MovementDragDropDialogBody(
        title: 'Confirm Movement',
        message: 'Are you sure you want to confirm this movement?\n$movementTitle',
        confirmLabel: 'Confirm',
      );
    },
  );
}

Future<MovementDragDropDecision?> showMovementRejectDropDialog(
  BuildContext context, {
  required String movementTitle,
}) {
  return showDialog<MovementDragDropDecision>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return _MovementDragDropDialogBody(
        title: 'Reject Movement',
        message: 'Provide an optional comment for rejection.\n$movementTitle',
        confirmLabel: 'Reject',
        showComment: true,
      );
    },
  );
}

Future<MovementDragDropDecision?> showMovementDateDropDialog(
  BuildContext context, {
  required String title,
  required String message,
  required bool mustBeFuture,
}) {
  return showDialog<MovementDragDropDecision>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return _MovementDragDropDialogBody(
        title: title,
        message: message,
        confirmLabel: 'Apply',
        requireDate: true,
        mustBeFuture: mustBeFuture,
      );
    },
  );
}

class _MovementDragDropDialogBody extends StatefulWidget {
  const _MovementDragDropDialogBody({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.showComment = false,
    this.requireDate = false,
    this.mustBeFuture = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool showComment;
  final bool requireDate;
  final bool mustBeFuture;

  @override
  State<_MovementDragDropDialogBody> createState() =>
      _MovementDragDropDialogBodyState();
}

class _MovementDragDropDialogBodyState extends State<_MovementDragDropDialogBody> {
  final TextEditingController _commentController = TextEditingController();
  DateTime? _selectedDate;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickNormalDate(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _error = null;
    });
  }

  void _submit() {
    if (widget.requireDate) {
      if (_selectedDate == null) {
        setState(() => _error = 'Please select a date.');
        return;
      }
      final today = DateTime.now();
      final dateOnlyToday = DateTime(today.year, today.month, today.day);
      if (widget.mustBeFuture && !_selectedDate!.isAfter(dateOnlyToday)) {
        setState(() => _error = 'Date must be in the future.');
        return;
      }
      if (!widget.mustBeFuture && !_selectedDate!.isBefore(dateOnlyToday)) {
        setState(() => _error = 'Date must be in the past.');
        return;
      }
    }

    Navigator.of(context).pop(
      MovementDragDropDecision(
        confirmed: true,
        comment: _commentController.text.trim(),
        selectedDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headerBg = Color.fromRGBO(243, 238, 250, 1);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: headerBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => Navigator.of(context).pop(
                        const MovementDragDropDecision(confirmed: false),
                      ),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.primaryColor.withValues(alpha: 0.85),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  widget.message,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF424242),
                    height: 1.35,
                  ),
                ),
              ),
              if (widget.requireDate)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDate == null
                                ? 'Select date'
                                : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                            style: AppTextStyles.body.copyWith(
                              color: _selectedDate == null
                                  ? Colors.grey[600]
                                  : AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.showComment)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Add a Comment (optional)',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _error!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.errorColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomCancelButton(
                        cancelButtonLabel: 'Back',
                        onPressedCancel: () => Navigator.of(context).pop(
                          const MovementDragDropDecision(confirmed: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomConfirmButton(
                        label: widget.confirmLabel,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
