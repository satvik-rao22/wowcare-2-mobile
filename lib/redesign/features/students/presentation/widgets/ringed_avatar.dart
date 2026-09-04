import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/attendance_label.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';

/// An avatar with today's attendance drawn as a ring around it rather than a
/// dot beside it (5c's header, and each day of the Attendance tab).
///
/// A ring rather than a dot because there is only one student on the screen:
/// the status belongs to the whole record, not to a row in a list.
class RingedAvatar extends StatelessWidget {
  const RingedAvatar({
    required this.initials,
    required this.status,
    this.size = StudentsSizes.profileAvatar,
    this.ringWidth = StudentsSizes.profileAvatarRing,
    this.gap = StudentsSizes.profileAvatarRingGap,
    this.textStyle,
    super.key,
  });

  final String initials;
  final AttendanceStatus status;
  final double size;
  final double ringWidth;

  /// The breathing space between the ring and the bubble.
  final double gap;

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = AttendanceLabel.inkFor(c, status);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(gap),
      // A ring is a border on a circle: there is no `AppSurfaces` recipe for
      // one, and its colour and width are both tokens.
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink, width: ringWidth),
      ),
      child: AppAvatar(
        initials: initials,
        size: size - (ringWidth + gap) * 2,
        textStyle: textStyle ?? AppTextStyles.avatarInitials,
      ),
    );
  }
}
