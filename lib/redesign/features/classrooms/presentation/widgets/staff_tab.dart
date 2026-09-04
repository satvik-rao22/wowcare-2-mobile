import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_state_view.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/filter_key.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/ratio_notice.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/staff_row.dart';

/// Who is in the classroom today (7c's second tab): the ratio said out loud,
/// then the people it counts.
///
/// An Admin's tab only. A teacher never sees it: who else is here is on the
/// classroom's record, and assigning staff is admin work.
class StaffTab extends StatelessWidget {
  const StaffTab({
    required this.state,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onOpenFilters,
    required this.onToggleDutyState,
    super.key,
  });

  final ClassroomState state;
  final TextEditingController searchController;

  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;
  final ValueChanged<StaffDutyState> onToggleDutyState;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    if (detail == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ClassroomsSizes.toolbarGap,
      children: <Widget>[
        SearchField(
          controller: searchController,
          hintText: ClassroomsStrings.searchStaffHere,
          onChanged: onSearch,
          onClear: onClearSearch,
        ),
        _toggles(detail),
        RatioNotice(
          message: _ratioMessage(detail),
          isShort: !detail.summary.isInRatio,
        ),
        if (state.hasNoStaffMatches)
          ClassroomStateView.noResults(
            query: state.query.trim(),
            classroomName: detail.summary.name,
            onClearSearch: onClearSearch,
            isStaff: true,
          )
        else
          for (final person in state.visibleStaff) StaffRow(person: person),
      ],
    );
  }

  /// The two toggles scroll past the Filter key rather than pushing it off
  /// the screen.
  Widget _toggles(ClassroomDetail detail) => Row(
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
                label: ClassroomsStrings.onDutyChip(
                  detail.countOfDuty(StaffDutyState.onDuty),
                ),
                selected: state.staffFilters.dutyStates.contains(
                  StaffDutyState.onDuty,
                ),
                onTap: () => onToggleDutyState(StaffDutyState.onDuty),
              ),
              AppChip(
                label: ClassroomsStrings.onBreakChip(
                  detail.countOfDuty(StaffDutyState.onBreak),
                ),
                selected: state.staffFilters.dutyStates.contains(
                  StaffDutyState.onBreak,
                ),
                onTap: () => onToggleDutyState(StaffDutyState.onBreak),
              ),
            ],
          ),
        ),
      ),
      FilterKey(onTap: onOpenFilters, isActive: !state.staffFilters.isClear),
    ],
  );

  /// The ratio in words. Counts on both sides, and never a figure.
  static String _ratioMessage(ClassroomDetail detail) {
    final summary = detail.summary;
    return summary.isInRatio
        ? ClassroomsStrings.staffForStudents(
            summary.staffPresent,
            summary.studentsPresent,
            detail.staffWanted,
          )
        : ClassroomsStrings.staffShortFor(
            summary.staffPresent,
            summary.studentsPresent,
            summary.staffNeeded,
          );
  }
}
