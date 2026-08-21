import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

class RoundedButton extends StatefulWidget {
  final String lable;
  final Color lableColor;
  final Color buttonColor;
  final VoidCallback onPressed;
  final bool isLoading;

  const RoundedButton({
    super.key,
    required this.lable,
    required this.lableColor,
    required this.buttonColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<RoundedButton> createState() => _RoundedButtonState();
}

class _RoundedButtonState extends State<RoundedButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 50),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            backgroundColor: widget.buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: widget.isLoading
              ? const SizedBox(
                  height: 60,
                  width: 60,
                  child: RefreshProgressIndicator(
                    color: AppColors.white,
                    backgroundColor: Color(0xFFFE3541),
                    strokeWidth: 4,
                    indicatorPadding: EdgeInsets.all(14),
                  ),
                )
              : Text(
                  widget.lable,
                  style: TextStyle(color: widget.lableColor, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
