import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_date_field.dart';

/// What Mark Absent came back with.
@immutable
class MarkAbsentDraft {
  const MarkAbsentDraft({required this.date, required this.reason});

  final DateTime date;
  final String reason;
}

/// Mark Absent (4a's record sheet).
///
/// The one action in the module that takes a reason: a sign in and a sign out
/// take a date and a time and nothing else, and an absence has to say why or
/// the classroom lead is left guessing.
class MarkAbsentSheet extends StatefulWidget {
  const MarkAbsentSheet({
    required this.name,
    required this.date,
    required this.today,
    super.key,
  });

  final String name;
  final DateTime date;
  final DateTime today;

  static Future<MarkAbsentDraft?> show(
    BuildContext context, {
    required String name,
    required DateTime date,
    required DateTime today,
  }) => showAppSheet<MarkAbsentDraft>(
    context,
    builder: (_) => MarkAbsentSheet(name: name, date: date, today: today),
  );

  @override
  State<MarkAbsentSheet> createState() => _MarkAbsentSheetState();
}

class _MarkAbsentSheetState extends State<MarkAbsentSheet> {
  final TextEditingController _reason = TextEditingController();
  late DateTime _date = widget.date;
  bool _showError = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(
      context,
    ).pop<MarkAbsentDraft>(MarkAbsentDraft(date: _date, reason: reason));
  }

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: AttendanceStrings.markAbsentTitle,
    subtitle: widget.name,
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
        AppTextField(
          label: AttendanceStrings.reasonLabel,
          isRequired: true,
          hintText: AttendanceStrings.reasonHint,
          controller: _reason,
          maxLines: AttendanceSizes.reasonLines,
          errorText: _showError ? AttendanceStrings.reasonRequired : null,
          onChanged: (_) {
            if (_showError) setState(() => _showError = false);
          },
        ),
      ],
    ),
    footer: <Widget>[
      PrimaryKey(label: AttendanceStrings.markAbsent, onTap: _submit),
    ],
  );
}
