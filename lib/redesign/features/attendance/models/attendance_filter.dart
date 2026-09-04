import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';

/// The chip run over the list. One at a time, and tapping the live one clears
/// it back to [all].
enum AttendanceFilter {
  all,
  signedIn,
  notMarked,
  absent,
  signedOut;

  String get label => switch (this) {
    AttendanceFilter.all => AttendanceStrings.allChip,
    AttendanceFilter.signedIn => AppStrings.signedIn,
    AttendanceFilter.notMarked => AppStrings.notMarked,
    AttendanceFilter.absent => AppStrings.absent,
    AttendanceFilter.signedOut => AppStrings.signedOut,
  };

  /// The status this chip narrows to. Null for [all].
  AttendanceStatus? get status => switch (this) {
    AttendanceFilter.all => null,
    AttendanceFilter.signedIn => AttendanceStatus.signedIn,
    AttendanceFilter.notMarked => AttendanceStatus.notMarked,
    AttendanceFilter.absent => AttendanceStatus.absent,
    AttendanceFilter.signedOut => AttendanceStatus.signedOut,
  };

  bool matches(AttendanceStatus other) => status == null || status == other;
}
