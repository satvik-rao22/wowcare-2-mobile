/// Typed arguments for every route the dashboard pushes.
///
/// Mandate 1: *"Route arguments are typed: path parameters, or a declared class
/// passed through `extra`. No `Object?`, no `dynamic`, no untyped casts at the
/// receiving end."* Before this file the dashboard handed go_router eight raw
/// `Map<String, dynamic>` / `{}` payloads and the router cast them back key by
/// key — a typo in either half is a runtime null, not a build error.
///
/// This is the `model/` folder §3.1 requires and the dashboard did not have.
/// These are screen/route parameter objects, not DTOs and not entities: they
/// carry values the receiving screen already accepts, nothing is serialised,
/// and nothing here goes near the wire.
library;

import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart'
    show FilterData;

/// Args for the attendance tabbed views opened from `RatioMonitoringCard`'s
/// per-classroom student/staff cells.
@immutable
class AttendanceTabbedViewArgs {
  const AttendanceTabbedViewArgs({
    required this.initialTabIndex,
    required this.classroomFilter,
  });

  final int initialTabIndex;
  final FilterData classroomFilter;
}

/// Args for the attendance tabbed views opened from `EnrollmentCard`'s
/// breakdown-bar legend taps. A different shape from
/// [AttendanceTabbedViewArgs]: this one carries a status filter string, not a
/// classroom filter object.
@immutable
class AttendanceStatusFilterArgs {
  const AttendanceStatusFilterArgs({
    required this.filter,
    this.hasBackButton = true,
  });

  /// One of the status buckets the tabbed view understands, e.g. `ACTIVE`,
  /// `UPCOMING`, `Expected`, `Present`, `Signed Out`, `Absent`, `Not Marked`.
  /// Passed through verbatim — the receiving screen owns its vocabulary.
  final String filter;

  final bool hasBackButton;
}

/// Args for the student attendance profile opened from `StudentAttendanceSummaryCard`.
@immutable
class StudentAttendanceProfileArgs {
  const StudentAttendanceProfileArgs({
    required this.studentCode,
    required this.studentName,
    required this.roomName,
    this.studentId = 0,
    this.studentPhotoUuid,
    this.syncWithParentChildSelection = false,
  });

  final String studentCode;
  final String studentName;
  final String roomName;
  final int studentId;
  final String? studentPhotoUuid;

  /// Makes the profile screen follow the parent's child-switcher selection.
  /// The dashboard passes true — dropping it would silently unhook the
  /// switcher, which is exactly the class of regression typed args exist to
  /// prevent (it was a live key in the map this replaced, read at
  /// `_studentAttendanceProfileScreen`).
  final bool syncWithParentChildSelection;
}

/// Args for the mixed sign-in/out selection screen, reached both from
/// `MyChildsDayCard`'s action button and from a QR scan.
@immutable
class ChildSignInOutSelectionArgs {
  const ChildSignInOutSelectionArgs({
    required this.signedInCodes,
    required this.signedOutCodes,
    this.isQrScan = false,
    this.qrToken,
  });

  final List<String> signedInCodes;
  final List<String> signedOutCodes;
  final bool isQrScan;
  final String? qrToken;
}

/// Cache-buster for the incident-filtered activity feed opened from the
/// "Need your attention" grid.
///
/// A typed carrier rather than `{'timestamp': …}`: the value is never read by
/// the destination, it exists purely so two taps produce two distinct
/// locations. Naming it says that out loud instead of leaving a mystery key in
/// an untyped map.
@immutable
class IncidentFeedNonce {
  const IncidentFeedNonce({required this.value});

  final int value;
}

/// Args for the staff attendance profile opened from `MyAttendanceCard`'s
/// header redirect. Only the four fields the card actually varies are declared;
/// the rest keep the receiving screen's own defaults, which is what the map
/// this replaces did by omission.
@immutable
class StaffAttendanceProfileArgs {
  const StaffAttendanceProfileArgs({
    required this.staffCode,
    required this.staffName,
    this.staffId = 0,
    this.designationName = '',
    this.roomName = '-',
  });

  final String staffCode;
  final String staffName;
  final int staffId;
  final String designationName;
  final String roomName;
}
