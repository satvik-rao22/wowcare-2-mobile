import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';

/// Dark scrim + percentage pill shown over an avatar while a profile photo or
/// classroom logo is uploading.
///
/// Shared so every upload spot (staff / student / guardian profile photos and
/// the classroom logo) shows the identical progress UI. Drop it as a
/// `Positioned.fill` child inside the avatar's [Stack] while an upload runs.
class PhotoUploadProgressOverlay extends StatelessWidget {
  const PhotoUploadProgressOverlay({
    super.key,
    required this.percent,
    this.borderRadius = const BorderRadius.all(Radius.circular(45)),
  });

  /// Upload progress, 0–100. At 100 the label switches to "Finalizing".
  final double percent;

  /// Corner radius of the dark scrim — match the avatar (its size / 2 for a
  /// circle).
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 100.0);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xB3241631),
          borderRadius: borderRadius,
        ),
        child: Center(
          // Scale the pill down to fit smaller avatars (e.g. the 60px classroom
          // logo) instead of overflowing — it was sized for the 90px profile
          // avatar.
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${clamped.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (clamped / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      MediaRes.uploadIcon,
                      height: 10,
                      width: 10,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.92),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      clamped >= 100 ? 'Finalizing' : 'Uploading',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
              ),
            ),
        ),
      ),
    );
  }
}
