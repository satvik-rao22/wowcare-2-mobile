import 'package:flutter/material.dart';

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
          CustomDropdown(
            hintText: 'Select Classroom',
            items: classroomNames,
            selectedItem: selectedClassroom,
            prependHintAsSelectableItem: true,
            fieldHeight: 44,
            onSelect: onClassroomChanged,
          ),
          const SizedBox(height: 12),
          const SchedulingLegend(),
        ],
      ),
    );
  }
}
