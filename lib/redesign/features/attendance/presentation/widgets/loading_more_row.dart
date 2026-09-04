import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// The foot of a list with another page behind it (4f).
///
/// Three dots and a word rather than a spinner: the list is already on
/// screen, and a ring over it would say the whole thing was reloading.
class LoadingMoreRow extends StatelessWidget {
  const LoadingMoreRow({super.key});

  static const int _dots = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: AttendanceSizes.loadingMorePad,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AttendanceSizes.loadingDotGap,
        children: <Widget>[
          for (var i = 0; i < _dots; i++)
            Container(
              width: AttendanceSizes.loadingDot,
              height: AttendanceSizes.loadingDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0 ? c.notMarked : c.track,
              ),
            ),
          Text(
            AttendanceStrings.loadingMore,
            style: AttendanceTextStyles.stripKey.copyWith(color: c.ink3),
          ),
        ],
      ),
    );
  }
}
