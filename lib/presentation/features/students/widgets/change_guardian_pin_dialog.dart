import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';
import 'package:wowcare/core/theme/skeu_press.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

/// Which way the operator chose to set the new PIN.
enum ChangeGuardianPinMode { manual, regenerate }

/// The operator's choice, returned by [ChangeGuardianPinDialog.show].
///
/// [pin] is set only for [ChangeGuardianPinMode.manual]; the regenerate flow
/// lets the server pick.
class ChangeGuardianPinResult {
  const ChangeGuardianPinResult({required this.mode, this.pin});

  final ChangeGuardianPinMode mode;
  final String? pin;
}

/// "Change PIN" confirmation dialog for a parent/guardian.
///
/// Offers the two mutually exclusive routes from the design: type a 4-digit PIN
/// and confirm, or let the system regenerate one. The dialog only COLLECTS the
/// choice — it pops a [ChangeGuardianPinResult] and the caller performs the API
/// call, so this widget stays free of data-layer concerns.
class ChangeGuardianPinDialog extends StatefulWidget {
  const ChangeGuardianPinDialog({super.key});

  /// Returns the operator's choice, or null if they cancelled/dismissed.
  static Future<ChangeGuardianPinResult?> show(BuildContext context) {
    return showDialog<ChangeGuardianPinResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ChangeGuardianPinDialog(),
    );
  }

  @override
  State<ChangeGuardianPinDialog> createState() =>
      _ChangeGuardianPinDialogState();
}

class _ChangeGuardianPinDialogState extends State<ChangeGuardianPinDialog> {
  static const int _pinLength = 4;

  final TextEditingController _pinController = TextEditingController();

  /// Set when the operator submits a PIN that isn't exactly 4 digits.
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  bool get _isPinComplete => _pinController.text.trim().length == _pinLength;

  void _submitManual() {
    final pin = _pinController.text.trim();
    if (pin.length != _pinLength) {
      setState(() => _errorText = StudentStrings.enterA4DigitPin);
      return;
    }
    Navigator.of(context).pop(
      ChangeGuardianPinResult(mode: ChangeGuardianPinMode.manual, pin: pin),
    );
  }

  void _submitRegenerate() {
    Navigator.of(context).pop(
      const ChangeGuardianPinResult(mode: ChangeGuardianPinMode.regenerate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ChangePinDialogHeader(),
                AppSpacing.gapVMd,
                const Text(
                  StudentStrings.generatingANewPinWillDeactivateTheCurrentPin,
                  style: AppTextStyles.guardianPinDialogBody,
                ),
                AppSpacing.gapVLg,
                const Text(
                  StudentStrings.enterPinManually,
                  style: AppTextStyles.guardianPinSectionLabel,
                ),
                AppSpacing.gapVXs,
                _ChangePinManualRow(
                  controller: _pinController,
                  pinLength: _pinLength,
                  isPinComplete: _isPinComplete,
                  onChanged: () => setState(() => _errorText = null),
                  onSubmit: _submitManual,
                ),
                if (_errorText != null) ...[
                  AppSpacing.gapVXs,
                  Text(
                    _errorText!,
                    style: AppTextStyles.guardianPinErrorText,
                  ),
                ],
                AppSpacing.gapVLg,
                const _ChangePinOrDivider(),
                AppSpacing.gapVLg,
                CustomButtonLayout(
                  confirmButtonLabel: StudentStrings.regeneratePin,
                  cancelButtonLabel: StudentStrings.cancel,
                  onPressedConfirm: _submitRegenerate,
                  onPressedCancel: () => Navigator.of(context).pop(),
                  isForm: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// Title row + dismiss control.
class _ChangePinDialogHeader extends StatelessWidget {
  const _ChangePinDialogHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(StudentStrings.changePin, style: AppTextStyles.title),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.studentSurfaceGrey,
            ),
            child: const Icon(
              Icons.close,
              size: AppDimensions.iconSm,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// PIN field + inline "Change PIN" confirm, per the design. The button is
/// greyed until exactly [pinLength] digits are entered.
class _ChangePinManualRow extends StatelessWidget {
  const _ChangePinManualRow({
    required this.controller,
    required this.pinLength,
    required this.isPinComplete,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final int pinLength;
  final bool isPinComplete;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          // A typed-into field is a well with no edge, at rest or on focus —
          // see AppSurfaces.fieldDecoration.
          child: SkeuFieldWell(
            radius: AppRadius.sm,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: pinLength,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(pinLength),
              ],
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSubmit(),
              style: AppTextStyles.guardianPinFieldValue,
              decoration: AppSurfaces.fieldDecoration(radius: AppRadius.sm)
                  .copyWith(
                    // The 4-digit cap is already obvious from the hint; the
                    // counter would only add vertical noise inside a compact
                    // dialog row.
                    counterText: '',
                    isDense: true,
                    hintText: StudentStrings.enter4DigitPin,
                    hintStyle: AppTextStyles.guardianPinFieldHint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                  ),
            ),
          ),
        ),
        AppSpacing.gapHXs,
        _InlineKeyButton(
          label: StudentStrings.changePin,
          onTap: isPinComplete ? onSubmit : null,
        ),
      ],
    );
  }
}

/// "Or generate by system" rule between the two routes.
class _ChangePinOrDivider extends StatelessWidget {
  const _ChangePinOrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: AppDimensions.hairline,
            color: AppColors.dividerColor,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            StudentStrings.orGenerateBySystem,
            style: AppTextStyles.guardianPinDividerLabel,
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: AppDimensions.hairline,
            color: AppColors.dividerColor,
          ),
        ),
      ],
    );
  }
}

/// Compact primary key sized to sit beside the PIN field.
class _InlineKeyButton extends StatelessWidget {
  const _InlineKeyButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Material(
        color: AppColors.transparentColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SkeuKeyBox(
            variant: KeyVariant.primary,
            radius: AppRadius.sm,
            height: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTextStyles.guardianPinInlineButtonLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
