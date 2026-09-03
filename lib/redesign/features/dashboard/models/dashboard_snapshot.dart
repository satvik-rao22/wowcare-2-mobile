import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/dashboard/models/attention_summary.dart';
import 'package:wowcare/redesign/features/dashboard/models/billing_summary.dart';
import 'package:wowcare/redesign/features/dashboard/models/child_day.dart';
import 'package:wowcare/redesign/features/dashboard/models/guardian_billing.dart';
import 'package:wowcare/redesign/features/dashboard/models/message_preview.dart';
import 'package:wowcare/redesign/features/dashboard/models/my_day.dart';
import 'package:wowcare/redesign/features/dashboard/models/my_week.dart';
import 'package:wowcare/redesign/features/dashboard/models/ratio_row.dart';
import 'package:wowcare/redesign/features/dashboard/models/school_status.dart';
import 'package:wowcare/redesign/features/dashboard/models/shift_row.dart';

/// Everything a dashboard draws, for whichever persona is looking.
///
/// One object rather than three, because the three dashboards are the same
/// screen showing different cards: the fields a persona cannot see are simply
/// null, and the page never asks the cubit which persona it is.
@immutable
class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    this.dateLabel = '',
    this.attention = const AttentionSummary(),
    this.myDay,
    this.schoolStatus,
    this.ratios = const <RatioRow>[],
    this.shifts = const <ShiftRow>[],
    this.placesFilled = 0,
    this.capacity = 0,
    this.movesToApprove = 0,
    this.billing,
    this.week = const <ShiftDay>[],
    this.weekRangeLabel = '',
    this.myAttendance,
    this.message,
    this.children = const <ChildDay>[],
    this.guardianBilling,
    this.childAttendance,
    this.newsletter,
  });

  /// "Thu, 20 Aug", in the school's timezone rather than the device's.
  final String dateLabel;

  // --- Admin and Staff ------------------------------------------------------

  final AttentionSummary attention;
  final MyDay? myDay;
  final SchoolStatus? schoolStatus;
  final List<RatioRow> ratios;
  final List<ShiftRow> shifts;
  final int placesFilled;
  final int capacity;
  final int movesToApprove;
  final BillingSummary? billing;

  /// 3S2's week strip and the range above it.
  final List<ShiftDay> week;
  final String weekRangeLabel;
  final AttendanceRecord? myAttendance;

  final MessagePreview? message;

  // --- Guardian -------------------------------------------------------------

  final List<ChildDay> children;
  final GuardianBilling? guardianBilling;
  final AttendanceRecord? childAttendance;
  final NewsletterRow? newsletter;

  DashboardSnapshot copyWith({
    MyDay? myDay,
    List<ChildDay>? children,
  }) => DashboardSnapshot(
    dateLabel: dateLabel,
    attention: attention,
    myDay: myDay ?? this.myDay,
    schoolStatus: schoolStatus,
    ratios: ratios,
    shifts: shifts,
    placesFilled: placesFilled,
    capacity: capacity,
    movesToApprove: movesToApprove,
    billing: billing,
    week: week,
    weekRangeLabel: weekRangeLabel,
    myAttendance: myAttendance,
    message: message,
    children: children ?? this.children,
    guardianBilling: guardianBilling,
    childAttendance: childAttendance,
    newsletter: newsletter,
  );

  @override
  List<Object?> get props => [
    dateLabel,
    attention,
    myDay,
    schoolStatus,
    ratios,
    shifts,
    placesFilled,
    capacity,
    movesToApprove,
    billing,
    week,
    weekRangeLabel,
    myAttendance,
    message,
    children,
    guardianBilling,
    childAttendance,
    newsletter,
  ];
}
