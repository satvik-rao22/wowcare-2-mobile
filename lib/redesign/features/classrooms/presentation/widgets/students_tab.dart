import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_state_view.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/dashed_panel.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/filter_key.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/roster_row.dart';

/// The classroom's roster (7c's first tab, and the only list a teacher gets
/// on 7e): search, the two quick toggles, the filter sheet's results, and the
/// rows themselves.
///
/// The empty states are 7j's: nobody on the roll at all is one screen, and a
/// search that found nobody is another.
class StudentsTab extends StatelessWidget {
  const StudentsTab({
    required this.state,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onOpenFilters,
    required this.onToggleSignedIn,
    required this.onToggleNapping,
    required this.onToggleRow,
    required this.onToggleSelected,
    required this.onAssignStudents,
    required this.onOpenStudent,
    required this.onMoreActions,
    super.key,
  });

  final ClassroomState state;
  final TextEditingController searchController;

  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;
  final VoidCallback onToggleSignedIn;
  final VoidCallback onToggleNapping;

  final ValueChanged<RosterStudent> onToggleRow;
  final ValueChanged<RosterStudent> onToggleSelected;
  final VoidCallback? onAssignStudents;
  final ValueChanged<RosterStudent> onOpenStudent;
  final ValueChanged<RosterStudent> onMoreActions;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    if (detail == null) return const SizedBox.shrink();

    if (state.hasNoStudents) {
      // A role that may look but not change gets 7j's view-only screen
      // rather than a key it could never press.
      return onAssignStudents == null
          ? const ClassroomStateView.viewOnly()
          : ClassroomStateView.noStudents(
              classroomName: detail.summary.name,
              places: detail.summary.capacity,
              unassigned: 0,
              onAssign: onAssignStudents,
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ClassroomsSizes.toolbarGap,
      children: <Widget>[
        SearchField(
          controller: searchController,
          hintText: ClassroomsStrings.searchThisClassroom,
          onChanged: onSearch,
          onClear: onClearSearch,
        ),
        _toggles(context, detail),
        _showingLine(context),
        if (state.hasNoStudentMatches)
          _noMatches(detail)
        else
          for (final student in state.visibleStudents)
            RosterRow(
              student: student,
              isExpanded: state.expandedId == student.id,
              isSelectMode: state.isSelectMode,
              isSelected: state.selectedIds.contains(student.id),
              isLocked: state.isLocked,
              onTap: () => state.isSelectMode
                  ? onToggleSelected(student)
                  : onToggleRow(student),
              onOpenProfile: () => onOpenStudent(student),
              onMoreActions: () => onMoreActions(student),
            ),
      ],
    );
  }

  /// The two toggles scroll past the Filter key rather than pushing it off
  /// the screen, which is what a long label would otherwise do.
  Widget _toggles(BuildContext context, ClassroomDetail detail) => Row(
    spacing: ClassroomsSizes.chipGap,
    children: <Widget>[
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: ClassroomsSizes.chipGap,
            children: <Widget>[
              AppChip(
                label: ClassroomsStrings.signedInChip(detail.signedInCount),
                selected: state.studentFilters.signedInOnly,
                onTap: onToggleSignedIn,
              ),
              AppChip(
                label: ClassroomsStrings.nappingChip(detail.nappingCount),
                selected: state.studentFilters.nappingOnly,
                onTap: onToggleNapping,
              ),
            ],
          ),
        ),
      ),
      FilterKey(onTap: onOpenFilters, isActive: !state.studentFilters.isClear),
    ],
  );

  Widget _showingLine(BuildContext context) {
    final shown = state.visibleStudents.length;
    final total = state.totalStudents;

    return Text(
      shown == total
          ? ClassroomsStrings.showingAll(total)
          : ClassroomsStrings.showingOf(shown, total),
      style: ClassroomsTextStyles.showingLine.copyWith(
        color: context.colours.ink3,
      ),
    );
  }

  Widget _noMatches(ClassroomDetail detail) {
    if (state.isSearching) {
      return ClassroomStateView.noResults(
        query: state.query.trim(),
        classroomName: detail.summary.name,
        onClearSearch: onClearSearch,
      );
    }
    return DashedPanel(
      title: ClassroomsStrings.nobodyMatches,
      message: ClassroomsStrings.turnToggleOff(state.totalStudents),
      padding: ClassroomsSizes.inlineEmptyPad,
    );
  }
}
