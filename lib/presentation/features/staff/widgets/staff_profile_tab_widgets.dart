import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// A work/break time chip shown in [StaffProfileTab]'s schedule section.
class ScheduleChip extends StatelessWidget {
  const ScheduleChip({
    super.key,
    required this.label,
    required this.labelColor,
    required this.color,
    required this.width,
    this.isTimeChip = false,
  });

  final String label;
  final Color labelColor;
  final Color color;
  final double width;
  final bool isTimeChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: isTimeChip
            ? Border.all(color: AppColors.staffBadgeActiveBg, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: isTimeChip ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
      ),
    );
  }
}

/// A label/value field row used throughout [StaffProfileTab].
class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.label,
    this.value,
    this.trailing,
  });
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        if (trailing == null)
          Text(
            value ?? '-',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w400,
            ),
          )
        else
          trailing!,
      ],
    );
  }
}

/// A small pill/badge chip used throughout [StaffProfileTab].
class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.label,
    required this.labelColor,
    required this.color,
    this.icon,
  });
  final String label;
  final Color labelColor;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Caps a single chip's width so one very long classroom name wraps
      // onto extra lines within the chip instead of rendering at its full
      // intrinsic width and overflowing past the screen edge — Wrap only
      // moves children that don't fit onto a new line, it doesn't shrink
      // a child that's wider than the available space by itself.
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
