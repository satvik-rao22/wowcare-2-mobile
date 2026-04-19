import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Resolves which student rows to PATCH when saving an edit.
///
/// [checkedIndices] empty → all rows in [allStudentMaps]. Non-empty → only
/// those indices (each map should include `activityCode` when available).
List<Map<String, dynamic>> studentMapsForScopedActivityUpdate({
  required List<Map<String, dynamic>> allStudentMaps,
  required Set<int> checkedIndices,
}) {
  if (allStudentMaps.length <= 1) {
    return List<Map<String, dynamic>>.from(allStudentMaps);
  }
  if (checkedIndices.isEmpty) {
    return List<Map<String, dynamic>>.from(allStudentMaps);
  }
  final out = <Map<String, dynamic>>[];
  for (final i in checkedIndices) {
    if (i >= 0 && i < allStudentMaps.length) {
      out.add(allStudentMaps[i]);
    }
  }
  return out;
}

/// When [studentNames.length] > 1 in edit mode: optional checkboxes to limit save
/// to specific students. **All unchecked** = apply changes to **every** student
/// (each underlying activity row). **Any checked** = only those rows are updated.
class ActivityEditStudentScopeCheckboxes extends StatelessWidget {
  const ActivityEditStudentScopeCheckboxes({
    super.key,
    required this.studentNames,
    required this.checkedIndices,
    required this.onChanged,
  });

  final List<String> studentNames;
  final Set<int> checkedIndices;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply changes to (leave all unchecked to update every student):',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(studentNames.length, (i) {
          final n = studentNames[i].trim().isEmpty ? 'Student' : studentNames[i];
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: checkedIndices.contains(i),
            onChanged: (v) {
              final next = Set<int>.from(checkedIndices);
              if (v == true) {
                next.add(i);
              } else {
                next.remove(i);
              }
              onChanged(next);
            },
            title: Text(
              n,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xff573353),
              ),
            ),
          );
        }),
      ],
    );
  }
}
