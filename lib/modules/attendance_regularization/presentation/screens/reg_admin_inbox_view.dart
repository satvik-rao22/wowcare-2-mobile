import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_confirm_dialog.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_empty_state.dart';

import '../../domain/entities/regularization_request.dart';
import '../controllers/reg_inbox_filter.dart';
import '../cubit/reg_inbox_cubit.dart';
import '../cubit/reg_inbox_state.dart';
import '../widgets/reg_admin_notification_tile.dart';
import '../widgets/reg_decision_sheet.dart';
import '../widgets/reg_filter_chips.dart';
import '../widgets/reg_request_detail_sheet.dart';

/// Admin approver list — the pending queue **and** the approved history, from
/// the one §9.5 endpoint.
///
/// Admins approve (correcting the time if needed); there is no reject and no
/// cancel (§8.4). Pending tiles are multi-select: pick a set and **Approve
/// selected** in one action (§9.7).
///
/// Brings no chrome of its own: it lives in the Staff Attendance screen's
/// **Request** tab, which supplies the app bar and the title.
///
/// The default constructor is presentation-only for tests and previews, and
/// [RegAdminInboxView.connected] wires the cubit.
class RegAdminInboxView extends StatefulWidget {
  const RegAdminInboxView({
    super.key,
    required this.requests,
    this.filter = RegInboxFilter.pending,
    this.selected = const {},
    this.onFilterChanged,
    this.onSelectChanged,
    this.onSelectAll,
    this.onApprove,
    this.onApproveSelected,
    this.onRefresh,
    this.onLoadMore,
    this.loadingMore = false,
    this.busy = false,
  });

  /// Live version, fed by [RegInboxCubit].
  static Widget connected() {
    return BlocProvider<RegInboxCubit>(
      create: (_) => serviceLocator<RegInboxCubit>()..load(),
      child: const _RegAdminInboxConnected(),
    );
  }

  /// Which tab the list opens on. Pending is the work queue.
  static const RegInboxFilter initialFilter = RegInboxFilter.pending;

  final List<RegularizationRequest> requests;
  final RegInboxFilter filter;
  final Set<String> selected;

  final ValueChanged<RegInboxFilter>? onFilterChanged;
  final void Function(String code, bool selected)? onSelectChanged;
  final VoidCallback? onSelectAll;
  final void Function(RegularizationRequest request, RegDecision decision)?
  onApprove;
  final VoidCallback? onApproveSelected;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;

  final bool loadingMore;
  final bool busy;

  @override
  State<RegAdminInboxView> createState() => _RegAdminInboxViewState();
}

class _RegAdminInboxViewState extends State<RegAdminInboxView> {
  /// Local selection, used only when the screen is driven without a cubit
  /// (tests and previews). The connected path passes selection down instead.
  final Set<String> _localSelected = {};

  Set<String> get _selected =>
      widget.onSelectChanged != null ? widget.selected : _localSelected;

  /// The rows an admin may actually act on.
  ///
  /// The list mixes statuses on the history tabs, so selection, "Select all"
  /// and the header count all work off this rather than the whole page — an
  /// already-approved row must never be selectable.
  List<RegularizationRequest> get _selectable =>
      widget.requests.where((r) => r.status.isPending).toList();

  void _toggle(String code, bool on) {
    if (widget.onSelectChanged != null) {
      widget.onSelectChanged!(code, on);
      return;
    }
    setState(() => on ? _localSelected.add(code) : _localSelected.remove(code));
  }

