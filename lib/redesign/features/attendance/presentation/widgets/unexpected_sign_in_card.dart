import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// The gate in front of signing in somebody who is not expected today.
///
/// The app has always asked this as a dialog on top of the form; here it is
/// part of the form, so the names are on screen beside the key rather than
/// over it. Until it is answered the key underneath stays off.
class UnexpectedSignInCard extends StatelessWidget {
  const UnexpectedSignInCard({
    required this.names,
    required this.onAcknowledge,
    super.key,
  });

  /// The names, already written as a sentence.
  final String names;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: AttendanceSizes.ackPad,
      lineColor: c.dangerLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AttendanceSizes.ackGap,
        children: <Widget>[
          SectionEyebrow(
            label: AttendanceStrings.unexpectedTitle,
            color: c.dangerFg,
          ),
          Text(
            AttendanceStrings.unexpectedBody(names),
            style: AttendanceTextStyles.noticeBody.copyWith(color: c.ink2),
          ),
          SecondaryKey(
            label: AttendanceStrings.unexpectedAcknowledge,
            onTap: onAcknowledge,
          ),
        ],
      ),
    );
  }
}
