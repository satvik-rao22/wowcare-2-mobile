import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../core/config/reg_config.dart';
import '../../domain/entities/missed_signout.dart';
import '../../domain/policy/reg_time_policy.dart';

/// Outcome of resolving a missed sign-out: the actual sign-out time plus a
/// reason.
///
/// There is no "was the suggestion kept?" flag. Spec §7.5 dropped both the
/// stored suggestion and `confirmed_suggested_time`, so the server cannot
/// distinguish "kept the pre-filled time" from "typed the same time
/// deliberately" — which is why §8.2 makes [reason] mandatory either way.
class RegResolveResult {
  const RegResolveResult({required this.signOutLocal, required this.reason});
  final DateTime signOutLocal;
  final String reason;
}

/// Whether the sheet is creating a request or revising an existing one.
enum RegResolveMode {
  /// §9.2 — no request exists yet for this day.
  create,

  /// §9.4 — a `PENDING` request exists and is being corrected. This is the
  /// module's only fix-it path; there is no cancel (§8.4).
  edit,
}

/// Single bottom sheet that handles a missed sign-out end-to-end: it explains
/// what's missing and the consequence, lets the raiser set the actual sign-out
/// time + reason, and submits — all in one place.
///
/// The **same sheet serves create and edit** ([mode]). §9.4 accepts exactly
/// the two fields this sheet already collects, so a second sheet would be
/// duplicated layout plus a second copy of the §8.5 validation that could
/// drift from this one. [mode] only changes the copy and the pre-fill.
///
/// When [mandatory] (the gate before signing in), it can't be dismissed
/// without submitting.
///
/// Set [byAdmin] when an **admin** is raising it on a staff member's behalf
/// (they must clear the open day before they can sign that staff in). Admin
/// corrections are **auto-approved by the backend**, so the copy promises an
/// immediate apply rather than "sent for approval". Pass [staffName] for
/// admin mode so the sheet can name whose day it is.
///
/// In [RegResolveMode.edit], pass [initialSignOutLocal] and [initialReason]
/// from the existing request so the fields open on what was actually asked for
/// rather than back on the suggestion.
Future<RegResolveResult?> showRegResolveSheet(
  BuildContext context, {
  required MissedSignout item,
  bool mandatory = false,
  bool byAdmin = false,
  String staffName = '',
  RegResolveMode mode = RegResolveMode.create,
  DateTime? initialSignOutLocal,
  String initialReason = '',
}) {
  return showModalBottomSheet<RegResolveResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: !mandatory,
    enableDrag: !mandatory,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Av2Spacing.radiusLg),
      ),
    ),
    builder: (context) => _RegResolveSheet(
      item: item,
      mandatory: mandatory,
      byAdmin: byAdmin,
      staffName: staffName,
      mode: mode,
      initialSignOutLocal: initialSignOutLocal,
      initialReason: initialReason,
    ),
  );
}

class _RegResolveSheet extends StatefulWidget {
  const _RegResolveSheet({
    required this.item,
    required this.mandatory,
    required this.byAdmin,
    required this.staffName,
    required this.mode,
    required this.initialSignOutLocal,
    required this.initialReason,
  });
  final MissedSignout item;
  final bool mandatory;
  final bool byAdmin;
  final String staffName;
  final RegResolveMode mode;
  final DateTime? initialSignOutLocal;
  final String initialReason;

  @override
  State<_RegResolveSheet> createState() => _RegResolveSheetState();
}

class _RegResolveSheetState extends State<_RegResolveSheet> {
  /// Editing opens on what was actually requested; creating opens on the
  /// server's suggestion (§9.1).
  late TimeOfDay _time = TimeOfDay(
    hour: (widget.initialSignOutLocal ?? widget.item.suggestedOrDefault).hour,
    minute:
        (widget.initialSignOutLocal ?? widget.item.suggestedOrDefault).minute,
  );
  late final TextEditingController _reason = TextEditingController(
    text: widget.initialReason,
  );
  String? _error;

  bool get _isEdit => widget.mode == RegResolveMode.edit;

