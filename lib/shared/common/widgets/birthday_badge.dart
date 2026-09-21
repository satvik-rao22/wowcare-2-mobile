import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/upcoming_birthday.dart';

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
      message: 'Birthday: ${UpcomingBirthday.label(daysUntil)}',
      child: AppIcon(
        MediaRes.birthdayCakeIcon,
        height: size,
        width: size,
        tone: IconTone.warning,
      ),
    );
  }
}

/// Compact "Today / Tomorrow / In N days" pill with a cake icon, for rows
/// that have room to show the count next to the icon at all times.
///
/// A birthday is a heads-up, not a warning, but the sun ramp is the palette's
/// "coming up, look at this" tone and the tint/ink pair is already contrast
/// checked — see [AppPalette.statusWarningSoft] and [statusWarningStrong].
class BirthdayCountdownChip extends StatelessWidget {
  const BirthdayCountdownChip({super.key, required this.daysUntil});

  final int daysUntil;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppPalette.statusWarningSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            MediaRes.birthdayCakeIcon,
            height: 12,
            width: 12,
            tone: IconTone.warning,
          ),
          const SizedBox(width: 3),
          Text(
            UpcomingBirthday.label(daysUntil),
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppPalette.statusWarningStrong,
            ),
          ),
        ],
      ),
    );
  }
}
