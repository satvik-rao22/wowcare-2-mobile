import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
// changed some github settings
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.iconPath,
    required this.label,
  });

  final String iconPath;
  final String label;


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          iconPath,
          height: 30,
          width: 30,

        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}