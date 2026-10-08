import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/regularization_request.dart';
import 'reg_status_pill.dart';

/// Read-only detail for a request that can no longer be acted on.
///
/// Its job is the part an approved row otherwise hides: what was asked for,
/// what was actually committed, who committed it, and — the reason this sheet
/// exists — the approver's note explaining any adjustment. Before it, tapping
/// an approved row opened the *approve* sheet, which shows the raiser's reason
/// and nothing about the decision.
Future<void> showRegRequestDetailSheet(
  BuildContext context, {
  required RegularizationRequest request,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Av2Spacing.radiusLg),
      ),
    ),
    builder: (context) => _RegRequestDetailSheet(request: request),
  );
}

class _RegRequestDetailSheet extends StatelessWidget {
  const _RegRequestDetailSheet({required this.request});

  final RegularizationRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final approved = r.status.isApproved;

    return SafeArea(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.staffName.isEmpty ? 'Staff' : r.staffName,
                        style: Av2Text.title,
                      ),
                      Text(
                        'Missed sign-out · '
                        '${Av2DateFormatter.monthDay(r.attendanceDate)}',
                        style: Av2Text.label,
                      ),
                    ],
                  ),
                ),
                RegStatusPill(status: r.status),
              ],
            ),
            const SizedBox(height: Av2Spacing.md),

            _Label('Requested sign-out'),
            _Value(Av2DateFormatter.compactTime(r.requestedSignOutTime)),

            const SizedBox(height: Av2Spacing.sm),
            _Label('Reason'),
            _Box(r.reason.isEmpty ? 'No reason given' : r.reason),

            if (approved) ...[
              const SizedBox(height: Av2Spacing.md),
              const Divider(height: 1, color: Av2Colors.border),
              const SizedBox(height: Av2Spacing.md),

              _Label('Approved sign-out'),
              _Value(
                Av2DateFormatter.compactTime(r.effectiveSignOutTime),
                // Both numbers, so "asked 7:00, approved 6:30" stays legible
                // rather than silently replacing what was requested.
                note: r.wasModified
                    ? 'adjusted from '
                          '${Av2DateFormatter.compactTime(r.requestedSignOutTime)}'
                    : null,
              ),

              if ((r.approvalNote ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: Av2Spacing.sm),
                _Label('Reason for change'),
                _Box(r.approvalNote!.trim()),
              ],

              const SizedBox(height: Av2Spacing.sm),
              _Label('Approved by'),
              _Value(_approver(r)),
            ],

            const SizedBox(height: Av2Spacing.md),
            Text(
              _raisedLine(r),
              style: Av2Text.caption.copyWith(color: Av2Colors.textTertiary),
            ),
            const SizedBox(height: Av2Spacing.sm),
          ],
        ),
      ),
    );
  }

  String _approver(RegularizationRequest r) {
    final who = (r.approvalByName ?? '').trim();
    // Auto-approval has no human approver to name, so say what happened
    // instead of leaving the field blank.
    final name = who.isNotEmpty
        ? who
        : (r.autoApproved ? 'Approved automatically' : 'An admin');
    final at = r.approvalAt;
    if (at == null) return name;
    return '$name · ${Av2DateFormatter.monthDay(at)}, '
        '${Av2DateFormatter.compactTime(at)}';
  }

  String _raisedLine(RegularizationRequest r) {
    final raised =
        'Raised ${Av2DateFormatter.monthDay(r.createdAt)}, '
        '${Av2DateFormatter.compactTime(r.createdAt)}';
    return r.wasEdited ? '$raised · edited since' : raised;
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: Av2Text.caption.copyWith(color: Av2Colors.textSecondary),
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.text, {this.note});
  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: Text(text, style: Av2Text.bodyMedium)),
        if (note != null) ...[
          const SizedBox(width: 6),
          Text(
            note!,
            style: Av2Text.caption.copyWith(color: Av2Colors.overtime),
          ),
        ],
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Av2Spacing.sm),
      decoration: BoxDecoration(
        color: Av2Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      ),
      child: Text(
        text,
        style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
      ),
    );
  }
}
