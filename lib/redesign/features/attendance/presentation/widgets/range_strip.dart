import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// The range the list is over, with the two keys that change it (4f).
class RangeStrip extends StatelessWidget {
  const RangeStrip({
    required this.label,
    required this.onChange,
    required this.onClearAll,
    super.key,
  });

  final String label;
  final VoidCallback onChange;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: AttendanceSizes.rangeStripPad,
      child: Row(
        spacing: AttendanceSizes.rangeStripGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.glyphTile(
              c,
              fill: c.sub,
              radius: AppRadii.chip,
            ),
            width: AttendanceSizes.dayArrow,
            height: AttendanceSizes.dayArrow,
            alignment: Alignment.center,
            child: Icon(
              AppIcons.calendar,
              size: AttendanceSizes.dayArrowGlyph,
              color: c.ink,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: AttendanceTextStyles.stripValue.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _SmallKey(
            label: AttendanceStrings.changeRange,
            onTap: onChange,
            isFilled: true,
          ),
          _SmallKey(label: AppStrings.clearAll, onTap: onClearAll),
        ],
      ),
    );
  }
}

/// One of the strip's two keys. Neither is the screen's one action, so
/// neither is pink.
class _SmallKey extends StatelessWidget {
  const _SmallKey({
    required this.label,
    required this.onTap,
    this.isFilled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isFilled
              ? AppSurfaces.glyphTile(c, fill: c.sub, radius: AppRadii.chip)
              : AppSurfaces.chip(c),
          padding: AttendanceSizes.rangeKeyPad,
          child: Text(
            label,
            style: AttendanceTextStyles.stripKey.copyWith(
              color: isFilled ? c.ink : c.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
