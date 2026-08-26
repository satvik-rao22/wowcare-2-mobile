import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/media_res.dart';

/// Funnel icon that opens the activity filter sheet, with a red count badge for
/// the number of filter groups currently applied.
///
/// Shared by the Daily and Custom tabs (portrait + landscape, staff/admin and
/// guardian personas) so every entry point into [ActivityFilterScreen] looks
/// and behaves the same.
class ActivityFilterIconButton extends StatelessWidget {
  const ActivityFilterIconButton({
    super.key,
    required this.onTap,
    required this.badgeCount,
  });

  final VoidCallback onTap;

  /// Number of applied filter groups; 0 hides the badge.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(MediaRes.filterIcon, height: 20),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(179, 38, 30, 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
