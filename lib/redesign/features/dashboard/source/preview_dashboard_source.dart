import 'package:flutter/material.dart' show TimeOfDay;
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/source/dashboard_source.dart';

/// M03's fixtures: Maple View on the design's own day, seen three ways.
///
/// The counts are the frames' own. Where a frame and `DemoData` disagree,
/// `DemoData` wins, so the Sunflower roster a reviewer opens from Classrooms
/// is the same Sunflower this card counts.
class PreviewDashboardSource implements DashboardSource {
  const PreviewDashboardSource();

  static const Duration _latency = Duration(milliseconds: 500);

  static const String _dateLabel = 'Thu, 20 Aug';

  @override
  Future<DashboardSnapshot> load(Persona persona) async {
    await Future<void>.delayed(_latency);
    return switch (persona) {
      Persona.admin => _admin,
      Persona.staff => _staff,
      Persona.guardian => _guardian,
    };
  }

  @override
  Future<MyDay> signOutSelf({required MyDay day, DateTime? at}) async {
    await Future<void>.delayed(_latency);
    return day.copyWith(status: AttendanceStatus.signedOut);
  }

  @override
  Future<MyDay> transfer({
    required MyDay day,
    required String classroomName,
  }) async {
    await Future<void>.delayed(_latency);
    return day.copyWith(classroomName: classroomName);
  }

  @override
  Future<MyDay> setAbsent({
    required MyDay day,
    required bool isAbsent,
  }) async {
    await Future<void>.delayed(_latency);
    return day.copyWith(
      isAbsent: isAbsent,
      status: isAbsent ? AttendanceStatus.absent : AttendanceStatus.signedIn,
    );
  }

  @override
  Future<ChildDay> signOutChild(ChildDay child) async {
    await Future<void>.delayed(_latency);
    return child.copyWith(attendance: AttendanceStatus.signedOut);
  }

  @override
  Future<ChildDay> setReminder({
    required ChildDay child,
    required bool isOn,
  }) async {
    await Future<void>.delayed(_latency);
    return child.copyWith(isReminderOn: isOn);
  }

  // --- The three dashboards -------------------------------------------------

  static DashboardSnapshot get _admin => DashboardSnapshot(
    dateLabel: _dateLabel,
    attention: const AttentionSummary(
      pendingIncidents: 3,
      ratioShortfalls: <RatioShortfall>[
        RatioShortfall(
          classroomCode: 'sunflower',
          classroomName: 'Sunflower',
          staffPresent: 1,
          staffNeeded: 1,
        ),
        RatioShortfall(
          classroomCode: 'bluebell',
          classroomName: 'Bluebell',
          staffPresent: 1,
          staffNeeded: 1,
        ),
      ],
      openShift: OpenShiftGap(
        classroomCode: 'bluebell',
        classroomName: 'Bluebell',
        start: TimeOfDay(hour: 13, minute: 0),
        end: TimeOfDay(hour: 18, minute: 0),
        staffNeeded: 2,
        staffScheduled: 1,
      ),
      pendingMovements: 4,
      overdueMovements: 1,
      expiredStudentDocuments: 2,
      expiringStudentDocuments: 6,
      expiringStaffDocuments: 3,
      outstandingAmount: 5000,
      outstandingPercent: 5,
    ),
    myDay: _myDay(DemoData.staffMembers.first, workWindow: '7:30 – 17:30'),
    schoolStatus: _schoolStatus,
    ratios: _adminRatios,
    shifts: _shifts,
    placesFilled: 86,
    capacity: 120,
    movesToApprove: 4,
    billing: _billing,
    message: const MessagePreview(
      conversationId: 'dana',
      name: 'Dana Whitfield',
      initials: 'DW',
      preview: 'Can I swap Friday’s break with Priya?',
      unreadCount: 2,
    ),
  );

  static DashboardSnapshot get _staff => DashboardSnapshot(
    dateLabel: _dateLabel,
    myDay: _myDay(
      DemoData.staffMembers[1],
      workWindow: '7:30 – 16:00',
      breakWindow: '12:00 – 12:30',
      classroomName: 'Sunflower',
    ),
    ratios: _staffRatios,
    week: _week,
    weekRangeLabel: '17–23 Aug',
    myAttendance: const AttendanceRecord(
      rangeLabel: '1 Aug – 20 Aug',
      daysAttended: 12,
      hoursAttended: 96,
      minutesAttended: 20,
      daysAbsent: 1,
      days: <AttendanceDay>[
        AttendanceDay(label: 'Mon · 17 Aug', from: '7:32 AM', to: '4:04 PM'),
        AttendanceDay(label: 'Fri · 14 Aug', absenceReason: ''),
      ],
    ),
    message: const MessagePreview(
      conversationId: 'ngozi',
      name: 'Ngozi Okafor',
      initials: 'NO',
      preview: 'Amara’s grandmother collects today',
      unreadCount: 1,
      isFromStaff: false,
    ),
  );

