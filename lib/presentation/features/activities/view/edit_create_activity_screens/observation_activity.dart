import 'package:flutter/material.dart';

import '../activity_daily_tab.dart';
import 'note_style_activity_config.dart';
import 'note_style_activity_screen.dart';

/// Observation create / view / edit form.
///
/// Shares [NoteStyleActivityScreen] with Notes: same fields (date, time, staff
/// present, description, optional photos), same eligibility rules (only
/// signed-in students, staff must be signed in, admins may attribute to another
/// signed-in staff member) and the same admin-approval flow. Visibility and
/// multi-student support come from the classroom activity settings API, so
/// nothing about those rules is hard-coded here.
class ObservationActivityScreen extends StatelessWidget {
  const ObservationActivityScreen({
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
    config: NoteStyleActivityConfig.observation,
    selectedStudents: selectedStudents,
    isEdit: isEdit,
    activityData: activityData,
    readOnly: readOnly,
  );
}
