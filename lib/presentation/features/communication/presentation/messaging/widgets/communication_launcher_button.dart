import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';

/// Gradient pill button used by [MessagingEntryScreen] to launch a
/// communication module (Staff Messaging / Admin Chat / Room Chat).
///
/// Reuses [AppColors.buildPrimaryGradient] (the app's existing gradient
/// token) and the same tap-scale feedback convention as [RoundedButton] —
/// neither existing button widget supports an icon + label gradient pill,
/// so this is the one new widget this feature requires.
///
/// Sizing is parameterised (not hardcoded) so callers can scale it per
/// breakpoint, e.g. via the app's existing [ResponsiveHelper], instead of
/// this widget baking in one fixed size.
class CommunicationLauncherButton extends StatefulWidget {
  const CommunicationLauncherButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onTap,
    this.unreadCount = 0,
    this.iconSize = 26,
    this.fontSize = 18,
    this.verticalPadding = 22,
    this.horizontalPadding = 24,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onTap;
  final int unreadCount;
  final double iconSize;
  final double fontSize;
  final double verticalPadding;
  final double horizontalPadding;

  @override
  State<CommunicationLauncherButton> createState() =>
      _CommunicationLauncherButtonState();
}

class _CommunicationLauncherButtonState
    extends State<CommunicationLauncherButton> {
  /// UI-only tap-scale feedback. A [ValueNotifier] rather than `setState` so
  /// only the [AnimatedScale] rebuilds on press — the pill subtree below is
  /// handed in as a built-once `child`.
  final ValueNotifier<bool> _isPressed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isPressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _isPressed.value = true,
      onTapUp: (_) => _isPressed.value = false,
      onTapCancel: () => _isPressed.value = false,
      onTap: widget.onTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isPressed,
        builder: (context, isPressed, child) => AnimatedScale(
          scale: isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 50),
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: widget.verticalPadding,
                horizontal: widget.horizontalPadding,
              ),
              decoration: AppSurfaces.key(
                KeyVariant.primary,
                radius: AppRadius.pill,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    widget.iconAsset,
                    width: widget.iconSize,
                    height: widget.iconSize,
                    color: AppColors.messagingOnAccent,
                  ),
                  SizedBox(width: widget.iconSize * 0.46),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.size14.copyWith(
                        color: AppColors.messagingOnAccent,
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.unreadCount > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.messagingOnAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    widget.unreadCount > 99
                        ? AppStrings.unreadCountOverflow
                        : '${widget.unreadCount}',
                    style: AppTextStyles.size14.copyWith(
                      color: AppColors.messagingOnAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
