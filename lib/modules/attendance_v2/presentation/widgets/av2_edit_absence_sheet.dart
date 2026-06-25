import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../domain/entities/attendance_day.dart';

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
  final String type; // FULL_DAY | HALF_DAY
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
  late DateTime _from = widget.day.absenceFromDate ?? widget.day.date;
  late DateTime _to = widget.day.absenceToDate ?? widget.day.date;
  late final TextEditingController _reason =
      TextEditingController(text: widget.day.absenceReason ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.day.absenceNote ?? '');
  late String _type =
      (widget.day.absenceType?.toUpperCase() == 'HALF_DAY') ? 'HALF_DAY' : 'FULL_DAY';
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_to.isBefore(_from)) _to = _from;
        } else {
          _to = picked;
        }
      });
    }
  }

  void _submit() {
    if (_to.isBefore(_from)) {
      setState(() => _error = 'End date must be on or after start date.');
      return;
    }
    Navigator.pop(
      context,
      Av2AbsenceEditResult(
        fromDate: _from,
        toDate: _to,
        reason: _reason.text.trim(),
        type: _type,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final df = DateFormat('dd-MM-yyyy');
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
              Text('Edit absence', style: Av2Text.title),
              const SizedBox(height: Av2Spacing.md),
              Text('Dates', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              Row(
                children: [
                  Expanded(child: _dateField(df.format(_from), () => _pick(isFrom: true))),
                  const SizedBox(width: Av2Spacing.xs),
                  Expanded(child: _dateField(df.format(_to), () => _pick(isFrom: false))),
                ],
              ),
              const SizedBox(height: Av2Spacing.md),
              Text('Type', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _typeToggle(),
              const SizedBox(height: Av2Spacing.md),
              Text('Reason', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _textField(_reason, 'e.g. sick'),
              const SizedBox(height: Av2Spacing.md),
              Text('Note', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _textField(_note, 'Optional note', maxLines: 2),
              if (_error != null) ...[
                const SizedBox(height: Av2Spacing.sm),
                Text(_error!,
                    style: Av2Text.caption.copyWith(color: Av2Colors.danger)),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Av2Colors.surfaceMuted,
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          border: Border.all(color: Av2Colors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Av2Colors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: Av2Text.body, maxLines: 1)),
          ],
        ),
      ),
    );
  }

  Widget _typeToggle() {
    Widget seg(String label, String value) {
      final sel = _type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _type = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? Av2Colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(Av2Spacing.radiusSm - 2),
              border: Border.all(color: sel ? Av2Colors.border : Colors.transparent),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Av2Text.chip.copyWith(
                color: sel ? Av2Colors.textPrimary : Av2Colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Av2Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      ),
      child: Row(children: [seg('Full day', 'FULL_DAY'), seg('Half day', 'HALF_DAY')]),
    );
  }

  Widget _textField(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: Av2Text.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Av2Text.body.copyWith(color: Av2Colors.textTertiary),
        filled: true,
        fillColor: Av2Colors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
