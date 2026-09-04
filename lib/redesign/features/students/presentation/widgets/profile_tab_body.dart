import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/inline_alert.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/students/cubit/student_profile_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/profile_fields.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/attendance_day_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/dashed_add_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/detail_fields_card.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/document_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/immunization_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/person_card.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/profile_note.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// Whichever of 5c's tabs is open.
///
/// One scrolling body, switched on the tab and its section, rather than a
/// page view: the tabs carry very different amounts of content and a shared
/// scroll position between them would be wrong every time.
class ProfileTabBody extends StatelessWidget {
  const ProfileTabBody({required this.state, required this.record, super.key});

  final StudentProfileState state;
  final StudentProfileRecord record;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: context.read<StudentProfileCubit>().refresh,
    color: context.colours.pink,
    child: ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: AppSizes.bodyPad,
      children: _children(context),
    ),
  );

  List<Widget> _children(BuildContext context) => switch (state.tab) {
    ProfileTab.profile => _profile(context),
    ProfileTab.health => _health(context),
    ProfileTab.attendance => _attendance(context),
    ProfileTab.dates => _dates(context),
    ProfileTab.documents => _documents(context),
  };

  // --- Profile --------------------------------------------------------------

  List<Widget> _profile(BuildContext context) => switch (state.profileSection) {
    ProfileSection.about => <Widget>[
      DetailFieldsCard(
        title: StudentsStrings.aboutTitle(record.student.firstName),
        rows: ProfileFields.about(record),
        onEdit: state.canWrite ? () => unawaited(_edit(context)) : null,
      ),
    ],
    ProfileSection.family => _people(
      context,
      people: record.guardians,
      addLabel: StudentsStrings.addParent,
      note: record.emergencyContact == null
          ? StudentsStrings.guardiansNoteNoEmergency
          : StudentsStrings.guardiansNote(record.emergencyContact!.name),
      actionLabel: StudentsStrings.messageKey,
    ),
    ProfileSection.pickup => _people(
      context,
      people: record.pickups,
      addLabel: StudentsStrings.addPickup,
      note: StudentsStrings.pickupsNote(record.student.firstName),
      actionLabel: StudentsStrings.callKey,
    ),
  };

  List<Widget> _people(
    BuildContext context, {
    required List<StudentPerson> people,
    required String addLabel,
    required String note,
    required String actionLabel,
  }) => <Widget>[
    for (final person in people)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
        child: PersonCard(
          person: person,
          actionLabel: person.badgeTone == PersonBadgeTone.lapsed
              ? StudentsStrings.renewKey
              : actionLabel,
          onAction: () => _soon(context),
          onEdit: state.canWrite ? () => _soon(context) : null,
        ),
      ),
    if (state.canWrite)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
        child: DashedAddRow(label: addLabel, onTap: () => _soon(context)),
      ),
    _note(context, note),
  ];

  // --- Health ---------------------------------------------------------------

  List<Widget> _health(BuildContext context) => switch (state.healthSection) {
    HealthSection.health => <Widget>[
      DetailFieldsCard(
        title: StudentsStrings.healthTitle,
        rows: ProfileFields.health(record.health),
        onEdit: state.canEditHealth ? () => _soon(context) : null,
      ),
      if (record.health.canFamilyEdit) ...<Widget>[
        const SizedBox(height: AppSizes.cardGap),
        const ProfileNote(
          title: StudentsStrings.parentsCanEditTitle,
          body: StudentsStrings.parentsCanEditBody,
        ),
      ],
    ],
    HealthSection.physician => <Widget>[
      if (record.physician == null)
        const EmptyState(
          icon: AppIcons.user,
          title: StudentsStrings.physicianTitle,
          subtitle: StudentsStrings.notRecorded,
        )
      else
        DetailFieldsCard(
          title: StudentsStrings.physicianTitle,
          rows: ProfileFields.physician(record.physician!),
          onEdit: state.canEditHealth ? () => _soon(context) : null,
        ),
    ],
    HealthSection.exam => <Widget>[
      if (record.exam == null)
        const EmptyState(
          icon: AppIcons.attendance,
          title: StudentsStrings.examTitle,
          subtitle: StudentsStrings.notRecorded,
        )
      else
        DetailFieldsCard(
          title: StudentsStrings.examTitle,
          rows: ProfileFields.exam(record.exam!),
          onEdit: state.canEditHealth ? () => _soon(context) : null,
        ),
    ],
    HealthSection.immunization => _immunization(),
  };

  List<Widget> _immunization() {
    final overdue = record.overdueImmunization;
    return <Widget>[
      if (overdue != null) ...<Widget>[
        InlineAlert(
          message: StudentsStrings.immunizationOverdue(
            overdue.name,
            overdue.dueDateLabel ?? '',
          ),
        ),
        const SizedBox(height: AppSizes.cardGap),
      ],
      for (final record in record.immunizations)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
          child: ImmunizationRow(record: record),
        ),
    ];
  }

  // --- Attendance -----------------------------------------------------------

  List<Widget> _attendance(BuildContext context) {
    final month = record.attendance;
    return <Widget>[
      SectionEyebrow(
        label: month.name,
        color: context.colours.student,
        meta: StudentsStrings.attendanceSummary(
          month.daysIn,
          month.absent,
          month.hours,
        ),
      ),
      const SizedBox(height: AppSizes.sectionGap),
      for (final day in month.days)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
          child: AttendanceDayRow(day: day, initials: record.student.initials),
        ),
    ];
  }

  // --- Dates ----------------------------------------------------------------

  List<Widget> _dates(BuildContext context) => <Widget>[
    DetailFieldsCard(
      title: StudentsStrings.datesTitle,
      rows: ProfileFields.dates(record.dates, record.student.classroomName),
      onEdit: state.canWrite ? () => _soon(context) : null,
    ),
    const SizedBox(height: AppSizes.cardGap),
    const ProfileNote(
      title: StudentsStrings.datesNoteTitle,
      body: StudentsStrings.datesNoteBody,
    ),
  ];

  // --- Documents ------------------------------------------------------------

  List<Widget> _documents(BuildContext context) => <Widget>[
    for (final document in record.documents)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
        child: DocumentRow(document: document, onTap: () => _soon(context)),
      ),
    if (record.documents.isEmpty)
      const Padding(
        padding: EdgeInsets.only(bottom: AppSizes.cardGap),
        child: EmptyState(
          icon: AppIcons.fileText,
          title: StudentsStrings.noDocuments,
        ),
      ),
    Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
      child: DashedAddRow(
        label: StudentsStrings.addDocument,
        onTap: () => unawaited(
          context.push<void>(
            AppRoutes.studentDocuments(state.studentId),
            // The record already knows who this is, so the Documents screen
            // does not have to fetch it again.
            extra: StudentDocumentsArgs(
              studentId: state.studentId,
              studentName: record.student.fullName,
              classroomName: record.student.classroomName,
            ),
          ),
        ),
      ),
    ),
    _note(context, StudentsStrings.documentsParentNote),
  ];

  // --- Odds and ends --------------------------------------------------------

  Widget _note(BuildContext context, String text) => Text(
    text,
    style: StudentsTextStyles.itemSub.copyWith(color: context.colours.ink3),
  );

  void _soon(BuildContext context) =>
      showAppToast(context, StudentsStrings.editSectionSoon);

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<StudentProfileCubit>();
    await context.push<void>(AppRoutes.editStudent(state.studentId));
    await cubit.load(isSilent: true);
  }
}
