import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/missed_signout.dart';

class RegRaiseResult {
  const RegRaiseResult({required this.signOutLocal, required this.reason});
  final DateTime signOutLocal;
  final String reason;
}

/// Bottom sheet for a staff to raise a missed sign-out correction.
Future<RegRaiseResult?> showRegRaiseSheet(
  BuildContext context, {
  required MissedSignout item,
}) {
  return showModalBottomSheet<RegRaiseResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (context) => _RegRaiseSheet(item: item),
  );
}

class _RegRaiseSheet extends StatefulWidget {
  const _RegRaiseSheet({required this.item});
  final MissedSignout item;

  @override
  State<_RegRaiseSheet> createState() => _RegRaiseSheetState();
}

class _RegRaiseSheetState extends State<_RegRaiseSheet> {
  late TimeOfDay _time = TimeOfDay(
      hour: widget.item.softSignOutAt.hour,
      minute: widget.item.softSignOutAt.minute);
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Please add a reason.');
      return;
    }
    final d = widget.item.attendanceDate;
    Navigator.pop(
      context,
      RegRaiseResult(
        signOutLocal: DateTime(d.year, d.month, d.day, _time.hour, _time.minute),
        reason: _reason.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Request correction', style: Av2Text.title),
              Text(
                '${Av2DateFormatter.monthDay(widget.item.attendanceDate)} · missed sign-out',
                style: Av2Text.label,
              ),
              const SizedBox(height: Av2Spacing.md),
              Text('Actual sign-out time', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: Av2Colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                    border: Border.all(color: Av2Colors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Av2Colors.textSecondary),
                      const SizedBox(width: 8),
                      Text(_time.format(context), style: Av2Text.body),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Av2Spacing.md),
              Text('Reason', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              TextField(
                controller: _reason,
                maxLines: 2,
                style: Av2Text.body,
                decoration: InputDecoration(
                  hintText: 'e.g. stayed for parent meeting',
                  hintStyle: Av2Text.body.copyWith(color: Av2Colors.textTertiary),
                  filled: true,
                  fillColor: Av2Colors.surfaceMuted,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              ),
              if (_error != null) ...[
                const SizedBox(height: Av2Spacing.xs),
                Text(_error!,
                    style: Av2Text.caption.copyWith(color: Av2Colors.danger)),
              ],
              const SizedBox(height: Av2Spacing.lg),
              SizedBox(
                width: double.infinity,
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
                        child: Text('Submit request',
                            style: Av2Text.bodyMedium
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
