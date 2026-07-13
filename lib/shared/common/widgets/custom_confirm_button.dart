import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wowcare/app/theme/colors.dart';

class CustomConfirmButton extends StatefulWidget {
  const CustomConfirmButton({
    required this.label,
    required this.onPressed,
    this.widget,
    super.key,
  });

  final String label;
  final Widget? widget;
  final FutureOr<void> Function()? onPressed;

  @override
  State<CustomConfirmButton> createState() => _CustomConfirmButtonState();
}

class _CustomConfirmButtonState extends State<CustomConfirmButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (widget.onPressed == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isEnabled ? AppColors.buildPrimaryGradient() : null,
        color: isEnabled ? null : Colors.grey[300],
      ),
      child: TextButton(
        onPressed: (isEnabled && !_isLoading) ? _handlePress : null,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isEnabled ? Colors.white : Colors.grey[600],
          disabledForegroundColor: Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : widget.widget ??
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : Colors.grey[600],
                  ),
                ),
      ),
    );
  }
}