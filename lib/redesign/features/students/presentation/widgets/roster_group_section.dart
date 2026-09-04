import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_roster_row.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// One classroom's slice of the roster, under a teal eyebrow that carries
/// today's tally (5a).
///
/// The tally costs nothing: every student in the group already knows their
/// own status, so the header is a count of what is on screen rather than a
/// second fetch.
class RosterGroupSection extends StatelessWidget {
  const RosterGroupSection({
    required this.group,
    required this.expandedId,
    required this.onToggle,
    this.title,
    this.canWrite = false,
    this.isSelectMode = false,
    this.selectedIds = const <String>{},
    this.onOpenProfile,
    this.onMoreActions,
    super.key,
  });

  final RosterGroup group;

  /// Overrides the classroom name: a staff member's own group says so.
  final String? title;

  final String? expandedId;
  final ValueChanged<StudentSummary> onToggle;

  final bool canWrite;
  final bool isSelectMode;
  final Set<String> selectedIds;

  final ValueChanged<StudentSummary>? onOpenProfile;
  final ValueChanged<StudentSummary>? onMoreActions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSizes.sectionGap,
    children: <Widget>[
      SectionEyebrow(
        label: title ?? group.classroomName,
        color: context.colours.student,
        meta: StudentsStrings.groupMeta(
          students: group.students.length,
          signedIn: group.signedIn,
          signedOut: group.signedOut,
          absent: group.absent,
          notMarked: group.notMarked,
        ),
      ),
      for (final student in group.students)
        Padding(
          padding: const EdgeInsets.only(bottom: StudentsSizes.rowGap),
          child: StudentRosterRow(
            student: student,
            isExpanded: student.id == expandedId,
            canWrite: canWrite,
            isSelectMode: isSelectMode,
            isSelected: selectedIds.contains(student.id),
            onTap: () => onToggle(student),
            onOpenProfile: onOpenProfile == null
                ? null
                : () => onOpenProfile!(student),
            onMoreActions: onMoreActions == null
                ? null
                : () => onMoreActions!(student),
          ),
        ),
    ],
  );
}
