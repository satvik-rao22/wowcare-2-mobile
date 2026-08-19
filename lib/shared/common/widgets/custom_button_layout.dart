import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The standard action footer: an optional neutral cancel key beside the pink
/// recommended-action key.
///
/// When [isForm] is true the pair sits on its own raised panel, which is how
/// every form in the app closes off its fields.
class CustomButtonLayout extends StatelessWidget {
  const CustomButtonLayout({
    required this.confirmButtonLabel,
    required this.onPressedConfirm,
    this.confirmButtonChild,
    this.onDisabledConfirmTap,
    this.disabledConfirmTooltip,
    this.cancelButtonLabel,
    this.onPressedCancel,
    this.showCancelButton = true,
    this.isForm = true,
    this.isLoading = false,
    this.gradientCancelLabel = false,
    super.key,
  });

  final String confirmButtonLabel;
  final Widget? confirmButtonChild;
  final String? cancelButtonLabel;
  final void Function()? onPressedConfirm;
  final void Function()? onPressedCancel;
  final VoidCallback? onDisabledConfirmTap;
  final String? disabledConfirmTooltip;
  final bool showCancelButton;
  final bool isForm;

  /// When true, shows a white loader on top of the confirm button
  /// and disables all button interactions.
  final bool isLoading;

  /// When true, the cancel button's label text is painted with the primary
  /// gradient instead of the flat primary color.
  final bool gradientCancelLabel;

  @override
  Widget build(BuildContext context) {
    final row = IgnorePointer(
      ignoring: isLoading,
      child: Row(
        children: [
          if (showCancelButton)
            Expanded(
              child: CustomCancelButton(
                cancelButtonLabel: cancelButtonLabel,
                onPressedCancel: onPressedCancel,
                gradientLabel: gradientCancelLabel,
              ),
            ),
          if (showCancelButton) const SizedBox(width: 16),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isLoading ? 0.6 : 1,
                  child: Tooltip(
                    message:
                        (onPressedConfirm == null &&
                            disabledConfirmTooltip != null)
                        ? disabledConfirmTooltip!
                        : '',
                    preferBelow: false,
                    verticalOffset: 14,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (onPressedConfirm == null && !isLoading)
                          ? onDisabledConfirmTap
                          : null,
                      child: CustomConfirmButton(
                        label: confirmButtonLabel,
                        widget: confirmButtonChild,
                        onPressed: onPressedConfirm,
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isForm) return row;
    return SkeuPanel(radius: 20, padding: const EdgeInsets.all(20), child: row);
  }
}
