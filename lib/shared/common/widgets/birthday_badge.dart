import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/upcoming_birthday.dart';

/// Small cake-icon badge meant to sit on a student's avatar corner (like the
/// napping badge) when their birthday is today or within
/// [UpcomingBirthday.maxDays] days. The day count is surfaced via tooltip.
class BirthdayAvatarBadge extends StatelessWidget {
  const BirthdayAvatarBadge({
    super.key,
    required this.daysUntil,
    this.size = 16,
  });

  final int daysUntil;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Birthday: ${UpcomingBirthday.label(daysUntil)}",
      child: SvgPicture.asset(
        MediaRes.birthdayCakeIcon,
        height: size,
        width: size,
      ),
    );
  }
}

/// Compact "Today / Tomorrow / In N days" pill with a cake icon, for rows
/// that have room to show the count next to the icon at all times.
class BirthdayCountdownChip extends StatelessWidget {
  const BirthdayCountdownChip({super.key, required this.daysUntil});

  final int daysUntil;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x33FFA726),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(MediaRes.birthdayCakeIcon, height: 12, width: 12),
          const SizedBox(width: 3),
          Text(
            UpcomingBirthday.label(daysUntil),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A5A00),
            ),
          ),
        ],
      ),
    );
  }
}
