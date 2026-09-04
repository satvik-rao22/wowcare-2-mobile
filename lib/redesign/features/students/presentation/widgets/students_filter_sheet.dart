import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/attendance_label.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/choice_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/multi_select_dropdown.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/students_filter_chip.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// 5b. The filter, over the list.
///
/// Five sections in the order the roster narrows: the one status it can be,
/// then the classrooms, the tags, the parents and today's attendance. Every
/// multi-select carries Select all; Clear all resets the lot. Nothing is
/// applied until Apply, so a half-built filter never disturbs the list
/// underneath.
class StudentsFilterSheet extends StatefulWidget {
  const StudentsFilterSheet({
    required this.filter,
    required this.classroomNames,
    required this.tagNames,
    required this.guardianNames,
    required this.activeCount,
    required this.upcomingCount,
    required this.attendanceCounts,
    super.key,
  });

  final StudentFilter filter;
  final List<String> classroomNames;
  final List<String> tagNames;
  final List<String> guardianNames;
  final int activeCount;
  final int upcomingCount;
  final Map<AttendanceStatus, int> attendanceCounts;

  /// Resolves to the filter to apply, or null when the sheet is dismissed.
  static Future<StudentFilter?> show(
    BuildContext context, {
    required StudentFilter filter,
    required List<String> classroomNames,
    required List<String> tagNames,
    required List<String> guardianNames,
    required int activeCount,
    required int upcomingCount,
    required Map<AttendanceStatus, int> attendanceCounts,
  }) => showAppSheet<StudentFilter>(
    context,
    builder: (_) => StudentsFilterSheet(
      filter: filter,
      classroomNames: classroomNames,
      tagNames: tagNames,
      guardianNames: guardianNames,
      activeCount: activeCount,
      upcomingCount: upcomingCount,
      attendanceCounts: attendanceCounts,
    ),
  );

  @override
  State<StudentsFilterSheet> createState() => _StudentsFilterSheetState();
}

class _StudentsFilterSheetState extends State<StudentsFilterSheet> {
  late StudentFilter _filter = widget.filter;
  String _guardianQuery = '';

  void _set(StudentFilter filter) => setState(() => _filter = filter);

  Set<T> _toggled<T>(Set<T> current, T value) {
    final next = <T>{...current};
    if (!next.remove(value)) next.add(value);
    return next;
  }

