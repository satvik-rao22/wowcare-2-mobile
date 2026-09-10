import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

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
    this.dividerColor = const Color(0xFFA1DA79)
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming move',
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: Color(0x8041414E),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF41414E),
                    fontFamily: AppFonts.body
                  ),


                )
              ],
            ),
            const SizedBox(width: 12,),
            Container(
              width: 2,
              height: 25,
              color: dividerColor,
            ),
            const SizedBox(width: 16,),
            Text(
              currentClass,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.03 * 16,
                color: Color(0xFF41414E)
              ),
            ),
            const SizedBox(width: 16,),
            Icon(
              Icons.arrow_forward,
              color: const Color(0xFF1D1B20),
              size: 20,
            ),
            const SizedBox(width: 16,),
            Text(
              nextClass,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: -0.03 * 16,
                  color: Color(0xFF41414E)
              ),
            ),
          ],
        )

      ],
    );
  }
}
