import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The line over a classroom's Staff tab that says the ratio out loud (7c):
/// how many staff there are for how many students, and how many are wanted.
///
/// Sun when the classroom is covered, danger when it is short. Counts only:
/// the number of staff wanted, never a ratio figure.
class RatioNotice extends StatelessWidget {
  const RatioNotice({required this.message, this.isShort = false, super.key});

  final String message;
  final bool isShort;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = isShort ? c.dangerFg : c.staffFg;

    return Container(
      padding: ClassroomsSizes.noticePad,
      decoration: BoxDecoration(
        color: isShort ? c.dangerBg : c.staffBg,
        borderRadius: AppRadii.innerR,
        border: Border.all(color: isShort ? c.dangerLine : c.staffLine),
      ),
      child: Row(
        spacing: ClassroomsSizes.noticeGap,
        children: <Widget>[
          Icon(
            isShort ? AppIcons.alertTriangle : AppIcons.clock,
            size: ClassroomsSizes.noticeGlyph,
            color: ink,
          ),
          Expanded(
            child: Text(
              message,
              style: ClassroomsTextStyles.notice.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