  static DashboardSnapshot get _guardian => DashboardSnapshot(
    dateLabel: _dateLabel,
    children: <ChildDay>[
      for (final child in DemoData.guardianChildren)
        ChildDay(
          id: child.id,
          name: child.name,
          initials: child.initials,
          classroomName: child.classroom,
          age: child.age,
          attendance: _statusOf(child.attendance),
          inTimeLabel: child.timeLabel,
          dayEndsLabel: '4:30 PM',
          activities: child.attendance == DemoAttendance.signedIn
              ? const ActivityTally(
                  napStartedLabel: '12:20',
                  meals: 2,
                  photos: 4,
                  bathroom: 3,
                )
              : const ActivityTally(meals: 1, photos: 2, bathroom: 1),
          isReminderOn: true,
        ),
    ],
    guardianBilling: const GuardianBilling(
      balanceDue: 412,
      dueLabel: '25 Aug',
      monthLabel: 'August',
      isAutopayOn: true,
      invoices: <InvoiceRow>[
        InvoiceRow(
          title: 'July tuition',
          meta: 'Paid 24 Jul · Visa 4471',
          amount: 412,
        ),
      ],
    ),
    childAttendance: const AttendanceRecord(
      rangeLabel: '1–20 Aug',
      daysAttended: 11,
      hoursAttended: 88,
      minutesAttended: 0,
      daysAbsent: 1,
      days: <AttendanceDay>[
        AttendanceDay(label: 'Mon · 17 Aug', from: '8:02 AM', to: '4:28 PM'),
        AttendanceDay(label: 'Fri · 14 Aug', absenceReason: 'unwell'),
      ],
    ),
    newsletter: const NewsletterRow(
      title: 'August newsletter',
      meta: 'Sunflower · 2 days ago',
    ),
  );

  // --- Shared fixtures ------------------------------------------------------

  static MyDay _myDay(
    DemoStaff member, {
    required String workWindow,
    String breakWindow = '13:00 – 13:30',
    String? classroomName,
  }) => MyDay(
    status: _statusOf(member.attendance),
    sinceLabel: member.timeLabel,
    workWindow: workWindow,
    breakWindow: breakWindow,
    signInPin: member.signInPin,
    classroomName: classroomName,
    onClockLabel: '8h 28m',
  );

  static const SchoolStatus _schoolStatus = SchoolStatus(
    classrooms: 5,
    capacity: 120,
    occupancyPercent: 82,
    studentsEnrolled: 86,
    studentsExpected: 80,
    students: AttendanceBreakdown(
      signedIn: 71,
      signedOut: 3,
      absent: 4,
      notMarked: 2,
    ),
    staffExpected: 15,
    staff: AttendanceBreakdown(
      signedIn: 12,
      signedOut: 1,
      absent: 1,
      notMarked: 1,
    ),
  );

  static const List<RatioRow> _adminRatios = <RatioRow>[
    RatioRow(
      classroomName: 'Bluebell',
      groupName: 'Toddler',
      students: 7,
      staff: 1,
      staffNeeded: 1,
    ),
    RatioRow(
      classroomName: 'Sunflower',
      groupName: 'Preschool',
      students: 9,
      staff: 1,
      staffNeeded: 1,
    ),
    RatioRow(
      classroomName: 'Maple',
      groupName: 'Preschool',
      students: 22,
      staff: 3,
      staffNeeded: 0,
    ),
  ];

  static const List<RatioRow> _staffRatios = <RatioRow>[
    RatioRow(
      classroomName: 'Sunflower',
      groupName: 'Preschool',
      students: 8,
      staff: 1,
      staffNeeded: 0,
      enrolled: 14,
    ),
    RatioRow(
      classroomName: 'Bluebell',
      groupName: 'Toddler',
      students: 6,
      staff: 1,
      staffNeeded: 0,
      enrolled: 9,
      isCovering: true,
      coveringFrom: '13:00',
    ),
  ];

  static const List<ShiftRow> _shifts = <ShiftRow>[
    ShiftRow(
      classroomName: 'Sunflower',
      window: '7:30 – 16:00',
      staffNeeded: 2,
      staffScheduled: 2,
      staffNames: 'Dana W., Priya R.',
    ),
    ShiftRow(
      classroomName: 'Bluebell',
      window: '13:00 – 18:00',
      staffNeeded: 2,
      staffScheduled: 1,
    ),
  ];

  static const BillingSummary _billing = BillingSummary(
    rangeLabel: '1 – 31 Aug',
    invoiced: 94200,
    netPaid: 89200,
    inProcess: 1200,
    outstanding: 5000,
    allUnpaid: 12480,
  );

  static const List<ShiftDay> _week = <ShiftDay>[
    ShiftDay(
      weekdayLabel: 'THU',
      dayNumber: 20,
      classroomName: 'Sunflower',
      window: '7:30 – 16:00',
      breakWindow: '12:30 – 13:00',
      isToday: true,
    ),
    ShiftDay(
      weekdayLabel: 'FRI',
      dayNumber: 21,
      classroomName: 'Sunflower',
      window: '7:30 – 16:00',
      breakWindow: '12:30 – 13:00',
    ),
    ShiftDay(
      weekdayLabel: 'MON',
      dayNumber: 24,
      classroomName: 'Bluebell',
      window: '8:00 – 16:30',
      breakWindow: '13:00 – 13:30',
      isCovering: true,
    ),
    ShiftDay(weekdayLabel: 'TUE', dayNumber: 25),
  ];

  static AttendanceStatus _statusOf(DemoAttendance attendance) =>
      switch (attendance) {
        DemoAttendance.signedIn => AttendanceStatus.signedIn,
        DemoAttendance.signedOut => AttendanceStatus.signedOut,
        DemoAttendance.absent => AttendanceStatus.absent,
        DemoAttendance.notMarked => AttendanceStatus.notMarked,
      };
}
