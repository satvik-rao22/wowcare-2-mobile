import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// How M07's own tones land on the colourway.
///
/// Kept in one place so "teal is students, sun is staff, red is danger" is
/// decided once rather than at thirty call sites, and so a screen never
/// reaches for a swatch of its own.
extension RosterToneColors on RosterTone {
  Color fill(Colourway c) => switch (this) {
    RosterTone.student => c.studentBg,
    RosterTone.staff => c.staffBg,
    RosterTone.danger => c.dangerBg,
    RosterTone.neutral => c.neutralBg,
  };

  Color ink(Colourway c) => switch (this) {
    RosterTone.student => c.student,
    RosterTone.staff => c.staffFg,
    RosterTone.danger => c.dangerFg,
    RosterTone.neutral => c.neutralFg,
  };
}

/// A staff member's duty state, as a pill.
extension StaffDutyColors on StaffDutyState {
  PillTone get pillTone => switch (this) {
    StaffDutyState.onDuty => PillTone.success,
    StaffDutyState.onBreak => PillTone.staff,
    StaffDutyState.absent => PillTone.danger,
    StaffDutyState.notMarked || StaffDutyState.signedOut => PillTone.neutral,
  };
}

/// A classroom's ratio, as a pill. Two live states and two quiet ones, and
/// never a ratio figure.
extension RatioStateColors on ClassroomRatioState {
  PillTone get pillTone => switch (this) {
    ClassroomRatioState.inRatio => PillTone.success,
    ClassroomRatioState.short => PillTone.danger,
    ClassroomRatioState.noStaff ||
    ClassroomRatioState.empty => PillTone.neutral,
  };

  /// Whether the classroom's card takes the danger hairline.
  bool get isShort => this == ClassroomRatioState.short;
}
