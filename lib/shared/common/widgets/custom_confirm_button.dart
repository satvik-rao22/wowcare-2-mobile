import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The recommended action in a confirm/cancel pair.
///
/// A rimmed pink key in the skeuomorphic language: pink is THE recommended
/// action across the design system, so every "Save" / "Submit" / "Yes" in the
/// app now reads as the same object. The internal loading state and the
/// `FutureOr` press contract are unchanged, so all 90-odd call sites keep
/// working exactly as before.
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

    return SkeuButton(
      label: widget.label,
      // A caller-supplied child (an icon + label row, say) replaces the label
      // but keeps the same rimmed key.
      child: widget.widget,
      height: 48,
      radius: SkeuRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      enabled: isEnabled,
      isLoading: _isLoading,
      onPressed: _handlePress,
    );
  }
}
