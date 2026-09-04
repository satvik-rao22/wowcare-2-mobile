import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/segmented_control.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_cubit.dart';

/// Students, Staff and Notes over one classroom (7c), each with its own
/// count under the label.
///
/// A teacher gets two of the three (7e): who else is in the classroom is on
/// the classroom's record, and assigning staff is admin work.
class ClassroomTabs extends StatelessWidget {
  const ClassroomTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    required this.studentCount,
    required this.staffCount,
    required this.newNoteCount,
    super.key,
  });

  final List<ClassroomTab> tabs;
  final ClassroomTab selected;
  final ValueChanged<ClassroomTab> onChanged;

  final int studentCount;
  final int staffCount;
  final int newNoteCount;

  @override
  Widget build(BuildContext context) => SegmentedControl(
    segments: <String>[for (final tab in tabs) _label(tab)],
    sublabels: <String>[for (final tab in tabs) _count(tab)],
    index: tabs.indexOf(selected).clamp(0, tabs.length - 1),
    onChanged: (index) => onChanged(tabs[index]),
  );

  static String _label(ClassroomTab tab) => switch (tab) {
    ClassroomTab.students => ClassroomsStrings.tabStudents,
    ClassroomTab.staff => ClassroomsStrings.tabStaff,
    ClassroomTab.notes => ClassroomsStrings.tabNotes,
  };

  String _count(ClassroomTab tab) => switch (tab) {
    ClassroomTab.students => '$studentCount',
    ClassroomTab.staff => '$staffCount',
    ClassroomTab.notes =>
      newNoteCount == 0 ? '' : ClassroomsStrings.newCount(newNoteCount),
  };
}
