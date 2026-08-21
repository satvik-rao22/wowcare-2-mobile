import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../app/theme/colors.dart';

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
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 50),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: widget.verticalPadding,
                horizontal: widget.horizontalPadding,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    widget.iconAsset,
                    width: widget.iconSize,
                    height: widget.iconSize,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: widget.iconSize * 0.46),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Manrope',
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
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: Text(
                    widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                    style: const TextStyle(
                      color: AppColors.white,
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
