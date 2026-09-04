import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/info_well.dart';

/// The same sheet, over a classroom's staff (7d's second half): what they
/// do, and where they are on today's clock.
class StaffFilterSheet extends StatefulWidget {
  const StaffFilterSheet({
    required this.filters,
    required this.designations,
    required this.counts,
    super.key,
  });

  final StaffFilters filters;

  /// Every designation the staff in this classroom hold.
  final List<String> designations;

  /// How many staff are in each duty state right now.
  final Map<StaffDutyState, int> counts;

  static Future<StaffFilters?> show(
    BuildContext context, {
    required StaffFilters filters,
    required List<String> designations,
    required Map<StaffDutyState, int> counts,
  }) => showAppSheet<StaffFilters>(
    context,
    builder: (_) => StaffFilterSheet(
      filters: filters,
      designations: designations,
      counts: counts,
    ),
  );

  @override
  State<StaffFilterSheet> createState() => _StaffFilterSheetState();
}

class _StaffFilterSheetState extends State<StaffFilterSheet> {
  late StaffFilters _working = widget.filters;

  void _toggleDesignation(String designation) => setState(() {
    final next = <String>{..._working.designations};
    if (!next.remove(designation)) next.add(designation);
    _working = _working.copyWith(designations: next);
  });

  void _toggleDutyState(StaffDutyState state) => setState(() {
    final next = <StaffDutyState>{..._working.dutyStates};
    if (!next.remove(state)) next.add(state);
    _working = _working.copyWith(dutyStates: next);
  });

  void _clearAll() => setState(() => _working = const StaffFilters());

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: ClassroomsStrings.filterStaff,
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.sheetGroupGap,
        children: <Widget>[
          if (widget.designations.isNotEmpty)
            _group(ClassroomsStrings.designation, <Widget>[
              for (final designation in widget.designations)
                AppChip(
                  label: designation,
                  selected: _working.designations.contains(designation),
                  onTap: () => _toggleDesignation(designation),
                ),
            ]),
          _group(ClassroomsStrings.onTheClock, <Widget>[
            for (final entry in widget.counts.entries)
              AppChip(
                label: _dutyLabel(entry.key, entry.value),
                selected: _working.dutyStates.contains(entry.key),
                onTap: () => _toggleDutyState(entry.key),
              ),
          ]),
          const InfoWell(message: ClassroomsStrings.staffFilterNote),
        ],
      ),
    ),
    footer: <Widget>[
      SecondaryKey(label: AppStrings.clearAll, onTap: _clearAll),
      PrimaryKey(
        label: AppStrings.apply,
        onTap: () => Navigator.of(context).pop(_working),
      ),
    ],
  );

  Widget _group(String eyebrow, List<Widget> chips) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: ClassroomsSizes.sheetFieldGap,
    children: <Widget>[
      SectionEyebrow(label: eyebrow),
      Wrap(
        spacing: ClassroomsSizes.chipGap,
        runSpacing: ClassroomsSizes.chipGap,
        children: chips,
      ),
    ],
  );

  static String _dutyLabel(StaffDutyState state, int count) => switch (state) {
    StaffDutyState.onDuty => ClassroomsStrings.onDutyChip(count),
    StaffDutyState.onBreak => ClassroomsStrings.onBreakChip(count),
    StaffDutyState.notMarked => ClassroomsStrings.notMarkedChip(count),
    StaffDutyState.absent => ClassroomsStrings.absentChip(count),
    StaffDutyState.signedOut => ClassroomsStrings.signedOutChip(count),
  };
}