  List<String> get _guardianMatches {
    final term = _guardianQuery.trim().toLowerCase();
    if (term.isEmpty) return const <String>[];
    return <String>[
      for (final name in widget.guardianNames)
        if (name.toLowerCase().contains(term) &&
            !_filter.guardians.contains(name))
          name,
    ];
  }

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: StudentsStrings.filterTitle,
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudentsSizes.filterSectionGap,
        children: <Widget>[
          _status(),
          _classrooms(),
          _tags(),
          _guardians(),
          _attendance(),
        ],
      ),
    ),
    footer: <Widget>[
      Row(
        spacing: AppSizes.sheetFooterGap,
        children: <Widget>[
          Expanded(
            flex: StudentsSizes.filterClearFlex,
            child: SecondaryKey(
              label: AppStrings.clearAll,
              onTap: () => _set(const StudentFilter()),
            ),
          ),
          Expanded(
            flex: StudentsSizes.filterApplyFlex,
            child: PrimaryKey(
              label: AppStrings.apply,
              onTap: () => Navigator.of(context).pop(_filter),
            ),
          ),
        ],
      ),
    ],
  );

  // --- Sections -------------------------------------------------------------

  Widget _section({
    required String eyebrow,
    required Widget child,
    Widget? action,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StudentsSizes.filterOptionGap,
    children: <Widget>[
      SectionEyebrow(label: eyebrow, trailing: action),
      child,
    ],
  );

  Widget _status() => _section(
    eyebrow: StudentsStrings.statusPickOne,
    child: ChoiceRow<StudentStatus>(
      value: _filter.status,
      onChanged: (status) => _set(_filter.copyWith(status: status)),
      choices: <Choice<StudentStatus>>[
        Choice<StudentStatus>(
          value: StudentStatus.active,
          label: StudentsStrings.withCount(
            StudentsStrings.activePill,
            widget.activeCount,
          ),
        ),
        Choice<StudentStatus>(
          value: StudentStatus.upcoming,
          label: StudentsStrings.withCount(
            StudentsStrings.upcomingPill,
            widget.upcomingCount,
          ),
        ),
        const Choice<StudentStatus>(
          value: StudentStatus.inactive,
          label: StudentsStrings.inactivePill,
        ),
      ],
    ),
  );

  Widget _classrooms() {
    final all = _filter.classrooms.length == widget.classroomNames.length;
    return _section(
      eyebrow: StudentsStrings.classroomSection,
      action: TextLink(
        label: all ? AppStrings.clearAll : AppStrings.selectAll,
        color: context.colours.ink2,
        onTap: () => _set(
          _filter.copyWith(
            classrooms: all ? <String>{} : widget.classroomNames.toSet(),
          ),
        ),
      ),
      child: Wrap(
        spacing: StudentsSizes.choiceGap,
        runSpacing: StudentsSizes.choiceGap,
        children: <Widget>[
          for (final name in widget.classroomNames)
            StudentsFilterChip(
              label: name,
              selected: _filter.classrooms.contains(name),
              onTap: () => _set(
                _filter.copyWith(
                  classrooms: _toggled(_filter.classrooms, name),
                ),
              ),
            ),
          StudentsFilterChip(
            label: StudentsStrings.notAssigned,
            selected: _filter.classrooms.contains(StudentsStrings.notAssigned),
            onTap: () => _set(
              _filter.copyWith(
                classrooms: _toggled(
                  _filter.classrooms,
                  StudentsStrings.notAssigned,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tags is a dropdown rather than a row of chips because the school's tag
  /// list is its own, and there are usually more than a screen's worth.
  Widget _tags() {
    final all = _filter.tags.length == widget.tagNames.length;
    return _section(
      eyebrow: StudentsStrings.tagsSection,
      action: TextLink(
        label: all ? AppStrings.clearAll : AppStrings.selectAll,
        color: context.colours.ink2,
        onTap: () => _set(
          _filter.copyWith(tags: all ? <String>{} : widget.tagNames.toSet()),
        ),
      ),
      child: MultiSelectDropdown(
        options: widget.tagNames,
        selected: _filter.tags,
        searchHint: StudentsStrings.searchTags,
        emptySummary: StudentsStrings.anyTag,
        summaryOf: (picked) => picked.length > 2
            ? StudentsStrings.tagsOf(picked.length, widget.tagNames.length)
            : picked.join(', '),
        onChanged: (tags) => _set(_filter.copyWith(tags: tags)),
      ),
    );
  }

  Widget _guardians() => _section(
    eyebrow: StudentsStrings.guardianSection,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StudentsSizes.filterOptionGap,
      children: <Widget>[
        SearchField(
          hintText: StudentsStrings.searchParents,
          onChanged: (q) => setState(() => _guardianQuery = q),
        ),
        if (_guardianMatches.isNotEmpty)
          Wrap(
            spacing: StudentsSizes.choiceGap,
            runSpacing: StudentsSizes.choiceGap,
            children: <Widget>[
              for (final name in _guardianMatches.take(_matchLimit))
                StudentsFilterChip(
                  label: name,
                  onTap: () => _set(
                    _filter.copyWith(
                      guardians: _toggled(_filter.guardians, name),
                    ),
                  ),
                ),
            ],
          ),
        if (_filter.guardians.isNotEmpty)
          Wrap(
            spacing: StudentsSizes.choiceGap,
            runSpacing: StudentsSizes.choiceGap,
            children: <Widget>[
              for (final name in _filter.guardians)
                StudentsFilterChip(
                  label: name,
                  selected: true,
                  onRemove: () => _set(
                    _filter.copyWith(
                      guardians: _toggled(_filter.guardians, name),
                    ),
                  ),
                ),
            ],
          ),
      ],
    ),
  );

  Widget _attendance() => _section(
    eyebrow: StudentsStrings.attendanceSection,
    child: Wrap(
      spacing: StudentsSizes.choiceGap,
      runSpacing: StudentsSizes.choiceGap,
      children: <Widget>[
        for (final status in AttendanceStatus.values)
          StudentsFilterChip(
            label: StudentsStrings.withCount(
              AttendanceLabel.wordFor(status),
              widget.attendanceCounts[status] ?? 0,
            ),
            selected: _filter.attendance.contains(status),
            onTap: () => _set(
              _filter.copyWith(
                attendance: _toggled(_filter.attendance, status),
              ),
            ),
          ),
      ],
    ),
  );

  /// How many parent matches the search offers at once. More than this and
  /// the section stops being a filter and starts being a directory.
  static const int _matchLimit = 6;
}
