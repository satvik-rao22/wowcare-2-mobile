import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';

/// Isolated PIN pad widget with local state management.
/// Prevents PIN input changes from triggering QR widget rebuilds.
class KioskPinPadWidget extends StatefulWidget {
  const KioskPinPadWidget({
    required this.onPinSubmit,
    this.maxPinLength = 4,
    super.key,
  });

  final Function(String pin) onPinSubmit;
  final int maxPinLength;

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
      setState(() {
        _pin += digit;
      });

      // Auto-submit when max PIN length is reached
      if (_pin.length == widget.maxPinLength) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isSubmitting) {
            _submitPinInternal();
          }
        });
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
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

  void _submitPinInternal() {
    if (_pin.length == widget.maxPinLength) {
      setState(() {
        _isSubmitting = true;
      });
      widget.onPinSubmit(_pin);
    }
  }

  void _validate(BuildContext context) {
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

    // Call parent callback
    widget.onPinSubmit(_pin);
  }

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your Sign-In/out PIN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              _buildPinDots(),
              const SizedBox(height: 30),
              _buildKeypad(),
              const SizedBox(height: 30),
              _buildActionButtons(context),
            ],
          ),
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
            color: index < _pin.length ? Colors.blue[400] : Colors.grey[300],
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
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
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
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
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
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.buildSecondaryGradient(),
            ),
            padding: const EdgeInsets.all(1),
            child: TextButton(
              onPressed: _isSubmitting ? null : () {
                _reset();
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'PIN entry cancelled',
                  isWarning: true,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) =>
                    AppColors.buildSecondaryGradient().createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 16 * (-3 / 100),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.buildSecondaryGradient(),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSubmitting ? null : () {
                _validate(context);
              },
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
