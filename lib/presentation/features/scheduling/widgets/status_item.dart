import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StatusItem extends StatelessWidget {
  final String iconPath;
  final String label;

  const StatusItem({super.key, required this.iconPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 18, height: 18, child: SvgPicture.asset(iconPath)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
