import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';

/// Outcome of [showUnexpectedSignInAttentionDialog].
class UnexpectedSignInAttentionResult {
  const UnexpectedSignInAttentionResult({
    required this.confirmed,
    this.comment = '',
  });

  final bool confirmed;
  final String comment;
}

/// Joins display names for the unexpected sign-in banner; truncates after [maxShown].
String formatUnexpectedSignInNames(List<String> names, {int maxShown = 3}) {
  final trimmed = names
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (trimmed.isEmpty) return '';
  if (trimmed.length <= maxShown) {
    return trimmed.join(', ');
  }
  return '${trimmed.take(maxShown).join(', ')}...';
}

/// Floating modal: [UnexpectedSignInAttentionResult.confirmed] false / null = Back.
Future<UnexpectedSignInAttentionResult?> showUnexpectedSignInAttentionDialog(
  BuildContext context, {
  required List<String> unexpectedFullNames,
  required bool forStaff,
}) {
  return showDialog<UnexpectedSignInAttentionResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return _UnexpectedSignInAttentionDialogBody(
        unexpectedFullNames: unexpectedFullNames,
        forStaff: forStaff,
      );
    },
  );
}

class _UnexpectedSignInAttentionDialogBody extends StatefulWidget {
  const _UnexpectedSignInAttentionDialogBody({
    required this.unexpectedFullNames,
    required this.forStaff,
  });

  final List<String> unexpectedFullNames;
  final bool forStaff;

  @override
  State<_UnexpectedSignInAttentionDialogBody> createState() =>
      _UnexpectedSignInAttentionDialogBodyState();
}

class _UnexpectedSignInAttentionDialogBodyState
    extends State<_UnexpectedSignInAttentionDialogBody> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final namesText = formatUnexpectedSignInNames(widget.unexpectedFullNames);
    final target = widget.forStaff ? 'staff' : 'students';
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: headerBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Attention!',
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
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => Navigator.of(context).pop(
                        const UnexpectedSignInAttentionResult(confirmed: false),
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
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF424242),
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: namesText,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.themeColor,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' are not expected today. Do you still want to sign-in $target?',
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF424242),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Add a Comment',
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomCancelButton(
                        cancelButtonLabel: 'Back',
                        onPressedCancel: () => Navigator.of(context).pop(
                          const UnexpectedSignInAttentionResult(
                            confirmed: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomConfirmButton(
                        label: 'Confirm',
                        onPressed: () => Navigator.of(context).pop(
                          UnexpectedSignInAttentionResult(
                            confirmed: true,
                            comment: _commentController.text.trim(),
                          ),
                        ),
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
