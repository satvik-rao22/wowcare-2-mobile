import 'package:flutter/material.dart';
import '../../../../domain/features/staff_classroom/entities/staff_model.dart';

class StaffItemTile extends StatelessWidget {
  final StaffModel staff;

  const StaffItemTile({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          staff.image,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name),
                const SizedBox(height: 4),
                Text(
                  "${_formatHours(staff.availableHours)}h | ${_formatHours(staff.scheduledHours)}h",
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(staff.shift),
          ),
        ],
      ),
    );
  }

  String _formatHours(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceAll(RegExp(r'\.?0+$'), '');
  }
}
