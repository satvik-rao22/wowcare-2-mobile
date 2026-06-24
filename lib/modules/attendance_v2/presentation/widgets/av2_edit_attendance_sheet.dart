import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../domain/entities/attendance_session.dart';

/// Result of an edit: the admin's wall-clock sign-in (required) and optional
/// sign-out. The data layer converts these to UTC using the school timezone.
class Av2EditResult {
  const Av2EditResult({required this.signInLocal, this.signOutLocal});
  final DateTime signInLocal;
  final DateTime? signOutLocal;
}

/// Bottom sheet to edit a session's sign-in/sign-out date+time.
Future<Av2EditResult?> showAv2EditAttendanceSheet(
  BuildContext context, {
  required AttendanceSession session,
}) {
  return showModalBottomSheet<Av2EditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (context) => _Av2EditAttendanceSheet(session: session),
  );
}

class _Av2EditAttendanceSheet extends StatefulWidget {
  const _Av2EditAttendanceSheet({required this.session});
  final AttendanceSession session;

  @override
  State<_Av2EditAttendanceSheet> createState() =>
      _Av2EditAttendanceSheetState();
}

class _Av2EditAttendanceSheetState extends State<_Av2EditAttendanceSheet> {
  late DateTime _inDate;
  late TimeOfDay _inTime;
  DateTime? _outDate;
  TimeOfDay? _outTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _inDate = DateTime(s.signInAt.year, s.signInAt.month, s.signInAt.day);
    _inTime = TimeOfDay(hour: s.signInAt.hour, minute: s.signInAt.minute);
    final out = s.signOutAt;
    if (out != null) {
      _outDate = DateTime(out.year, out.month, out.day);
      _outTime = TimeOfDay(hour: out.hour, minute: out.minute);
    }
  }

  Future<void> _pickDate({required bool isIn}) async {
    final initial = isIn ? _inDate : (_outDate ?? _inDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() => isIn ? _inDate = picked : _outDate = picked);
    }
  }

  Future<void> _pickTime({required bool isIn}) async {
    final initial = isIn ? _inTime : (_outTime ?? _inTime);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => isIn ? _inTime = picked : _outTime = picked);
    }
  }

  void _submit() {
    final signIn = _combine(_inDate, _inTime);
    DateTime? signOut;
    final hasOutDate = _outDate != null;
    final hasOutTime = _outTime != null;
    if (hasOutDate != hasOutTime) {
      setState(() => _error = 'Set both sign-out date and time, or leave both empty.');
      return;
    }
    if (hasOutDate && hasOutTime) {
      signOut = _combine(_outDate!, _outTime!);
      if (!signOut.isAfter(signIn)) {
        setState(() => _error = 'Sign-out must be after sign-in.');
        return;
      }
    }
    Navigator.pop(context, Av2EditResult(signInLocal: signIn, signOutLocal: signOut));
  }

  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
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
              Text('Edit attendance', style: Av2Text.title),
              Text(widget.session.classroomName, style: Av2Text.label),
              const SizedBox(height: Av2Spacing.md),
              _section(
                'Sign in',
                dateText: DateFormat('dd-MM-yyyy').format(_inDate),
                timeText: _inTime.format(context),
                onDate: () => _pickDate(isIn: true),
                onTime: () => _pickTime(isIn: true),
              ),
              const SizedBox(height: Av2Spacing.md),
              _section(
                'Sign out',
                dateText: _outDate == null
                    ? 'dd-mm-yyyy'
                    : DateFormat('dd-MM-yyyy').format(_outDate!),
                timeText: _outTime == null ? '--:--' : _outTime!.format(context),
                onDate: () => _pickDate(isIn: false),
                onTime: () => _pickTime(isIn: false),
                muted: _outDate == null && _outTime == null,
              ),
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
                          borderRadius:
                              BorderRadius.circular(Av2Spacing.radiusSm),
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

  Widget _section(
    String title, {
    required String dateText,
    required String timeText,
    required VoidCallback onDate,
    required VoidCallback onTime,
    bool muted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Av2Text.bodyMedium),
        const SizedBox(height: Av2Spacing.xs),
        Row(
          children: [
            Expanded(
              child: _field(
                  icon: Icons.calendar_today_outlined,
                  text: dateText,
                  muted: muted,
                  onTap: onDate),
            ),
            const SizedBox(width: Av2Spacing.xs),
            Expanded(
              child: _field(
                  icon: Icons.access_time,
                  text: timeText,
                  muted: muted,
                  onTap: onTime),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool muted = false,
  }) {
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
            Icon(icon, size: 16, color: Av2Colors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Av2Text.body.copyWith(
                  color: muted ? Av2Colors.textTertiary : Av2Colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
