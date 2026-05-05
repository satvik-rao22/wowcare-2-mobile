import 'package:flutter/material.dart';
import '../model/staff_model.dart';

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
                Text("${staff.workedHours}h | ${staff.totalHours}h"),
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
}
