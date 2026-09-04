import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// Why the classroom under it is inert (4d).
///
/// A teacher can read their classroom before they have signed themselves in;
/// they cannot sign anyone in or out. Saying so is better than a list of dead
/// keys with no explanation.
class StudentsLockedCard extends StatelessWidget {
  const StudentsLockedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AttendanceSizes.sheetHeaderGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.glyphTile(
              c,
              fill: c.well,
              radius: AttendanceSizes.lockRadius,
            ),
            width: AttendanceSizes.lockTile,
            height: AttendanceSizes.lockTile,
            alignment: Alignment.center,
            child: Icon(
              AppIcons.lock,
              size: AttendanceSizes.lockGlyph,
              color: c.ink2,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AttendanceSizes.noteGap,
              children: <Widget>[
                Text(
                  AttendanceStrings.lockedTitle,
                  style: AttendanceTextStyles.noticeTitle.copyWith(
                    color: c.ink,
                  ),
                ),
                Text(
                  AttendanceStrings.lockedBody,
                  style: AttendanceTextStyles.noticeBody.copyWith(
                    color: c.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
