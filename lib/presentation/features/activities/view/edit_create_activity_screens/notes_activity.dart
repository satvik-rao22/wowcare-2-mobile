import 'package:flutter/material.dart';

import '../activity_daily_tab.dart';
import 'note_style_activity_config.dart';
import 'note_style_activity_screen.dart';

/// Notes create / view / edit form.
///
/// The implementation lives in [NoteStyleActivityScreen] and is shared with
/// Observation — the two activities take the same input and follow the same
/// permission, approval and attendance rules. Only the pieces held in
/// [NoteStyleActivityConfig] differ.
class NotesActivityScreen extends StatelessWidget {
  const NotesActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    this.activityData,
    this.readOnly = false,
  });

  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => NoteStyleActivityScreen(
    config: NoteStyleActivityConfig.notes,
    selectedStudents: selectedStudents,
    isEdit: isEdit,
    activityData: activityData,
    readOnly: readOnly,
  );
}
