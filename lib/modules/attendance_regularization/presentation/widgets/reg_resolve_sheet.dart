import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/missed_signout.dart';

/// Outcome of resolving a missed sign-out. [confirmedSoftTime] is true when the
/// staff left the system time unchanged (a simple confirmation rather than a
/// correction).
class RegResolveResult {
  const RegResolveResult({
    required this.signOutLocal,
    required this.reason,
    required this.confirmedSoftTime,
  });
  final DateTime signOutLocal;
  final String reason;
  final bool confirmedSoftTime;
}

/// Single bottom sheet that handles a missed sign-out end-to-end: it explains
/// what's missing and the consequence, lets the raiser confirm the suggested
/// time or set the actual time + reason, and submits — all in one place.
///
/// When [mandatory] (the gate before signing in), it can't be dismissed
/// without submitting.
///
/// Set [byAdmin] when an **admin** is raising it on a staff member's behalf
/// (they must clear the open day before they can sign that staff in). Admin
/// corrections are **auto-approved by the backend**, so the copy promises an
/// immediate apply rather than "sent for approval". Pass [staffName] for
/// admin mode so the sheet can name whose day it is.
Future<RegResolveResult?> showRegResolveSheet(
  BuildContext context, {
  required MissedSignout item,
  bool mandatory = false,
  bool byAdmin = false,
  String staffName = '',
}) {
  return showModalBottomSheet<RegResolveResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: !mandatory,
    enableDrag: !mandatory,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (context) => _RegResolveSheet(
      item: item,
      mandatory: mandatory,
      byAdmin: byAdmin,
      staffName: staffName,
    ),
  );
}

class _RegResolveSheet extends StatefulWidget {
  const _RegResolveSheet({
    required this.item,
    required this.mandatory,
    required this.byAdmin,
    required this.staffName,
  });
  final MissedSignout item;
  final bool mandatory;
  final bool byAdmin;
  final String staffName;

  @override
  State<_RegResolveSheet> createState() => _RegResolveSheetState();
}

class _RegResolveSheetState extends State<_RegResolveSheet> {
  late TimeOfDay _time = TimeOfDay(
    hour: widget.item.softSignOutAt.hour,
    minute: widget.item.softSignOutAt.minute,
  );
  final _reason = TextEditingController();
  String? _error;

  /// Whose day it is, for admin-mode copy.
  String get _who =>
      widget.staffName.trim().isEmpty ? 'This staff member' : widget.staffName.trim();

  bool get _isSoftTime =>
      _time.hour == widget.item.softSignOutAt.hour &&
      _time.minute == widget.item.softSignOutAt.minute;

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
    // A correction (different time) needs a reason; confirming the system time
    // does not.
    if (!_isSoftTime && _reason.text.trim().isEmpty) {
      setState(() => _error = 'Add a reason for the corrected time.');
      return;
    }
    final d = widget.item.attendanceDate;
    Navigator.pop(
      context,
      RegResolveResult(
        signOutLocal: DateTime(d.year, d.month, d.day, _time.hour, _time.minute),
        reason: _reason.text.trim(),
        confirmedSoftTime: _isSoftTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final soft = Av2DateFormatter.compactTime(item.softSignOutAt);
    final dateLabel = Av2DateFormatter.monthDay(item.attendanceDate);
    return PopScope(
      canPop: !widget.mandatory,
      child: Padding(
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
                      child: const Icon(Icons.error_outline,
                          size: 20, color: Av2Colors.overtime),
                    ),
                    const SizedBox(width: Av2Spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              widget.byAdmin
                                  ? 'Sign-out missing'
                                  : 'Finish yesterday first',
                              style: Av2Text.title),
                          Text('$dateLabel · missed sign-out',
                              style: Av2Text.label),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Av2Spacing.sm),
                Text(
                  widget.byAdmin
                      ? '$_who never signed out on $dateLabel. Add the '
                          'sign-out before signing them in again.'
                      : "You didn't sign out on $dateLabel, so that day is "
                          'still open.',
                  style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
                ),
                const SizedBox(height: Av2Spacing.sm),
                _consequenceStrip(),
                const SizedBox(height: Av2Spacing.md),
                Text('Actual sign-out time', style: Av2Text.bodyMedium),
                const SizedBox(height: Av2Spacing.xs),
                _timeField(),
                const SizedBox(height: 6),
                Text(
                  _isSoftTime
                      ? (widget.byAdmin
                          ? 'If $soft is right, just save to apply it.'
                          : "If $soft is right, just submit to confirm.")
                      : 'Corrected to ${_time.format(context)} — add a reason below.',
                  style: Av2Text.caption.copyWith(color: Av2Colors.textSecondary),
                ),
                const SizedBox(height: Av2Spacing.md),
                Row(
                  children: [
                    Text('Reason', style: Av2Text.bodyMedium),
                    const SizedBox(width: 6),
                    Text(_isSoftTime ? '(optional)' : '(required)',
                        style: Av2Text.caption
                            .copyWith(color: Av2Colors.textTertiary)),
                  ],
                ),
                const SizedBox(height: Av2Spacing.xs),
                _reasonField(),
                if (_error != null) ...[
                  const SizedBox(height: Av2Spacing.xs),
                  Text(_error!,
                      style: Av2Text.caption.copyWith(color: Av2Colors.danger)),
                ],
                const SizedBox(height: Av2Spacing.lg),
                _primary(widget.byAdmin
                    ? 'Save sign-out'
                    : (_isSoftTime ? 'Confirm & submit' : 'Submit request')),
                if (!widget.mandatory) ...[
                  const SizedBox(height: Av2Spacing.xs),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Later',
                          style: Av2Text.label
                              .copyWith(color: Av2Colors.textSecondary)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _consequenceStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Av2Spacing.sm),
      decoration: BoxDecoration(
        color: Av2Colors.overtimeFill,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Av2Colors.overtime),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.byAdmin
                  ? 'As an admin your correction is approved automatically — '
                      'the day is counted as soon as you save.'
                  : "Until this is approved, that day's sign-out — and any "
                      "hours after it — won't be counted in your attendance.",
              style: Av2Text.caption.copyWith(color: Av2Colors.overtime),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField() {
    return InkWell(
      onTap: _pickTime,
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
            Text(_time.format(context), style: Av2Text.body),
            const Spacer(),
            Text('Tap to change',
                style: Av2Text.caption.copyWith(color: Av2Colors.theme)),
          ],
        ),
      ),
    );
  }

  Widget _reasonField() {
    return TextField(
      controller: _reason,
      maxLines: 2,
      style: Av2Text.body,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        hintText: 'e.g. stayed for parent meeting',
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

  Widget _primary(String label) {
    return SizedBox(
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
              borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            ),
            child: Center(
              child: Text(label,
                  style: Av2Text.bodyMedium.copyWith(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
