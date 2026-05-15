import 'package:flutter/material.dart';
import '../../../../../app/theme/colors.dart';

class LegendWidget extends StatelessWidget {
  const LegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text(
            'Collapse All',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          const VerticalDivider(),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _legendDot(AppColors.colorBox2, 'Under Ratio'),
                  const SizedBox(width: 10),
                  _legendDot(AppColors.colorBox, 'Present'),
                  const SizedBox(width: 10),
                  _legendDot(AppColors.colorBox3, 'Over Ratio'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
