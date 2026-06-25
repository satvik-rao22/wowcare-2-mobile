import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_empty_state.dart';

import '../../domain/entities/regularization_request.dart';
import '../widgets/reg_admin_notification_tile.dart';
import '../widgets/reg_decision_sheet.dart';
import '../widgets/reg_scaffold.dart';

/// Admin approver inbox — pending regularization requests.
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
          : ListView.separated(
              padding: const EdgeInsets.all(Av2Spacing.md),
              itemCount: pending.length,
              itemBuilder: (context, i) => RegAdminNotificationTile(
                request: pending[i],
                onTap: () => _review(context, pending[i]),
              ),
              separatorBuilder: (_, __) => const SizedBox(height: Av2Spacing.xs + 2),
            ),
    );
  }

  Future<void> _review(BuildContext context, RegularizationRequest r) async {
    final decision = await showRegDecisionSheet(context, request: r);
    if (decision == null) return;
    final msg = decision.approved
        ? 'Approved · ${r.staffName}'
        : 'Rejected · ${r.staffName}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
