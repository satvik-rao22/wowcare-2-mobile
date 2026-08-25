import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class UpcomingMoveWidget extends StatelessWidget {
  final String month;
  final String day;
  final String currentClass;
  final String nextClass;
  final Color dividerColor;
  const UpcomingMoveWidget({
    super.key,
    required this.month,
    required this.day,
    required this.currentClass,
    required this.nextClass,
    this.dividerColor = const Color(0xFFA1DA79),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming move',
          style: AppTextStyles.title.copyWith(color: Color(0xff573353)),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  month,
                  style: AppTextStyles.body.copyWith(color: Color(0x8041414E)),
                ),
                Text(
                  day,
                  style: AppTextStyles.body.copyWith(color: Color(0xFF41414E)),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(width: 2, height: 25, color: dividerColor),
            const SizedBox(width: 16),
            Text(
              currentClass,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.03 * 16,
                color: Color(0xFF41414E),
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.arrow_forward, color: const Color(0xFF1D1B20), size: 20),
            const SizedBox(width: 16),
            Text(
              nextClass,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.03 * 16,
                color: Color(0xFF41414E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
