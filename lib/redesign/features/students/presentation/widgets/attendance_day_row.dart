import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/attendance_label.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/ringed_avatar.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// One day of a student's attendance (5c Attendance).
///
/// The ring around the little avatar repeats the status the word on the right
/// gives, so the column can be read down at a glance without reading it.
class AttendanceDayRow extends StatelessWidget {
  const AttendanceDayRow({
    required this.day,
    required this.initials,
    super.key,
  });

  final AttendanceDay day;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.keySecondary(c),
      padding: StudentsSizes.itemRowPad,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          RingedAvatar(
            initials: initials,
            status: day.status,
            size: StudentsSizes.miniAvatar,
            gap: StudentsSizes.miniAvatarRingGap,
            textStyle: StudentsTextStyles.kindTile,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  day.dateLabel,
                  style: StudentsTextStyles.itemTitle.copyWith(color: c.ink),
                ),
                Text(
                  day.detail,
                  style: StudentsTextStyles.footnote.copyWith(color: c.ink3),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: AppSizes.rowTextGap,
            children: <Widget>[
              AttendanceLabel(
                status: day.status,
                style: StudentsTextStyles.fieldKey,
              ),
              Text(
                day.hoursLabel,
                style: StudentsTextStyles.footnote.copyWith(color: c.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
