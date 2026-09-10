// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:wowcare/core/theme/app_colors.dart';
// import 'package:wowcare/core/theme/app_media_res.dart';
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
//             color: AppPalette.textPrimary,
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
//               border: Border.all(color: AppPalette.textMuted),
//               borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     _formatTime(time),
//                     style: const TextStyle(
//                       color: AppPalette.textPrimary,
//                       fontSize: 15,
//                       fontFamily: 'Manrope',
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 SvgPicture.asset(
//                   MediaRes.clock_icon,
//                   height: responsive.isTablet ? 20.0 : 18.0,
//                   colorFilter: const ColorFilter.mode(AppPalette.textPrimary, BlendMode.srcIn),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_icon.dart';

class GradientTimePickerField extends StatelessWidget {
  const GradientTimePickerField({
    super.key,
    this.label,
    required this.time,
    required this.onTimeSelected,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.onClear,
    this.minuteInterval,
  });

  /// Optional in-field label rendered above the picker. When null or empty,
  /// no label row is drawn — useful where the caller already renders its own
  /// label (e.g. the attendance forms use `AppText.label('Time')`).
  final String? label;
  final String? errorText;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final bool isRequired;

  /// When false, the field is greyed out and taps are ignored (read-only).
  /// Mirrors the disabled state the activity screens drove via `isEditable`.
  final bool enabled;

  /// Optional clear callback. When non-null and [time] is set, a small
  /// close (×) button is rendered next to the clock icon — gives mobile users
  /// the same affordance the web build gets from pressing backspace inside
  /// the input.
  final VoidCallback? onClear;

  /// When set (e.g. 15), the field opens a wheel picker that only allows
  /// minutes in multiples of this value (00/15/30/45 for 15) — the restriction
  /// is enforced in the picker UI, so off-interval minutes can't be chosen.
  /// When null (the default), the normal themed clock picker is used.
  final int? minuteInterval;

  String _formatHourMinute(TimeOfDay? t) {
    if (t == null) return 'hh:mm AM';

    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;

    final minute = t.minute.toString().padLeft(2, '0');

    final period = t.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _pickTime(BuildContext context) async {
    // Interval-restricted mode: minutes are limited to multiples of
    // [minuteInterval] directly in the picker UI (a wheel picker).
    if (minuteInterval != null) {
      return _pickTimeRestricted(context);
    }

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
                primary: AppPalette.brand,
                secondary: AppPalette.brand,
                onPrimary: AppPalette.onBrand,
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

  /// Wheel picker whose minute column only shows multiples of [minuteInterval]
  /// (e.g. 00/15/30/45). The restriction is enforced by the picker itself, so a
  /// user can never land on an off-interval minute.
  Future<void> _pickTimeRestricted(BuildContext context) async {
    final interval = minuteInterval!;
    final now = time ?? const TimeOfDay(hour: 9, minute: 0);
    // The wheel's initial minute must already be a valid multiple.
    final snappedMinute = (now.minute ~/ interval) * interval;
    var selected = DateTime(2020, 1, 1, now.hour, snappedMinute);

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const Text(
                        'Select time',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(
                          TimeOfDay(
                            hour: selected.hour,
                            minute: selected.minute,
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontWeight: FontWeight.w700,
                            color: AppColors.themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    minuteInterval: interval,
                    use24hFormat: false,
                    initialDateTime: selected,
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) onTimeSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    final hasLabel = label != null && label!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: MaterialHues.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        GestureDetector(
          onTap: enabled ? () => _pickTime(context) : null,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Container(
              constraints: BoxConstraints(
                minHeight: responsive.inputFieldHeight,
              ),

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
                    child: Text(
                      _formatHourMinute(time),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 15,
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  if (onClear != null && time != null && enabled) ...[
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
                  AppIcon(
                    MediaRes.clock_icon,
                    height: responsive.isTablet ? 20.0 : 18.0,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              color: MaterialHues.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.body,
            ),
          ),
        ],
      ],
    );
  }
}