  /// Whose day it is, for admin-mode copy.
  String get _who => widget.staffName.trim().isEmpty
      ? 'This staff member'
      : widget.staffName.trim();

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
    final d = widget.item.attendanceDate;
    final signOutLocal = DateTime(
      d.year,
      d.month,
      d.day,
      _time.hour,
      _time.minute,
    );

    // §8.2 reason + "after sign-in", from the shared policy so the message
    // here matches what the server would reject for. No closing-time bound:
    // staying late is the normal reason a sign-out was missed.
    final error =
        RegTimePolicy.validateReason(_reason.text) ??
        RegTimePolicy.validateSignOut(
          signOutLocal: signOutLocal,
          attendanceDate: d,
          signedInAt: widget.item.signedInAt,
        );
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    Navigator.pop(
      context,
      RegResolveResult(signOutLocal: signOutLocal, reason: _reason.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final suggested = Av2DateFormatter.compactTime(item.suggestedOrDefault);
    final dateLabel = Av2DateFormatter.monthDay(item.attendanceDate);
    return PopScope(
      canPop: !widget.mandatory,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
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
                      borderRadius: BorderRadius.circular(
                        Av2Spacing.radiusPill,
                      ),
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
                            _isEdit
                                ? 'Update your request'
                                : (widget.byAdmin
                                      ? 'Sign-out missing'
                                      : 'Finish yesterday first'),
                            style: Av2Text.title,
                          ),
                          Text(
                            '$dateLabel · missed sign-out',
                            style: Av2Text.label,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Av2Spacing.sm),
                Text(
                  _isEdit
                      ? 'This request is still waiting for approval, so you '
                            'can change the time or the reason.'
                      : (widget.byAdmin
                            ? '$_who never signed out on $dateLabel. Add the '
                                  'sign-out before signing them in again.'
                            : "You didn't sign out on $dateLabel, so that day "
                                  'is still open.'),
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
                  _isEdit
                      ? 'Showing what you asked for. The school end time was '
                            '$suggested.'
                      : (widget.byAdmin
                            ? 'Pre-filled with $suggested — change it if they '
                                  'left at a different time.'
                            : 'Pre-filled with $suggested — change it if you '
                                  'left at a different time.'),
                  style: Av2Text.caption.copyWith(
                    color: Av2Colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Av2Spacing.md),
                Row(
                  children: [
                    Text('Reason', style: Av2Text.bodyMedium),
                    const SizedBox(width: 6),
                    Text(
                      '(required)',
                      style: Av2Text.caption.copyWith(
                        color: Av2Colors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Av2Spacing.xs),
                _reasonField(),
                if (_error != null) ...[
                  const SizedBox(height: Av2Spacing.xs),
                  Text(
                    _error!,
                    style: Av2Text.caption.copyWith(color: Av2Colors.danger),
                  ),
                ],
                const SizedBox(height: Av2Spacing.lg),
                _primary(
                  _isEdit
                      ? 'Save changes'
                      : (widget.byAdmin ? 'Save sign-out' : 'Confirm & submit'),
                ),
                if (!widget.mandatory) ...[
                  const SizedBox(height: Av2Spacing.xs),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Later',
                        style: Av2Text.label.copyWith(
                          color: Av2Colors.textSecondary,
                        ),
                      ),
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
              _isEdit
                  ? 'Editing keeps the request pending, so you stay unblocked '
                        "— but the day still won't be counted until an admin "
                        'approves it.'
                  : (widget.byAdmin
                        ? 'As an admin your correction is approved '
                              'automatically — the day is counted as soon as you '
                              'save.'
                        : "Until this is approved, that day's sign-out — and "
                              "any hours after it — won't be counted in your "
                              'attendance.'),
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
            const Icon(
              Icons.access_time,
              size: 16,
              color: Av2Colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(_time.format(context), style: Av2Text.body),
            const Spacer(),
            Text(
              'Tap to change',
              style: Av2Text.caption.copyWith(color: Av2Colors.theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonField() {
    return SkeuFieldWell(
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
              hintText: 'e.g. stayed for parent meeting',
              hintStyle: Av2Text.body.copyWith(color: Av2Colors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
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
              color: Av2Colors.primaryFill,
              borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            ),
            child: Center(
              child: Text(
                label,
                style: Av2Text.bodyMedium.copyWith(color: Av2Colors.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
