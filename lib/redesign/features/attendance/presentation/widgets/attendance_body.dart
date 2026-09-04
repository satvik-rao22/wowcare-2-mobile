import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/cubit/attendance_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_empty_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_group_section.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_notice_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_scope_note.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/guardian_child_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/guardian_day_row.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/self_shift_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/staff_gap_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/students_locked_card.dart';

/// Everything under the day strip: the cards that lead the list, the list
/// itself, and the states that stand in for it (4a, 4c, 4d, 4e).
///
/// It takes callbacks rather than reaching for the cubit, so the same body
/// draws all three lenses and the page decides what each key does.
class AttendanceBody extends StatelessWidget {
  const AttendanceBody({
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onClearNarrowing,
    required this.onToggleRow,
    required this.onSelectRow,
    required this.onMoreActions,
    required this.onSignSelf,
    required this.onSignOutSelf,
    required this.onOpenScheduling,
    required this.onSeeWhoIsFree,
    required this.onScanQr,
    required this.onGuardianSignOut,
    super.key,
  });

  final AttendanceState state;

  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onClearNarrowing;

  final ValueChanged<AttendanceRecord> onToggleRow;
  final ValueChanged<AttendanceRecord> onSelectRow;
  final ValueChanged<AttendanceRecord> onMoreActions;

  final VoidCallback onSignSelf;
  final VoidCallback onSignOutSelf;
  final VoidCallback onOpenScheduling;
  final VoidCallback onSeeWhoIsFree;

