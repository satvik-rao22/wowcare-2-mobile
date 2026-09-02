import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../domain/entities/attendance_day.dart';

/// Result of editing an absence. The admin edits only the absent **date** and
/// **note**; reason/type are carried through from the existing record so the
/// PATCH payload stays complete.
class Av2AbsenceEditResult {
  const Av2AbsenceEditResult({
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.type,
    required this.note,
  });
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String type;
  final String note;
}

Future<Av2AbsenceEditResult?> showAv2EditAbsenceSheet(
  BuildContext context, {
  required AttendanceDay day,
}) {
  return showModalBottomSheet<Av2AbsenceEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (context) => _Av2EditAbsenceSheet(day: day),
  );
}

class _Av2EditAbsenceSheet extends StatefulWidget {
  const _Av2EditAbsenceSheet({required this.day});
  final AttendanceDay day;

  @override
  State<_Av2EditAbsenceSheet> createState() => _Av2EditAbsenceSheetState();
}

class _Av2EditAbsenceSheetState extends State<_Av2EditAbsenceSheet> {
  late DateTime _date = widget.day.absenceFromDate ?? widget.day.date;
  late final TextEditingController _note =
      TextEditingController(text: widget.day.absenceNote ?? '');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    Navigator.pop(
      context,
      Av2AbsenceEditResult(
        // Admin edits a single day: from == to.
        fromDate: _date,
        toDate: _date,
        // Carried through unchanged.
        reason: widget.day.absenceReason ?? '',
        type: (widget.day.absenceType?.trim().isNotEmpty ?? false)
            ? widget.day.absenceType!
            : 'FULL_DAY',
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final df = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              Av2Spacing.md, Av2Spacing.sm, Av2Spacing.md, Av2Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Av2Colors.border,
                    borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: Av2Spacing.md),
              Row(
                children: [
                  Expanded(child: Text('Edit absent', style: Av2Text.title)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 20, color: Av2Colors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Av2Spacing.md),
              Text('Absent Date', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _dateField(df.format(_date), _pickDate),
              const SizedBox(height: Av2Spacing.md),
              Text('Absent Note', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _noteField(),
              const SizedBox(height: Av2Spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Av2Colors.borderStrong),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                        ),
                      ),
                      child: Text('Cancel',
                          style: Av2Text.bodyMedium
                              .copyWith(color: Av2Colors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: Av2Spacing.sm),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                      child: InkWell(
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                        child: Ink(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: Av2Colors.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(Av2Spacing.radiusSm),
                          ),
                          child: Center(
                            child: Text('Submit',
                                style: Av2Text.bodyMedium
                                    .copyWith(color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Av2Colors.surfaceMuted,
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          border: Border.all(color: Av2Colors.border),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: Av2Text.body, maxLines: 1)),
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Av2Colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: _note,
      maxLines: 3,
      style: Av2Text.body,
      decoration: InputDecoration(
        hintText: 'Add a note',
        hintStyle: Av2Text.body.copyWith(color: Av2Colors.textTertiary),
        filled: true,
        fillColor: Av2Colors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          borderSide: const BorderSide(color: Av2Colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          borderSide: const BorderSide(color: Av2Colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          borderSide: const BorderSide(color: Av2Colors.theme),
        ),
      ),
    );
  }
}
