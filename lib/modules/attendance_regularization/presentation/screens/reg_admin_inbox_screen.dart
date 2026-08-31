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
/// (correcting the time if needed); there is no reject. Tiles are multi-select:
/// pick a set and **Approve selected** in one action; handle the rest
/// individually.
class RegAdminInboxScreen extends StatefulWidget {
  const RegAdminInboxScreen({super.key, required this.requests});

  final List<RegularizationRequest> requests;

  @override
  State<RegAdminInboxScreen> createState() => _RegAdminInboxScreenState();
}

class _RegAdminInboxScreenState extends State<RegAdminInboxScreen> {
  final Set<String> _selected = {};

  List<RegularizationRequest> get _pending =>
      widget.requests.where((r) => r.status.isPending).toList();

  void _toggle(String code, bool on) {
    setState(() => on ? _selected.add(code) : _selected.remove(code));
  }

  void _toggleAll(List<RegularizationRequest> pending) {
    setState(() {
      if (_selected.length == pending.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(pending.map((r) => r.code));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return RegScaffold(
      title: 'Regularization requests',
      body: pending.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(Av2Spacing.md),
              child: Av2EmptyState(message: 'No pending requests'),
            )
          : Column(
              children: [
                _selectionHeader(pending),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Av2Spacing.md, 0,
                        Av2Spacing.md, Av2Spacing.md),
                    itemCount: pending.length,
                    itemBuilder: (context, i) {
                      final r = pending[i];
                      return RegAdminNotificationTile(
                        request: r,
                        selected: _selected.contains(r.code),
                        onSelectChanged: (v) => _toggle(r.code, v),
                        onTap: () => _review(r),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Av2Spacing.xs + 2),
                  ),
                ),
                if (_selected.isNotEmpty) _approveSelectedBar(),
              ],
            ),
    );
  }

  Widget _selectionHeader(List<RegularizationRequest> pending) {
    final allSelected = _selected.length == pending.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Av2Spacing.md, Av2Spacing.xs, Av2Spacing.md, Av2Spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selected.isEmpty
                  ? '${pending.length} pending'
                  : '${_selected.length} selected',
              style: Av2Text.caption.copyWith(color: Av2Colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => _toggleAll(pending),
            child: Text(allSelected ? 'Clear' : 'Select all',
                style: Av2Text.label.copyWith(
                    color: Av2Colors.theme, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _review(RegularizationRequest r) async {
    final decision = await showRegDecisionSheet(context, request: r);
    if (decision == null || !mounted) return;
    final changed = decision.signOutLocal != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(changed
            ? 'Approved with changes · ${r.staffName}'
            : 'Approved · ${r.staffName}'),
      ),
    );
    setState(() => _selected.remove(r.code));
  }

  Widget _approveSelectedBar() {
    final n = _selected.length;
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
            onTap: () => _approveSelected(n),
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
                    Text('Approve selected ($n)',
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

  Future<void> _approveSelected(int n) async {
    final confirmed = await showAv2ConfirmDialog(
      context,
      title: 'Approve $n selected?',
      message: 'These requests are approved as submitted. To change a time, '
          'open a request individually instead.',
      confirmLabel: 'Approve',
    );
    if (!confirmed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved $n requests')),
    );
    setState(_selected.clear);
  }
}
