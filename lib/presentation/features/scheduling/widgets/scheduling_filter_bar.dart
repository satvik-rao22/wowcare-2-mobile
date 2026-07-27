import 'package:flutter/material.dart';

import '../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import 'scheduling_legend.dart';

class SchedulingFilterBar extends StatelessWidget {
  const SchedulingFilterBar({
    super.key,
    required this.classroomNames,
    required this.selectedClassroom,
    required this.onClassroomChanged,
  });

  final List<String> classroomNames;
  final String? selectedClassroom;
  final ValueChanged<String?> onClassroomChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x19162831)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomDropdown(
                  hintText: 'Select Classroom',
                  items: classroomNames,
                  selectedItem: selectedClassroom,
                  fieldHeight: 44,
                  onSelect: onClassroomChanged,
                ),
              ),
              if (selectedClassroom != null) ...[
                const SizedBox(width: 8),
                CustomClearAllChip(
                  label: 'Clear',
                  onTap: () => onClassroomChanged(null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const SchedulingLegend(),
        ],
      ),
    );
  }
}
