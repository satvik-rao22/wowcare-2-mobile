import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// The recessed note at the foot of a list: what you are looking at, and why
/// it is not everything (4a, 4c).
///
/// A well rather than a card, because there is nothing to press.
class AttendanceScopeNote extends StatelessWidget {
  const AttendanceScopeNote({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppWell(
      padding: AttendanceSizes.notePad,
      radius: AppRadii.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AttendanceSizes.noteGap,
        children: <Widget>[
          Text(
            title,
            style: AttendanceTextStyles.noteTitle.copyWith(color: c.ink),
          ),
          Text(
            body,
            style: AttendanceTextStyles.footnote.copyWith(color: c.ink2),
          ),
        ],
      ),
    );
  }
}
