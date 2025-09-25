import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class MessageDateSeperatorRow extends StatelessWidget {
  const MessageDateSeperatorRow({
    super.key,
    required this.timeStamp,
  });
  final String timeStamp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeStamp,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
