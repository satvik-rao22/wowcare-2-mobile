import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
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

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromRGBO(249, 245, 250, 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.value(
              time != null
                  ? _formatTime12h(time!)
                  : (placeholder ?? 'Select time'),
            ),
            SvgPicture.asset(MediaRes.clock_icon),
          ],
        ),
      ),
    );
  }
}

