import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class SimpleTimePickerField extends StatelessWidget {
  const SimpleTimePickerField({
    super.key,
    this.time,
    this.placeholder,
    required this.onTimeSelected,
  });

  /// Currently selected time. If null, the field shows [placeholder] instead
  /// and the time picker will default to the current time.
  final TimeOfDay? time;

  /// Optional placeholder text to show when [time] is null.
  final String? placeholder;

  final ValueChanged<TimeOfDay> onTimeSelected;

  String _formatTime12h(TimeOfDay time) {
    final hour24 = time.hour;
    final minute = time.minute;
    final isPm = hour24 >= 12;
    final hour12 = (hour24 % 12) == 0 ? 12 : (hour24 % 12);
    final minutePadded = minute.toString().padLeft(2, '0');
    return '$hour12:$minutePadded ${isPm ? 'PM' : 'AM'}';
  }

  Future<TimeOfDay> _defaultPickerTime() async {
    if (time != null) return time!;
    try {
      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
            storage: serviceLocator<StorageService>(),
            apiClient: serviceLocator<ApiClient>(),
          );
      final dt = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
        schoolTimeZone,
      );
      return dt.$2;
    } catch (_) {
      return ServerTimeService.instance.timeOfDayNow();
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final initialTime = await _defaultPickerTime();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && picked != time) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: AppSurfaces.well(radius: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.value(
              time != null
                  ? _formatTime12h(time!)
                  : (placeholder ?? 'Select time'),
            ),
            AppIcon(MediaRes.clock_icon),
          ],
        ),
      ),
    );
  }
}
