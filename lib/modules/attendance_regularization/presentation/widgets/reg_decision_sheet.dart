import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../core/config/reg_config.dart';
import '../../domain/entities/regularization_request.dart';

class RegDecision {
  const RegDecision({this.signOutLocal, this.note = ''});

  /// Admin-adjusted sign-out (modify) — null means "approve as submitted".
  final DateTime? signOutLocal;
  final String note;
}

/// Admin sheet to approve a request — optionally adjusting (modifying) the time
/// with a reason. There is no reject: admins approve, correcting if needed.
Future<RegDecision?> showRegDecisionSheet(
  BuildContext context, {
  required RegularizationRequest request,
}) {
  return showModalBottomSheet<RegDecision>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Av2Spacing.radiusLg),
      ),
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
  late TimeOfDay _outTime;

  /// Whether the admin actually touched the time. Spec §9.6: omit `signOutTime`
  /// to approve **as submitted**. Sending the pre-filled value back would
  /// record a modification that never happened and make
  /// `RegularizationRequest.wasModified` lie.
  bool _timeChanged = false;

  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _outTime = TimeOfDay.fromDateTime(widget.request.requestedSignOutTime);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickOutTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _outTime,
    );
    if (picked == null) return;
    setState(() {
      _outTime = picked;
      _timeChanged = true;
    });
  }

  DateTime _combine(TimeOfDay t) {
    final d = widget.request.attendanceDate;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  void _approve() => Navigator.pop(
    context,
    RegDecision(
      signOutLocal: _timeChanged ? _combine(_outTime) : null,
      note: _note.text.trim(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Av2Spacing.md,
            Av2Spacing.sm,
            Av2Spacing.md,
            Av2Spacing.md,
          ),
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
              Text(
                'Missed sign-out · ${Av2DateFormatter.monthDay(r.attendanceDate)}',
                style: Av2Text.label,
              ),
              const SizedBox(height: Av2Spacing.sm),
              _reasonBox(r.reason),
              const SizedBox(height: Av2Spacing.md),
              Text('Sign-out time', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _timeField(_outTime, _pickOutTime),
              const SizedBox(height: Av2Spacing.md),
              Text('Reason for change', style: Av2Text.bodyMedium),
              const SizedBox(height: Av2Spacing.xs),
              _noteField(),
              const SizedBox(height: Av2Spacing.lg),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                  child: InkWell(
                    onTap: _approve,
                    borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                    child: Ink(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Av2Colors.primaryFill,
                        borderRadius: BorderRadius.circular(
                          Av2Spacing.radiusSm,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Approve',
                          style: Av2Text.bodyMedium.copyWith(
                            color: Av2Colors.onPrimary,
                          ),
                        ),
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

  Widget _reasonBox(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Av2Spacing.sm),
      decoration: BoxDecoration(
        color: Av2Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      ),
      child: Text(
        reason.isEmpty ? 'No reason provided' : reason,
        style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
      ),
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
            const Icon(
              Icons.access_time,
              size: 16,
              color: Av2Colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(t.format(context), style: Av2Text.body),
            const Spacer(),
            Text(
              'Tap to modify',
              style: Av2Text.caption.copyWith(color: Av2Colors.theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return SkeuFieldWell(
      // A field you type into is a well: no edge at rest, none on focus.
      radius: Av2Spacing.radiusSm,
      child: TextField(
        controller: _note,
        maxLines: 2,
        maxLength: RegConfig.reasonMaxLength,
        style: Av2Text.body,
        decoration: AppSurfaces.fieldDecoration(radius: Av2Spacing.radiusSm)
            .copyWith(
              hintText: 'Optional · why you adjusted the time',
              hintStyle: Av2Text.body.copyWith(color: Av2Colors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
            ),
      ),
    );
  }
}
