import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';

/// Today's attendance, in the app's own words.
enum AttendanceStatus {
  signedIn,
  signedOut,
  absent,
  notMarked;

  /// The dot colour this status draws in.
  Color colour(Colourway c) => switch (this) {
    AttendanceStatus.signedIn => c.signedIn,
    AttendanceStatus.signedOut => c.signedOut,
    AttendanceStatus.absent => c.absent,
    AttendanceStatus.notMarked => c.notMarked,
  };
}

/// The 13px attendance dot, ringed 2.5px in the colour of the card it sits
/// on. Components page `.avatar__dot`.
///
/// Usually drawn by `AppAvatar`; on its own it is a legend swatch.
class AttendanceDot extends StatelessWidget {
  const AttendanceDot({
    required this.status,
    this.size = AppSizes.attendanceDot,
    this.ringColor,
    this.ringWidth = AppSizes.attendanceDotRing,
    super.key,
  });

  final AttendanceStatus status;
  final double size;

  /// The ground the dot sits on. Defaults to the card colour.
  final Color? ringColor;

  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status.colour(c),
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? c.card, width: ringWidth),
      ),
    );
  }
}
