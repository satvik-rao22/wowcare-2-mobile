import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The quiet half of a confirm/cancel pair.
///
/// A neutral rimmed key in the skeuomorphic language — the same object as the
/// confirm key, in the material that says "not the recommended action". It sits
/// beside the pink one without competing with it.
class CustomCancelButton extends StatelessWidget {
  const CustomCancelButton({
    this.cancelButtonLabel,
    this.onPressedCancel,
    this.gradientLabel = false,
    super.key,
  });

  final String? cancelButtonLabel;
  final void Function()? onPressedCancel;

  /// Retained for call-site compatibility. The skeuomorphic language has one
  /// neutral key face, so a gradient label would put a second treatment on the
  /// same object; the flag no longer changes the rendering.
  final bool gradientLabel;

  @override
  Widget build(BuildContext context) => SkeuButton(
    label: cancelButtonLabel ?? 'Cancel',
    variant: SkeuButtonVariant.neutral,
    height: 48,
    radius: SkeuRadius.md,
    onPressed: onPressedCancel ?? () => Navigator.pop(context),
  );
}
