// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:wowcare/app/theme/colors.dart';
// import 'package:wowcare/app/theme/media_res.dart';
// import 'package:wowcare/shared/utils/responsive_helper.dart';

// class GradientTimePickerField extends StatelessWidget {
//   const GradientTimePickerField({
//     super.key,
//     required this.label,
//     required this.time,
//     required this.onTimeSelected,
//   });

//   final String label;
//   final TimeOfDay? time;
//   final ValueChanged<TimeOfDay> onTimeSelected;

//   String _formatTime(TimeOfDay? t) {
//     if (t == null) return 'hh:mm AM';
//     final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
//     final period = t.period == DayPeriod.am ? 'AM' : 'PM';
//     final minute = t.minute.toString().padLeft(2, '0');
//     return '$hour:$minute $period';
//   }

//   Future<void> _pickTime(BuildContext context) async {
//     final initial = time ?? const TimeOfDay(hour: 9, minute: 0);
//     try {
//       final picked = await showTimePicker(
//         context: context,
//         initialTime: initial,
//         builder: (context, child) {
//           final theme = Theme.of(context);
//           return Theme(
//             data: theme.copyWith(
//               timePickerTheme: const TimePickerThemeData(
//                 dialHandColor: Colors.white,
//               ),
//               colorScheme: theme.colorScheme.copyWith(
//                 primary: AppColors.primaryColor,
//                 secondary: AppColors.primaryColor,
//               ),
//             ),
//             child: child!,
//           );
//         },
//       );
//       if (picked != null) {
//         onTimeSelected(picked);
//       }
//     } catch (_) {}
//   }

//   @override
//   Widget build(BuildContext context) {
//     final responsive = ResponsiveHelper(context);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontFamily: 'Manrope',
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Color(0xff573353),
//           ),
//         ),
//         const SizedBox(height: 6),
//         GestureDetector(
//           onTap: () => _pickTime(context),
//           child: Container(
//             constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
//             padding: EdgeInsets.symmetric(
//               horizontal: responsive.isTablet ? 16.0 : 12.0,
//               vertical: responsive.isTablet ? 16.0 : 12.0,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border.all(color: const Color(0x66573353)),
//               borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     _formatTime(time),
//                     style: const TextStyle(
//                       color: Color(0xff573353),
//                       fontSize: 15,
//                       fontFamily: 'Manrope',
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 SvgPicture.asset(
//                   MediaRes.clock_icon,
//                   height: responsive.isTablet ? 20.0 : 18.0,
//                   colorFilter: const ColorFilter.mode(Color(0xff573353), BlendMode.srcIn),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class GradientTimePickerField extends StatelessWidget {
  const GradientTimePickerField({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeSelected,
    this.errorText,
    this.isRequired = false,
    this.onClear,
  });

  final String label;
  final String? errorText;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final bool isRequired;

  /// Optional clear callback. When non-null and [time] is set, a small
  /// close (×) button is rendered next to the clock icon — gives mobile users
  /// the same affordance the web build gets from pressing backspace inside
  /// the input.
  final VoidCallback? onClear;

  String _formatHourMinute(TimeOfDay? t) {
    if (t == null) return 'hh:mm AM';

    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;

    final minute = t.minute.toString().padLeft(2, '0');

    final period = t.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _pickTime(BuildContext context) async {
    final initial = time ?? const TimeOfDay(hour: 9, minute: 0);

    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
        builder: (context, child) {
          final theme = Theme.of(context);

          return Theme(
            data: theme.copyWith(
              timePickerTheme: TimePickerThemeData(
                dialHandColor: AppColors.themeColor,

                hourMinuteTextColor: AppColors.primaryColor,

                hourMinuteColor: AppColors.themeColor.withValues(alpha: 0.15),

                dayPeriodColor: AppColors.themeColor.withValues(alpha: 0.15),

                dayPeriodTextColor: AppColors.primaryColor,

                dayPeriodBorderSide: const BorderSide(
                  color: AppColors.themeColor,
                ),

                dialBackgroundColor: AppColors.fieldBackgroundColor,

                backgroundColor: AppColors.cardColor,

                entryModeIconColor: AppColors.themeColor,
              ),

              colorScheme: theme.colorScheme.copyWith(
                primary: AppColors.themeColor,
                secondary: AppColors.themeColor,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        onTimeSelected(picked);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        GestureDetector(
          onTap: () => _pickTime(context),
          child: Container(
            constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),

            padding: EdgeInsets.symmetric(
              horizontal: responsive.isTablet ? 16.0 : 12.0,
              vertical: responsive.isTablet ? 16.0 : 12.0,
            ),

            decoration: BoxDecoration(
              color: AppColors.fieldBackgroundColor,
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 12.0 : 8.0,
              ),
            ),

            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        _formatHourMinute(time),
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 15,
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 10,
                      //     vertical: 4,
                      //   ),

                      //   decoration: BoxDecoration(
                      //     color: AppColors.themeColor,

                      //     borderRadius: BorderRadius.circular(6),
                      //   ),

                      //   child: Text(
                      //     _formatPeriod(time),

                      //     style: const TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 11,
                      //       fontFamily: 'Manrope',
                      //       fontWeight: FontWeight.w700,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),

                if (onClear != null && time != null) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Icon(
                        Icons.close,
                        size: responsive.isTablet ? 20.0 : 18.0,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                SvgPicture.asset(
                  MediaRes.clock_icon,

                  height: responsive.isTablet ? 20.0 : 18.0,

                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ],
    );
  }
}