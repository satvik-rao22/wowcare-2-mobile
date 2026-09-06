import 'package:flutter/material.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';

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

  // Empty set is the implicit "all selected" state; a full explicit set means
  // the same thing. Both render as Select All + every student checked.
  bool get _isAllSelected {
    return checkedIndices.isEmpty ||
        checkedIndices.length >= studentNames.length;
  }

  void _toggleIndex(int index, bool isChecked) {
    // Materialize the implicit "all selected" (empty) state into an explicit
    // set first, so unchecking one student keeps the rest selected.
    final next = checkedIndices.isEmpty
        ? <int>{for (var k = 0; k < studentNames.length; k++) k}
        : Set<int>.from(checkedIndices);
    if (isChecked) {
      next.add(index);
    } else {
      next.remove(index);
    }
    // Normalize "everything selected" back to empty so it reads as Select All.
    if (next.length >= studentNames.length) {
      onChanged(<int>{});
    } else {
      onChanged(next);
    }
  }

  void _toggleSelectAll(bool isChecked) {
    // Keep existing behavior: empty set means "apply to all students".
    onChanged(<int>{});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleSelectAll(!_isAllSelected),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                CustomCheckbox(
                  value: _isAllSelected,
                  scale: 1.0,
                  onChanged: (v) => _toggleSelectAll(v ?? false),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Select All',
                    style: AppTextStyles.activityBodyValue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: List.generate(studentNames.length, (i) {
                final n = studentNames[i].trim().isEmpty
                    ? 'Student'
                    : studentNames[i];
                final isChecked = _isAllSelected || checkedIndices.contains(i);
                final initials = n
                    .split(RegExp(r'\s+'))
                    .where((e) => e.trim().isNotEmpty)
                    .take(2)
                    .map((e) => e.trim().substring(0, 1).toUpperCase())
                    .join();
                return SizedBox(
                  width: itemWidth,
                  height: 64,
                  child: InkWell(
                    onTap: () => _toggleIndex(i, !isChecked),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.themeColor, width: 1),
                        color: AppColors.cardColor,
                      ),
                      child: Row(
                        children: [
                          CustomCheckbox(
                            value: isChecked,
                            scale: 1.0,
                            onChanged: (v) => _toggleIndex(i, v ?? false),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.themeColor,
                            child: Text(
                              initials.isEmpty ? 'S' : initials,
                              style: AppTextStyles.activitySmallBadgeText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              n,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.activityBodyValue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
