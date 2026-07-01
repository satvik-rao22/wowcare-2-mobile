import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_confirm_dialog.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_empty_state.dart';

import '../../domain/entities/regularization_request.dart';
import '../widgets/reg_admin_notification_tile.dart';
import '../widgets/reg_decision_sheet.dart';
import '../widgets/reg_scaffold.dart';

/// Admin approver inbox — pending regularization requests. Admins approve
/// (correcting the time if needed); there is no reject. A bottom bar lets them
/// approve every pending request at once.
class RegAdminInboxScreen extends StatelessWidget {
  const RegAdminInboxScreen({super.key, required this.requests});

  final List<RegularizationRequest> requests;

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r.status.isPending).toList();
    return RegScaffold(
      title: 'Regularization requests',
      body: pending.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(Av2Spacing.md),
              child: Av2EmptyState(message: 'No pending requests'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(Av2Spacing.md),
                    itemCount: pending.length,
                    itemBuilder: (context, i) => RegAdminNotificationTile(
                      request: pending[i],
                      onTap: () => _review(context, pending[i]),
                    ),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Av2Spacing.xs + 2),
                  ),
                ),
                _approveAllBar(context, pending.length),
              ],
            ),
    );
  }

  Future<void> _review(BuildContext context, RegularizationRequest r) async {
    final decision = await showRegDecisionSheet(context, request: r);
    if (decision == null || !context.mounted) return;
    final changed =
        decision.signInLocal != null || decision.signOutLocal != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(changed
            ? 'Approved with changes · ${r.staffName}'
            : 'Approved · ${r.staffName}'),
      ),
    );
  }

  Widget _approveAllBar(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Av2Spacing.md, Av2Spacing.sm, Av2Spacing.md, Av2Spacing.md),
      decoration: const BoxDecoration(
        color: Av2Colors.surface,
        border: Border(top: BorderSide(color: Av2Colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          child: InkWell(
            onTap: () => _approveAll(context, count),
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            child: Ink(
              height: 48,
              decoration: BoxDecoration(
                gradient: Av2Colors.primaryGradient,
                borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.done_all, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Approve all ($count)',
                        style:
                            Av2Text.bodyMedium.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveAll(BuildContext context, int count) async {
    final confirmed = await showAv2ConfirmDialog(
      context,
      title: 'Approve all $count requests?',
      message: 'Each request is approved as submitted. If any needs a time '
          'change, tap it and adjust before approving all.',
      confirmLabel: 'Approve all',
    );
    if (!confirmed || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved $count requests')),
    );
  }
}
