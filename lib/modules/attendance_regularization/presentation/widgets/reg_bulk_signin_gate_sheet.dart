import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';

import '../../core/config/reg_config.dart';
import '../../domain/entities/missed_signout.dart';
import '../../domain/policy/reg_time_policy.dart';
import 'reg_staff_time_row.dart';

/// One staff member's resolution inside a bulk sign-in gate.
class RegBulkGateItem {
  const RegBulkGateItem({
    required this.attendanceCode,
    required this.staffCode,
    required this.attendanceDate,
    required this.signOutLocal,
    required this.reason,
  });

  final String attendanceCode;
  final String staffCode;
  final DateTime attendanceDate;
  final DateTime signOutLocal;

  /// Mandatory on every item (spec §8.2) — the shared reason, unless this row
  /// was given its own.
  final String reason;
}

/// Blocks a **bulk sign-in** when some of the selected staff still have an
/// unresolved past day, and closes all of them in one action.
///
/// Every row is pre-filled with that staff's suggested sign-out time, so the
/// common case is a single tap. Tapping a row's time corrects just that person;
/// one shared reason covers whoever was corrected.
///
/// Returns the resolutions to apply, or `null` if the admin chose to skip
/// (the unaffected staff still sign in — the caller handles that).
Future<List<RegBulkGateItem>?> showRegBulkSignInGateSheet(
  BuildContext context, {
  required List<MissedSignout> blocked,
  int otherCount = 0,
}) {
  return showModalBottomSheet<List<RegBulkGateItem>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Av2Spacing.radiusLg),
      ),
    ),
    builder: (context) =>
        _RegBulkSignInGateSheet(blocked: blocked, otherCount: otherCount),
  );
}

class _RegBulkSignInGateSheet extends StatefulWidget {
  const _RegBulkSignInGateSheet({
    required this.blocked,
    required this.otherCount,
  });
  final List<MissedSignout> blocked;
  final int otherCount;

  @override
  State<_RegBulkSignInGateSheet> createState() =>
      _RegBulkSignInGateSheetState();
}

class _RegBulkSignInGateSheetState extends State<_RegBulkSignInGateSheet> {
  /// attendanceCode → chosen sign-out time (starts at the suggested time).
  final Map<String, TimeOfDay> _times = {};
  final _reason = TextEditingController();
  String? _error;

  late final List<MissedSignout> _staff = [...widget.blocked]
    ..sort(
      (a, b) => a.staffName.toLowerCase().compareTo(b.staffName.toLowerCase()),
    );

