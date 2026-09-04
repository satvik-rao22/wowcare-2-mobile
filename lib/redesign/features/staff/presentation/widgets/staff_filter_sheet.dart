import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/choice_row.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6b. Status is pick-one and Order is pick-one; everything between them is a
/// set of chips that narrows the list.
///
/// The working set lives in this sheet until Apply, so nothing is written
/// back while it is open and Cancel is simply a dismiss.
class StaffFilterSheet extends StatefulWidget {
  const StaffFilterSheet({
    required this.filters,
    required this.designations,
    required this.classrooms,
    required this.designationCounts,
    required this.attendanceCounts,
    super.key,
  });

  final StaffFilters filters;
  final List<String> designations;
  final List<String> classrooms;

  /// How many staff hold each designation, at the status that is picked.
  final Map<String, int> designationCounts;

  /// How many are in each attendance state, at the status that is picked.
  final Map<AttendanceStatus, int> attendanceCounts;

  static Future<StaffFilters?> show(
    BuildContext context, {
    required StaffFilters filters,
    required List<String> designations,
    required List<String> classrooms,
    required Map<String, int> designationCounts,
    required Map<AttendanceStatus, int> attendanceCounts,
  }) => showAppSheet<StaffFilters>(
    context,
    builder: (_) => StaffFilterSheet(
      filters: filters,
      designations: designations,
      classrooms: classrooms,
      designationCounts: designationCounts,
      attendanceCounts: attendanceCounts,
    ),
  );

  @override
  State<StaffFilterSheet> createState() => _StaffFilterSheetState();
}

class _StaffFilterSheetState extends State<StaffFilterSheet> {
  late StaffFilters _working = widget.filters;

  static const List<StaffStatus> _statuses = StaffStatus.values;
  static const List<AttendanceStatus> _attendance = AttendanceStatus.values;

  /// Flip [value] in [current], and hand the new set back to [write] so the
  /// caller decides which group of the filters it belongs to.
  void _toggle<T>(
    Set<T> current,
    T value,
    StaffFilters Function(Set<T> next) write,
  ) => setState(() {
    final next = <T>{...current};
    if (!next.remove(value)) next.add(value);
    _working = write(next);
  });

  void _clearAll() => setState(() => _working = const StaffFilters());

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: StaffStrings.filterTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StaffSizes.filterSectionGap,
          children: <Widget>[
            _group(
              StaffStrings.statusPickOne,
              ChoiceRow(
                labels: <String>[
                  for (final status in _statuses)
                    StaffStrings.statusLabel(status),
                ],
                selectedIndex: _statuses.indexOf(_working.status),
                onSelect: (index) => setState(
                  () => _working = _working.copyWith(status: _statuses[index]),
                ),
              ),
            ),
            if (widget.designations.isNotEmpty)
              _group(
                StaffStrings.designation,
                _chips(<Widget>[
                  for (final designation in widget.designations)
                    AppChip(
                      label: StaffStrings.countedLabel(
                        designation,
                        widget.designationCounts[designation] ?? 0,
                      ),
                      selected: _working.designations.contains(designation),
                      onTap: () => _toggle(
                        _working.designations,
                        designation,
                        (next) => _working.copyWith(designations: next),
                      ),
                    ),
                ]),
              ),
            _group(
              StaffStrings.primaryClassroomSection,
              _chips(<Widget>[
                for (final classroom in widget.classrooms)
                  AppChip(
                    label: classroom,
                    selected: _working.primaryClassrooms.contains(classroom),
                    onTap: () => _toggle(
                      _working.primaryClassrooms,
                      classroom,
                      (next) => _working.copyWith(primaryClassrooms: next),
                    ),
                  ),
              ]),
            ),
            _group(
              StaffStrings.allowedInSection,
              _chips(<Widget>[
                for (final classroom in widget.classrooms)
                  AppChip(
                    label: classroom,
                    selected: _working.allowedIn.contains(classroom),
                    onTap: () => _toggle(
                      _working.allowedIn,
                      classroom,
                      (next) => _working.copyWith(allowedIn: next),
                    ),
                  ),
              ]),
              note: StaffStrings.classroomNote,
            ),
            _group(
              StaffStrings.attendanceToday,
              _chips(<Widget>[
                for (final status in _attendance)
                  AppChip(
                    label: StaffStrings.countedLabel(
                      StaffStrings.attendanceLabel(status),
                      widget.attendanceCounts[status] ?? 0,
                    ),
                    selected: _working.attendance.contains(status),
                    onTap: () => _toggle(
                      _working.attendance,
                      status,
                      (next) => _working.copyWith(attendance: next),
                    ),
                  ),
              ]),
            ),
            _group(
              StaffStrings.order,
              ChoiceRow(
                labels: const <String>[StaffStrings.aToZ, StaffStrings.zToA],
                selectedIndex: _working.order == StaffOrder.aToZ ? 0 : 1,
                onSelect: (index) => setState(
                  () => _working = _working.copyWith(
                    order: index == 0 ? StaffOrder.aToZ : StaffOrder.zToA,
                  ),
                ),
              ),
            ),
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
  }

  Widget _group(String eyebrow, Widget body, {String? note}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StaffSizes.filterOptionGap,
    children: <Widget>[
      SectionEyebrow(label: eyebrow),
      body,
      if (note != null)
        Text(
          note,
          style: StaffTextStyles.sheetNote.copyWith(
            color: context.colours.ink3,
          ),
        ),
    ],
  );

  Widget _chips(List<Widget> chips) => Wrap(
    spacing: StaffSizes.chipWrapGap,
    runSpacing: StaffSizes.chipWrapGap,
    children: chips,
  );
}
