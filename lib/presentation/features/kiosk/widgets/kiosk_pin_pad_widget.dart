import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_haptics.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/kiosk/view_model/kiosk_dashboard_cubit.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Isolated PIN pad widget with local state management.
/// Prevents PIN input changes from triggering QR widget rebuilds.
class KioskPinPadWidget extends StatefulWidget {
  const KioskPinPadWidget({
    required this.onPinSubmit,
    this.maxPinLength = 4,
    this.isLogout = false,
    this.title = 'Enter your Sign-In/out PIN',
    this.onCancel,
    super.key,
  });

  final Future<void> Function(String pin, {bool isLogout}) onPinSubmit;
  final int maxPinLength;

  /// When true, this instance skips the internal [KioskDashboardCubit]
  /// listener (not ambient in every screen that hosts this widget, e.g. the
  /// logout page) and instead resets once [onPinSubmit] completes — see
  /// [build] and [_validate].
  final bool isLogout;

  /// Shown above the PIN dots. Pass null to omit it — for a caller (like the
  /// logout page) that already shows its own instructional text above this
  /// widget, so the two don't duplicate.
  final String? title;

  /// Overrides the Cancel button's action. Defaults to clearing the PIN and
  /// showing a "cancelled" snackbar (the dashboard's original behaviour) when
  /// null.
  final VoidCallback? onCancel;

  @override
  State<KioskPinPadWidget> createState() => _KioskPinPadWidgetState();
}

class _KioskPinPadWidgetState extends State<KioskPinPadWidget> {
  late String _pin;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pin = '';
  }

  void _addDigit(String digit) {
    if (_pin.length < widget.maxPinLength) {
      AppHaptics.tap();
      setState(() {
        _pin += digit;
      });

      // TODO: Temporarily disabled auto-trigger for Next button.
      // User must explicitly tap the Next button.
      // Auto-submit when max PIN length is reached
      // if (_pin.length == widget.maxPinLength) {
      //   Future.delayed(const Duration(milliseconds: 300), () {
      //     if (mounted && !_isSubmitting) {
      //       _submitPinInternal();
      //     }
      //   });
      // }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      AppHaptics.tap();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _reset() {
    setState(() {
      _pin = '';
      _isSubmitting = false;
    });
  }

  Future<void> _validate(BuildContext context) async {
    if (_pin.length != widget.maxPinLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a ${widget.maxPinLength}-digit PIN',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Call parent callback with isLogout flag
    await widget.onPinSubmit(_pin, isLogout: widget.isLogout);

    // The dashboard path resets via the KioskDashboardCubit listener below
    // (its result arrives as a state transition, not necessarily when this
    // future completes). The logout path has no such listener wired here —
    // its cubit isn't ambient in every screen that hosts this widget — so it
    // resets directly off this future instead, matching what the logout
    // page's own submit handler did before this widget replaced it.
    if (widget.isLogout && mounted) {
      _reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.isLogout) return content;
    return BlocListener<KioskDashboardCubit, KioskDashboardState>(
      listener: (context, state) {
        if (state is KioskDashboardPinSuccess) {
          // Clear PIN and reset submitting flag on successful verification
          _reset();
        } else if (state is KioskDashboardQrLoaded) {
          // Reset PIN and re-enable button when PIN verification fails
          // This clears the entered digits and allows user to retry with a new PIN
          if (_isSubmitting) {
            _reset();
          }
        }
      },
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
            ],
            _buildPinDots(),
            const SizedBox(height: 30),
            _buildKeypad(),
            const SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 10,
      children: List.generate(
        widget.maxPinLength,
        (index) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length
                ? MaterialHues.blue400
                : MaterialHues.grey300,
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 90),
              _buildKeypadButton('0'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 70,
                height: 50,
                child: ElevatedButton(
                  onPressed: _removeDigit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaterialHues.grey200,
                    foregroundColor: AppColors.blackColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.backspace_outlined, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String number) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 70,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _addDigit(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: MaterialHues.grey200,
          foregroundColor: AppColors.blackColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SkeuKeyBox(
            variant: KeyVariant.primary,
            radius: 8,
            height: 48,
            padding: const EdgeInsets.all(1),
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : widget.onCancel ??
                        () {
                          _reset();
                          CoreUtils.showTopSnackBar(
                            context: context,
                            message: 'PIN entry cancelled',
                            isWarning: true,
                          );
                        },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 16 * (-3 / 100),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SkeuKeyBox(
            variant: KeyVariant.primary,
            radius: 8,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () {
                      _validate(context);
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.whiteColor,
                        ),
                      ),
                    )
                  : const Text(
                      'Next',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 16 * (-3 / 100),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