  @override
  void initState() {
    super.initState();
    for (final s in _staff) {
      _times[s.attendanceCode] = _suggested(s);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  TimeOfDay _suggested(MissedSignout s) => TimeOfDay(
    hour: s.suggestedOrDefault.hour,
    minute: s.suggestedOrDefault.minute,
  );

  bool _isEdited(MissedSignout s) {
    final t = _times[s.attendanceCode]!;
    final sug = _suggested(s);
    return t.hour != sug.hour || t.minute != sug.minute;
  }

  int get _editedCount => _staff.where(_isEdited).length;

  Future<void> _pickTime(MissedSignout s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[s.attendanceCode]!,
    );
    if (picked != null) {
      setState(() {
        _times[s.attendanceCode] = picked;
        _error = null;
      });
    }
  }

  void _reset(MissedSignout s) =>
      setState(() => _times[s.attendanceCode] = _suggested(s));

  void _submit() {
    final reason = _reason.text.trim();
    // §8.2: reason is mandatory for every item of a batch raise, shared or
    // per-item — not only for the rows whose time was corrected.
    final reasonError = RegTimePolicy.validateReason(reason);
    if (reasonError != null) {
      setState(() => _error = reasonError);
      return;
    }
    Navigator.pop(context, [
      for (final s in _staff)
        RegBulkGateItem(
          attendanceCode: s.attendanceCode,
          staffCode: s.staffCode,
          attendanceDate: s.attendanceDate,
          signOutLocal: DateTime(
            s.attendanceDate.year,
            s.attendanceDate.month,
            s.attendanceDate.day,
            _times[s.attendanceCode]!.hour,
            _times[s.attendanceCode]!.minute,
          ),
          reason: reason,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final n = _staff.length;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Av2Spacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Av2Colors.border,
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Av2Spacing.md,
                  Av2Spacing.md,
                  Av2Spacing.md,
                  Av2Spacing.sm,
                ),
                child: _header(n),
              ),
              Flexible(child: _list()),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Av2Spacing.md,
                  Av2Spacing.sm,
                  Av2Spacing.md,
                  Av2Spacing.md,
                ),
                child: _footer(n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Av2Colors.overtimeFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 20,
                color: Av2Colors.overtime,
              ),
            ),
            const SizedBox(width: Av2Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    n == 1
                        ? '1 staff needs yesterday closed'
                        : '$n staff need yesterday closed',
                    style: Av2Text.title,
                  ),
                  if (widget.otherCount > 0)
                    Text(
                      '${widget.otherCount} others will sign in normally',
                      style: Av2Text.label,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Av2Spacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Av2Spacing.sm),
          decoration: BoxDecoration(
            color: Av2Colors.overtimeFill,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Av2Colors.overtime,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These staff never signed out, so those days are not counted '
                  'and they cannot be signed in yet. Closing them here is '
                  'approved automatically.',
                  style: Av2Text.caption.copyWith(color: Av2Colors.overtime),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Av2Spacing.sm),
        Text(
          'Each is set to the school end time. Tap a time to correct just that '
          'person.',
          style: Av2Text.caption.copyWith(color: Av2Colors.textSecondary),
        ),
      ],
    );
  }

  Widget _list() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: Av2Spacing.md),
      itemCount: _staff.length,
      itemBuilder: (context, i) {
        final s = _staff[i];
        return RegStaffTimeRow(
          item: s,
          signOutTime: _times[s.attendanceCode]!,
          isEdited: _isEdited(s),
          onEditTime: () => _pickTime(s),
          onReset: () => _reset(s),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
    );
  }

  Widget _footer(int n) {
    final edited = _editedCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reason', style: Av2Text.bodyMedium),
            const SizedBox(width: 6),
            Text(
              '(required)',
              style: Av2Text.caption.copyWith(color: Av2Colors.textTertiary),
            ),
            const Spacer(),
            if (edited > 0)
              Text(
                '$edited corrected',
                style: Av2Text.caption.copyWith(color: Av2Colors.theme),
              ),
          ],
        ),
        const SizedBox(height: Av2Spacing.xs),
        SkeuFieldWell(
          // A field you type into is a well: no edge at rest, none on focus.
          radius: Av2Spacing.radiusSm,
          child: TextField(
            controller: _reason,
            maxLines: 2,
            maxLength: RegConfig.reasonMaxLength,
            style: Av2Text.body,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: AppSurfaces.fieldDecoration(radius: Av2Spacing.radiusSm)
                .copyWith(
                  hintText: 'e.g. forgot to sign out',
                  hintStyle: Av2Text.body.copyWith(
                    color: Av2Colors.textTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Av2Spacing.xs),
          Text(
            _error!,
            style: Av2Text.caption.copyWith(color: Av2Colors.danger),
          ),
        ],
        const SizedBox(height: Av2Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            child: InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
              child: Ink(
                height: 48,
                decoration: BoxDecoration(
                  color: Av2Colors.primaryFill,
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    'Close all $n & sign them in',
                    style: Av2Text.bodyMedium.copyWith(
                      color: Av2Colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.otherCount > 0
                  ? 'Skip — sign in the other ${widget.otherCount}'
                  : 'Skip for now',
              style: Av2Text.label.copyWith(color: Av2Colors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
