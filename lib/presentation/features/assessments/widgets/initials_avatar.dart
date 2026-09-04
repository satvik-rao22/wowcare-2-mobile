import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// Circular avatar showing up to two initials, with a deterministic colour from
/// the app's profile palette. Used for student/classroom cards (FR-SA-04
/// initials fallback) when no avatar image is available.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.seed,
    required this.initials,
    this.radius = 22,
    this.imageUrl,
    this.icon,
    this.gradient,
  });

  /// Stable string (e.g. code) used to pick a palette colour.
  final String seed;
  final String initials;
  final double radius;
  final String? imageUrl;

  /// Optional icon instead of initials (used for classroom/school avatars).
  final IconData? icon;

  /// Optional gradient background (classroom/school cards).
  final Gradient? gradient;

  Color get _color {
    if (seed.isEmpty) return AppColors.profileAvatarColors.first;
    final index = seed.codeUnits.fold<int>(0, (sum, c) => sum + c) %
        AppColors.profileAvatarColors.length;
    return AppColors.profileAvatarColors[index];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        color: gradient == null ? _color.withValues(alpha: 0.85) : null,
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: radius)
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.7,
              ),
            ),
    );
  }
}
