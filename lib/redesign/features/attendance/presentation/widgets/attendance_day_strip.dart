import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// The day on screen, with a step either side of it (4a, 4b).
///
/// The middle opens the day sheet; the arrows walk a day at a time and the
/// forward one is dead on today, because tomorrow has no attendance.
class AttendanceDayStrip extends StatelessWidget {
  const AttendanceDayStrip({
    required this.label,
    required this.onPick,
    required this.onBack,
    this.onForward,
    this.isActive = false,
    super.key,
  });

  final String label;
  final VoidCallback onPick;
  final VoidCallback onBack;

  /// Null on today, where there is nowhere forward to go.
  final VoidCallback? onForward;

  /// The sheet is open over it.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: isActive
          ? AppSurfaces.card(c).copyWith(
              decoration: AppSurfaces.card(
                c,
              ).decoration.copyWith(border: Border.all(color: c.pink)),
            )
          : AppSurfaces.card(c),
      padding: AttendanceSizes.dayStripPad,
      child: Row(
        spacing: AttendanceSizes.dayStripGap,
        children: <Widget>[
          _Arrow(icon: AppIcons.chevronLeft, onTap: onBack),
          Expanded(
            child: Pressable.surface(
              onTap: onPick,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AttendanceSizes.dayGlyphGap,
                children: <Widget>[
                  Icon(
                    AppIcons.calendar,
                    size: AttendanceSizes.dayGlyph,
                    color: isActive ? c.pink : c.ink,
                  ),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AttendanceTextStyles.stripValue.copyWith(
                        color: isActive ? c.pink : c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Arrow(icon: AppIcons.chevronRight, onTap: onForward),
        ],
      ),
    );
  }
}

/// One step of the day. A dead arrow keeps its place and does not move.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final face = SurfaceBox(
      surface: AppSurfaces.glyphTile(c, fill: c.sub, radius: AppRadii.chip),
      width: AttendanceSizes.dayArrow,
      height: AttendanceSizes.dayArrow,
      alignment: Alignment.center,
      child: Icon(icon, size: AttendanceSizes.dayArrowGlyph, color: c.ink),
    );

    if (onTap == null) {
      return Opacity(opacity: AttendanceSizes.disabledOpacity, child: face);
    }
    return Pressable.surface(onTap: onTap, child: face);
  }
}
