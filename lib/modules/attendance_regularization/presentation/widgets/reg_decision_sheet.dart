import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/regularization_request.dart';

class RegDecision {
  const RegDecision({
    required this.approved,
    this.signInLocal,
    this.signOutLocal,
    this.note = '',
  });
  final bool approved;
  final DateTime? signInLocal; // admin-adjusted (modify) — null if unchanged
  final DateTime? signOutLocal;
  final String note;
}

/// Admin sheet to decide a request: adjust the time (modify), then Approve, or
/// Reject with a note.
Future<RegDecision?> showRegDecisionSheet(
  BuildContext context, {
  required RegularizationRequest request,
}) {
  return showModalBottomSheet<RegDecision>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (context) => _RegDecisionSheet(request: request),
  );
}

class _RegDecisionSheet extends StatefulWidget {
  const _RegDecisionSheet({required this.request});
  final RegularizationRequest request;

  @override
  State<_RegDecisionSheet> createState() => _RegDecisionSheetState();
}

class _RegDecisionSheetState extends State<_RegDecisionSheet> {
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  final _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    if (r.requestedSignInAt != null) {
      _inTime = TimeOfDay.fromDateTime(r.requestedSignInAt!);
    }
    if (r.requestedSignOutAt != null) {
      _outTime = TimeOfDay.fromDateTime(r.requestedSignOutAt!);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isIn ? _inTime : _outTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => isIn ? _inTime = picked : _outTime = picked);
    }
  }

  DateTime? _combine(TimeOfDay? t) {
    if (t == null) return null;
    final d = widget.request.attendanceDate;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  void _approve() => Navigator.pop(
        context,
        RegDecision(
          approved: true,
          signInLocal: _combine(_inTime),
          signOutLocal: _combine(_outTime),
          note: _note.text.trim(),
        ),
      );

  void _reject() {
    if (_note.text.trim().isEmpty) {
      setState(() => _error = 'Add a note to reject.');
      return;
    }
    Navigator.pop(context, RegDecision(approved: false, note: _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              Text(r.staffName, style: Av2Text.title),
              Text('${r.type.label} · ${Av2DateFormatter.monthDay(r.attendanceDate)}',
                  style: Av2Text.label),
              const SizedBox(height: Av2Spacing.sm),
              _reasonBox(r.reason),
              const SizedBox(height: Av2Spacing.md),
              if (_inTime != null) ...[
                Text('Sign-in time', style: Av2Text.bodyMedium),
                const SizedBox(height: Av2Spacing.xs),
                _timeField(_inTime!, () => _pick(isIn: true)),
                const SizedBox(height: Av2Spacing.md),
              ],
              if (_outTime != null) ...[
                Text('Sign-out time', style: Av2Text.bodyMedium),
                const SizedBox(height: Av2Spacing.xs),
                _timeField(_outTime!, () => _pick(isIn: false)),
                const SizedBox(height: Av2Spacing.md),
              ],
              Text('Note', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _noteField(),
              if (_error != null) ...[
                const SizedBox(height: Av2Spacing.xs),
                Text(_error!,
                    style: Av2Text.caption.copyWith(color: Av2Colors.danger)),
              ],
              const SizedBox(height: Av2Spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Av2Colors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                        ),
                      ),
                      child: Text('Reject',
                          style: Av2Text.bodyMedium.copyWith(color: Av2Colors.danger)),
                    ),
                  ),
                  const SizedBox(width: Av2Spacing.sm),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                      child: InkWell(
                        onTap: _approve,
                        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                        child: Ink(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: Av2Colors.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(Av2Spacing.radiusSm),
                          ),
                          child: Center(
                            child: Text('Approve',
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

  Widget _reasonBox(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Av2Spacing.sm),
      decoration: BoxDecoration(
        color: Av2Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      ),
      child: Text(reason.isEmpty ? 'No reason provided' : reason,
          style: Av2Text.body.copyWith(color: Av2Colors.textSecondary)),
    );
  }

  Widget _timeField(TimeOfDay t, VoidCallback onTap) {
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
            const Icon(Icons.access_time, size: 16, color: Av2Colors.textSecondary),
            const SizedBox(width: 8),
            Text(t.format(context), style: Av2Text.body),
            const Spacer(),
            Text('Tap to modify',
                style: Av2Text.caption.copyWith(color: Av2Colors.theme)),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: _note,
      maxLines: 2,
      style: Av2Text.body,
      decoration: InputDecoration(
        hintText: 'Optional for approve · required to reject',
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
