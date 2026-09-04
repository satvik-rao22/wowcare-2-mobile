import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// Today's attendance in words: "Signed In 8:42", "Absent", "Not Marked".
///
/// The colour is the dot's own, so the line and the dot on the avatar always
/// agree. Green is signed in, red is absent, and the two quiet states stay
/// quiet.
class AttendanceLabel extends StatelessWidget {
  const AttendanceLabel({
    required this.status,
    this.timeLabel,
    this.style,
    super.key,
  });

  final AttendanceStatus status;

  /// "8:42". Null leaves the status word on its own.
  final String? timeLabel;

  final TextStyle? style;

  /// What the status word is written in. Signed Out is ink rather than a
  /// colour of its own: leaving is not an event.
  static Color inkFor(Colourway c, AttendanceStatus status) => switch (status) {
    AttendanceStatus.signedIn => c.successFg,
    AttendanceStatus.signedOut => c.ink,
    AttendanceStatus.absent => c.dangerFg,
    AttendanceStatus.notMarked => c.ink2,
  };

  static String wordFor(AttendanceStatus status) => switch (status) {
    AttendanceStatus.signedIn => AppStrings.signedIn,
    AttendanceStatus.signedOut => AppStrings.signedOut,
    AttendanceStatus.absent => AppStrings.absent,
    AttendanceStatus.notMarked => AppStrings.notMarked,
  };

  @override
  Widget build(BuildContext context) {
    final word = wordFor(status);
    return Text(
      timeLabel == null ? word : StudentsStrings.attendanceAt(word, timeLabel!),
      style: (style ?? StudentsTextStyles.emphasis).copyWith(
        color: inkFor(context.colours, status),
      ),
    );
  }
}