  final VoidCallback onScanQr;
  final ValueChanged<AttendanceRecord> onGuardianSignOut;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    color: context.colours.pink,
    backgroundColor: context.colours.card,
    child: ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: AttendanceSizes.listPad,
      children: <Widget>[
        for (final card in _cards(context))
          Padding(
            padding: const EdgeInsets.only(bottom: AttendanceSizes.groupGap),
            child: card,
          ),
      ],
    ),
  );

  List<Widget> _cards(BuildContext context) => <Widget>[
    if (state.isOffline) _offlineCard(),
    if (state.isGuardian) ..._guardian(context) else ..._school(context),
  ];

  // --- The school-side list -------------------------------------------------

  List<Widget> _school(BuildContext context) {
    final shift = state.selfShift;

    return <Widget>[
      if (shift != null)
        SelfShiftCard(
          shift: shift,
          now: ClockTime.fromDateTime(state.today),
          isWorking: state.isWorking,
          onSignIn: onSignSelf,
          onSignOut: onSignOutSelf,
        ),
      if (state.isLocked) const StudentsLockedCard(),
      if (state.snapshot.staffGap != null && !state.audience.isStudents)
        StaffGapCard(
          gap: state.snapshot.staffGap!,
          onOpenScheduling: onOpenScheduling,
          onSeeWhoIsFree: onSeeWhoIsFree,
        ),
      if (!state.isToday) _readOnlyCard(),
      ..._groups(),
      if (state.isNobodyAbsent) _nobodyAbsentCard(),
      if (state.hasNoResults && !state.isNobodyAbsent) _noResultsCard(),
      if (state.isEmptyDay) _emptyDayCard(),
      if (!state.isEmptyDay) _scopeNote(),
    ];
  }

  /// The list itself. A locked classroom is legible and inert, which is what
  /// 4d fades it for.
  List<Widget> _groups() {
    final list = <Widget>[
      for (final group in state.groups)
        AttendanceGroupSection(
          group: group,
          expandedId: state.expandedId,
          isSelectMode: state.isSelectMode,
          selectedIds: state.selectedIds,
          onToggle: state.isSelectMode ? onSelectRow : onToggleRow,
          onMoreActions: state.canWrite || state.canEditTimes
              ? onMoreActions
              : null,
        ),
    ];
    if (!state.isLocked) return list;
    return <Widget>[
      for (final section in list)
        IgnorePointer(
          child: Opacity(
            opacity: AttendanceSizes.lockedOpacity,
            child: section,
          ),
        ),
    ];
  }

  // --- The cards that report the day ---------------------------------------

  Widget _offlineCard() => AttendanceNoticeCard(
    eyebrow: AttendanceStrings.couldNotLoadEyebrow,
    body: AttendanceStrings.offlineBody(state.asOfLabel ?? ''),
    primaryLabel: AppStrings.retry,
    onPrimary: onRetry,
    secondaryLabel: AttendanceStrings.keepReadingCache,
    onSecondary: onClearNarrowing,
    footnote: AttendanceStrings.offlineFootnote,
  );

  Widget _readOnlyCard() => AttendanceNoticeCard(
    tone: NoticeTone.success,
    icon: AppIcons.calendar,
    eyebrow: AttendanceFormats.weekdayDate(state.day),
    body: AttendanceStrings.readOnlyDay,
  );

  Widget _nobodyAbsentCard() => AttendanceNoticeCard(
    tone: NoticeTone.success,
    icon: AppIcons.check,
    eyebrow: AttendanceStrings.nobodyAbsentEyebrow,
    body: AttendanceStrings.nobodyAbsentBody(
      state.snapshot.studentsTotal,
      state.snapshot.classroomNames.join(' and '),
    ),
  );

  Widget _noResultsCard() => AttendanceEmptyCard(
    icon: AppIcons.search,
    title: AttendanceStrings.noResultsTitle(
      state.query.trim().isEmpty ? state.filter.label : state.query.trim(),
      state.classroomCount,
    ),
    body: AttendanceStrings.noResultsBody,
    primaryLabel: AttendanceStrings.searchAllClassrooms,
    onPrimary: onClearNarrowing,
    secondaryLabel: AttendanceStrings.clearFilter,
    onSecondary: onClearNarrowing,
  );

  Widget _emptyDayCard() => const AttendanceEmptyCard(
    icon: AppIcons.attendance,
    title: AttendanceStrings.emptyDayTitle,
    body: AttendanceStrings.emptyDayBody,
  );

  Widget _scopeNote() {
    if (state.isStaffLens) {
      return AttendanceScopeNote(
        title: AttendanceStrings.scopeStaffTitle,
        body: AttendanceStrings.scopeStaffBody(
          state.scopeClassroom ?? AppStrings.classrooms,
        ),
      );
    }
    if (!state.audience.isStudents) {
      return AttendanceScopeNote(
        title: AttendanceStrings.hoursTodayTitle,
        body: AttendanceStrings.hoursTodayBody(
          AttendanceFormats.span(state.snapshot.staffMinutesToday),
          state.snapshot.staffSignedIn,
        ),
      );
    }
    return AttendanceScopeNote(
      title: AttendanceStrings.scopeAdminTitle(
        state.classroomCount,
        state.snapshot.schoolClassroomCount,
      ),
      body: AttendanceStrings.scopeAdminBody(state.scopedStudentCount),
    );
  }

  // --- The guardian lens ----------------------------------------------------

  List<Widget> _guardian(BuildContext context) {
    final c = context.colours;

    return <Widget>[
      for (final child in state.snapshot.children) ...<Widget>[
        GuardianChildCard(
          record: child.today,
          onScanQr: onScanQr,
          onSignOut: () => onGuardianSignOut(child.today),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSizes.sectionGap,
          children: <Widget>[
            SectionEyebrow(
              label: AttendanceStrings.thisMonth,
              color: c.student,
              meta: AttendanceStrings.monthSummary(
                child.daysIn,
                child.daysAbsent,
                child.hours,
              ),
              metaColor: c.ink2,
            ),
            for (final day in child.days)
              Padding(
                padding: const EdgeInsets.only(bottom: AttendanceSizes.rowGap),
                child: GuardianDayRow(day: day),
              ),
          ],
        ),
      ],
      if (state.snapshot.children.isEmpty) _emptyDayCard(),
    ];
  }
}
