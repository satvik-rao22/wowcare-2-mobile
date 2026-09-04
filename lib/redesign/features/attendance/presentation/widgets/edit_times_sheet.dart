import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_date_field.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_time_field.dart';

/// What Edit times came back with.
@immutable
class EditTimesDraft {
  const EditTimesDraft({required this.at, required this.isSignOut});

  final DateTime at;

  /// Which of the two recorded times this replaces.
  final bool isSignOut;
}

/// Correcting a recorded time (4a's record sheet).
///
/// The same two fields as the sign-in form, because it is the same pair of
/// values. Editing the last recorded time is what an Admin does when somebody
/// was signed in late; it leaves an audit note with their name on it.
class EditTimesSheet extends StatefulWidget {
  const EditTimesSheet({
    required this.record,
    required this.date,
    required this.today,
    super.key,
  });

  final AttendanceRecord record;
  final DateTime date;
  final DateTime today;

  static Future<EditTimesDraft?> show(
    BuildContext context, {
    required AttendanceRecord record,
    required DateTime date,
    required DateTime today,
  }) => showAppSheet<EditTimesDraft>(
    context,
    builder: (_) => EditTimesSheet(record: record, date: date, today: today),
  );

  @override
  State<EditTimesSheet> createState() => _EditTimesSheetState();
}

class _EditTimesSheetState extends State<EditTimesSheet> {
  late final bool _isSignOut = widget.record.signedOutTime != null;
  late DateTime _date = widget.date;
  late ClockTime _time =
      (_isSignOut ? widget.record.signedOutTime : widget.record.signedInTime) ??
      ClockTime.fromDateTime(widget.today);

  void _submit() {
    Navigator.of(context).pop<EditTimesDraft>(
      EditTimesDraft(
        at: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        isSignOut: _isSignOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: AttendanceStrings.editTimesTitle,
    subtitle: _isSignOut
        ? '${widget.record.fullName} · ${AppStrings.signedOut}'
        : '${widget.record.fullName} · ${AppStrings.signedIn}',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.sheetGap,
      children: <Widget>[
        AttendanceDateField(
          label: AttendanceStrings.dateLabel,
          value: _date,
          today: widget.today,
          onChanged: (picked) => setState(() => _date = picked),
        ),
        AttendanceTimeField(
          label: AttendanceStrings.timeLabel,
          value: _time,
          onChanged: (picked) => setState(() => _time = picked),
        ),
        Text(
          AttendanceStrings.editTimesNote,
          style: AttendanceTextStyles.footnote.copyWith(
            color: context.colours.ink3,
          ),
        ),
      ],
    ),
    footer: <Widget>[PrimaryKey(label: AppStrings.save, onTap: _submit)],
  );
}
