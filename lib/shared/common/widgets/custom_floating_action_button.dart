import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';

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
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(borderRadius ?? 10),
        gradient: AppColors.buildPrimaryGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: FloatingActionButton(
        heroTag: null,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: svgIcon == null
            ? Icon(
                icon,
                size: 28,
              )
            : SvgPicture.asset(
                svgIcon!,
                height: 28,
              ),
      ),
    );
  }
}