  void _toggleAll() {
    if (widget.onSelectAll != null) {
      widget.onSelectAll!();
      return;
    }
    setState(() {
      final codes = _selectable.map((r) => r.code).toSet();
      if (_localSelected.length == codes.length) {
        _localSelected.clear();
      } else {
        _localSelected
          ..clear()
          ..addAll(codes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showFilters = widget.onFilterChanged != null;
    return Column(
      children: [
        if (showFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: Av2Spacing.xs),
            child: RegFilterChips(
              selected: widget.filter,
              onSelected: widget.onFilterChanged!,
            ),
          ),
        Expanded(child: _body()),
        if (_selected.isNotEmpty) _approveSelectedBar(),
      ],
    );
  }

  Widget _body() {
    if (widget.requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Av2Spacing.md),
        child: Av2EmptyState(message: widget.filter.emptyMessage),
      );
    }

    final list = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.onLoadMore == null) return false;
        if (notification.metrics.extentAfter < 240) widget.onLoadMore!();
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: Av2Spacing.md),
        itemCount: widget.requests.length + (widget.loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= widget.requests.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: Av2Spacing.md),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final r = widget.requests[i];
          // A checkbox appears only when `onSelectChanged` is non-null, so
          // passing null here is what makes approved rows unselectable.
          final selectable = r.status.isPending;
          return RegAdminNotificationTile(
            request: r,
            selected: _selected.contains(r.code),
            onSelectChanged: selectable
                ? (value) => _toggle(r.code, value)
                : null,
            onTap: () => _review(r),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: Av2Spacing.xs + 2),
      ),
    );

    return Column(
      children: [
        _header(),
        Expanded(
          child: widget.onRefresh == null
              ? list
              : RefreshIndicator(onRefresh: widget.onRefresh!, child: list),
        ),
      ],
    );
  }

  Widget _header() {
    final selectable = _selectable;
    final label = selectable.isNotEmpty
        ? '${selectable.length} pending'
        : '${widget.requests.length} '
              'request${widget.requests.length == 1 ? '' : 's'}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Av2Spacing.md,
        Av2Spacing.sm,
        Av2Spacing.md,
        Av2Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selected.isEmpty ? label : '${_selected.length} selected',
              style: Av2Text.caption.copyWith(color: Av2Colors.textSecondary),
            ),
          ),
          if (selectable.isNotEmpty)
            TextButton(
              onPressed: _toggleAll,
              child: Text(
                _selected.length == selectable.length ? 'Clear' : 'Select all',
                style: Av2Text.label.copyWith(
                  color: Av2Colors.theme,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _approveSelectedBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Av2Spacing.sm),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            child: InkWell(
              onTap: widget.busy ? null : _confirmApproveSelected,
              borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
              child: Ink(
                height: 48,
                decoration: BoxDecoration(
                  gradient: Av2Colors.primaryGradient,
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                ),
                child: Center(
                  child: widget.busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Approve selected (${_selected.length})',
                          style: Av2Text.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmApproveSelected() async {
    final count = _selected.length;
    final confirmed = await showAv2ConfirmDialog(
      context,
      title: 'Approve $count request${count == 1 ? '' : 's'}?',
      message:
          'Each will be approved as submitted, and those days will be '
          'counted.',
      confirmLabel: 'Approve',
    );
    if (confirmed != true || !mounted) return;

    if (widget.onApproveSelected != null) {
      widget.onApproveSelected!();
      return;
    }
    setState(_localSelected.clear);
  }

  /// Pending opens the decision sheet; anything already approved opens
  /// read-only.
  ///
  /// They used to share the approve sheet, which shows the raiser's reason and
  /// says nothing about the decision — so an admin could never see the note
  /// they themselves wrote when adjusting a time.
  Future<void> _review(RegularizationRequest r) async {
    if (!r.status.isPending) {
      await showRegRequestDetailSheet(context, request: r);
      return;
    }
    final decision = await showRegDecisionSheet(context, request: r);
    if (decision == null || !mounted) return;
    if (widget.onApprove != null) {
      widget.onApprove!(r, decision);
      return;
    }
    // Preview / test path: report locally, no network.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decision.signOutLocal != null
              ? 'Approved with an adjusted time'
              : 'Approved',
        ),
      ),
    );
  }
}

/// Binds [RegInboxCubit] to the presentation-only screen above.
class _RegAdminInboxConnected extends StatelessWidget {
  const _RegAdminInboxConnected();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegInboxCubit, RegInboxState>(
      listenWhen: (a, b) => a.message != b.message && b.message.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message)));
        context.read<RegInboxCubit>().clearMessage();
      },
      builder: (context, state) {
        final cubit = context.read<RegInboxCubit>();

        if (state.isLoading && state.requests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isError && state.requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Av2Spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: Av2Colors.textTertiary),
                  const SizedBox(height: Av2Spacing.sm),
                  Text(
                    state.message.isEmpty
                        ? 'Could not load requests'
                        : state.message,
                    textAlign: TextAlign.center,
                    style: Av2Text.body.copyWith(
                      color: Av2Colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Av2Spacing.sm),
                  TextButton(
                    onPressed: cubit.load,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        return RegAdminInboxView(
          requests: state.requests,
          filter: state.filter,
          selected: state.selected,
          loadingMore: state.loadingMore,
          busy: state.busy,
          onFilterChanged: cubit.setFilter,
          onSelectChanged: cubit.toggleSelect,
          onSelectAll: cubit.toggleSelectAll,
          onApproveSelected: cubit.approveSelected,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          onApprove: (request, decision) => cubit.approve(
            request.code,
            signOutLocal: decision.signOutLocal,
            note: decision.note,
          ),
        );
      },
    );
  }
}
