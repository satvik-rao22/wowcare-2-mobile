import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

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
      // A key sinks; it does not shrink. The 0.80 scale was a 20% collapse,
      // which is a different physical idea from pressing a button down.
      child: Transform.translate(
        offset: Offset(0, isPressed ? AppMotion.pressTravel : 0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            backgroundColor: widget.buttonColor,
            elevation: 0,
            shadowColor: AppColors.transparentColor,
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
                    color: AppPalette.onBrand,
                    backgroundColor: AppPalette.brand,
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
