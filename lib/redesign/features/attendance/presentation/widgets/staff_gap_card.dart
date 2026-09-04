import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// A classroom that runs short later today, over the staff list (4c).
///
/// The one card on this screen with a pink key on it, because covering a gap
/// before it happens is the whole reason to be looking at the staff list at
/// half past nine.
class StaffGapCard extends StatelessWidget {
  const StaffGapCard({
    required this.gap,
    required this.onOpenScheduling,
    required this.onSeeWhoIsFree,
    super.key,
  });

  final StaffGap gap;
  final VoidCallback onOpenScheduling;
  final VoidCallback onSeeWhoIsFree;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      lineColor: c.dangerLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AttendanceSizes.alertCardGap,
        children: <Widget>[
          Row(
            spacing: AttendanceSizes.alertCardGap,
            children: <Widget>[
              SurfaceBox(
                surface: AppSurfaces.glyphTile(
                  c,
                  fill: c.dangerBg,
                  radius: AttendanceSizes.alertTileRadius,
                ),
                width: AttendanceSizes.alertTile,
                height: AttendanceSizes.alertTile,
                alignment: Alignment.center,
                child: Icon(
                  AppIcons.alertTriangle,
                  size: AttendanceSizes.alertTileGlyph,
                  color: c.dangerFg,
                ),
              ),
              Expanded(
                child: Text(
                  AttendanceStrings.gapTitle(gap.classroomName, gap.at.label),
                  style: AttendanceTextStyles.noticeTitle.copyWith(
                    color: c.ink,
                  ),
                ),
              ),
            ],
          ),
          Text(
            gap.body,
            style: AttendanceTextStyles.noticeBody.copyWith(color: c.ink2),
          ),
          Row(
            spacing: AttendanceSizes.alertKeyGap,
            children: <Widget>[
              Expanded(
                child: PrimaryKey(
                  label: AttendanceStrings.openScheduling,
                  onTap: onOpenScheduling,
                ),
              ),
              Expanded(
                child: SecondaryKey(
                  label: AttendanceStrings.seeWhoIsFree,
                  onTap: onSeeWhoIsFree,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
