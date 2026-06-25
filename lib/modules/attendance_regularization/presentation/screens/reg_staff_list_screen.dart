import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';
import '../widgets/reg_gate_dialog.dart';
import '../widgets/reg_raise_sheet.dart';
import '../widgets/reg_request_tile.dart';
import '../widgets/reg_scaffold.dart';

/// Staff "my regularizations" — an optional needs-attention banner (unresolved
/// soft sign-out) + the list of the staff's requests.
class RegStaffListScreen extends StatelessWidget {
  const RegStaffListScreen({
    super.key,
    required this.requests,
    this.pendingGate,
  });

  final List<RegularizationRequest> requests;
  final MissedSignout? pendingGate;

  @override
  Widget build(BuildContext context) {
    return RegScaffold(
      title: 'My regularizations',
      body: ListView(
        padding: const EdgeInsets.all(Av2Spacing.md),
        children: [
          if (pendingGate != null) ...[
            _needsAttention(context, pendingGate!),
            const SizedBox(height: Av2Spacing.md),
          ],
          for (var i = 0; i < requests.length; i++) ...[
            if (i != 0) const SizedBox(height: Av2Spacing.xs + 2),
            RegRequestTile(request: requests[i]),
          ],
        ],
      ),
    );
  }

  Widget _needsAttention(BuildContext context, MissedSignout item) {
    return Container(
      padding: const EdgeInsets.all(Av2Spacing.sm),
      decoration: BoxDecoration(
        color: Av2Colors.overtimeFill,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Av2Colors.overtime),
          const SizedBox(width: Av2Spacing.sm),
          Expanded(
            child: Text(
              "Missed sign-out on ${Av2DateFormatter.monthDay(item.attendanceDate)}",
              style: Av2Text.caption.copyWith(color: Av2Colors.overtime),
            ),
          ),
          TextButton(
            onPressed: () => _resolve(context, item),
            child: Text('Resolve',
                style: Av2Text.label.copyWith(
                    color: Av2Colors.overtime, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(BuildContext context, MissedSignout item) async {
    final action = await showRegGateDialog(context, item: item, mandatory: false);
    if (action == null) return;
    if (action == RegGateAction.raise) {
      final result = await showRegRaiseSheet(context, item: item);
      if (result == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regularization request submitted')),
      );
    } else if (action == RegGateAction.confirmSoftTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-out confirmed')),
      );
    }
  }
}
