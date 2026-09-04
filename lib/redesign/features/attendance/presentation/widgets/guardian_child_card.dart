import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_avatar.dart';

/// One of a guardian's children, at the top of their own attendance screen
/// (4a, parent lens).
///
/// A guardian is told where their child is and by whom, and is given the one
/// thing they can do about it. Signing out is theirs; signing in belongs to
/// the door.
class GuardianChildCard extends StatelessWidget {
  const GuardianChildCard({
    required this.record,
    required this.onScanQr,
    required this.onSignOut,
    super.key,
  });

  final AttendanceRecord record;
  final VoidCallback onScanQr;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AttendanceSizes.guardianGap,
        children: <Widget>[
          Row(
            spacing: AttendanceSizes.sheetHeaderGap,
            children: <Widget>[
              AttendanceAvatar(
                initials: record.initials,
                status: record.status,
                size: AttendanceSizes.headerAvatar,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      _headline,
                      style: AttendanceTextStyles.heroLine.copyWith(
                        color: c.ink,
                      ),
                    ),
                    Text(
                      _line(c),
                      style: AttendanceTextStyles.heroSub.copyWith(
                        color: c.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            spacing: AttendanceSizes.guardianKeyGap,
            children: <Widget>[
              Expanded(
                child: SecondaryKey(
                  label: AttendanceStrings.scanQr,
                  onTap: onScanQr,
                ),
              ),
              Expanded(
                child: PrimaryKey(
                  label: AppStrings.signOut,
                  enabled: record.canSignOut,
                  onTap: onSignOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _headline {
    final name = record.firstName;
    if (record.isSignedIn) return AttendanceStrings.childIsIn(name);
    if (record.isSignedOut) return AttendanceStrings.childIsOut(name);
    if (record.isAbsent) return AttendanceStrings.childIsAbsent(name);
    return AttendanceStrings.childNotMarked(name);
  }

  String _line(Colourway c) {
    final inAt = record.signedInTime;
    final outAt = record.signedOutTime;
    if (record.isSignedIn && inAt != null) {
      return AttendanceStrings.childSignedInLine(
        inAt.label,
        record.signedInBy ?? AttendanceStrings.detailNotRecorded,
      );
    }
    if (record.isSignedOut && outAt != null) {
      return AttendanceStrings.childSignedOutLine(
        outAt.label,
        record.signedOutBy ?? AttendanceStrings.detailNotRecorded,
      );
    }
    if (record.isAbsent) {
      return record.absenceReason ?? AppStrings.absent;
    }
    return AttendanceStrings.rowExpected(record.classroomName);
  }
}
