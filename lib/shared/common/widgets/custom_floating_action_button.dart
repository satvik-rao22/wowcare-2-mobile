import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    required this.onPressed,
    this.icon = Icons.add,
    this.svgIcon,
    this.borderRadius,
    super.key,
  });

  final IconData icon;
  final String? svgIcon;
  final double? borderRadius;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: AppSurfaces.fab(
        enabled: onPressed != null,
      ).copyWith(borderRadius: BorderRadius.circular(borderRadius ?? 10)),
      child: FloatingActionButton(
        heroTag: null,
        onPressed: onPressed,
        backgroundColor: AppColors.transparentColor,
        elevation: 0,
        // No permission, no handler: the key stays in place, recessed and
        // plainly dead, rather than disappearing off the screen.
        child: svgIcon == null
            ? Icon(
                icon,
                size: 28,
                color: onPressed == null
                    ? AppPalette.textMuted
                    : AppPalette.onBrand,
              )
            : SvgPicture.asset(
                svgIcon!,
                height: 28,
                colorFilter: ColorFilter.mode(
                  onPressed == null ? AppPalette.textMuted : AppPalette.onBrand,
                  BlendMode.srcIn,
                ),
              ),
      ),
    );
  }
}
