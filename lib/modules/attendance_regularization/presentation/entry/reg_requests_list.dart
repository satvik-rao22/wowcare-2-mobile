import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_confirm_dialog.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_empty_state.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';
import '../controllers/reg_inbox_filter.dart';
import '../cubit/reg_inbox_cubit.dart';
import '../cubit/reg_inbox_state.dart';
import '../widgets/reg_decision_sheet.dart';
import '../widgets/reg_request_detail_sheet.dart';
import '../widgets/reg_request_tile.dart';
import '../widgets/reg_resolve_sheet.dart';

/// One person's regularization requests — pending and history — as an
/// embeddable list.
///
/// What a row offers is derived from the request itself, never from a flag the
/// caller passes, so the list cannot offer an action the server would reject:
///
/// * **Edit** — the raiser only, while pending (§9.4).
/// * **Review / bulk approve** — an admin, on pending rows (§9.6, §9.7).
///
/// Two constructors, like the rest of the module: the default takes plain data
/// for tests and `reg_dev_app.dart`; [RegRequestsList.connected] wires the
/// cubit for the app.
class RegRequestsList extends StatelessWidget {
  const RegRequestsList({
    super.key,
    required this.requests,
    this.currentUserCode = '',
    this.isAdmin = false,
    this.selected = const {},
    this.busyCode,
    this.busy = false,
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
    this.onSelectChanged,
    this.onSelectAll,
    this.onApproveSelected,
    this.onReview,
    this.onEdit,
    this.onShowDetail,
  });

  /// Live version. An empty [staffCode] lets the token decide whose requests
  /// these are — the staff's own.
  ///
  /// [from]/[to] limit it to an attendance-date window. A new window is a new
  /// list (keyed below), so changing the period refetches rather than showing
  /// the previous period's rows.
  static Widget connected({
    String staffCode = '',
    DateTime? from,
    DateTime? to,
  }) {
    return BlocProvider<RegInboxCubit>(
      key: ValueKey<String>('$staffCode|$from|$to'),
      create: (_) => serviceLocator<RegInboxCubit>()
        ..scopeTo(staffCode, filter: RegInboxFilter.all, from: from, to: to)
        ..load(),
      child: const _RegRequestsListConnected(),
    );
  }

  final List<RegularizationRequest> requests;

  /// Signed-in user, compared against `raisedByCode` to offer edit. These are
  /// `USR_…` codes; a staff code is `STF_…`, so the two never interchange.
  final String currentUserCode;

  final bool isAdmin;
  final Set<String> selected;

  /// The row whose edit is in flight.
  final String? busyCode;

  /// An approve or bulk approve is in flight.
  final bool busy;

  final bool hasMore;
  final bool loadingMore;
  final VoidCallback? onLoadMore;

  final void Function(String code, bool on)? onSelectChanged;
  final VoidCallback? onSelectAll;
  final VoidCallback? onApproveSelected;
  final void Function(RegularizationRequest request)? onReview;
  final void Function(RegularizationRequest request)? onEdit;

  /// Opens the read-only sheet for a row that can no longer be acted on.
  final void Function(RegularizationRequest request)? onShowDetail;

  bool _canEdit(RegularizationRequest r) =>
      r.isEditable &&
      r.raisedByCode.isNotEmpty &&
      r.raisedByCode == currentUserCode;

  bool _canApprove(RegularizationRequest r) => isAdmin && r.isEditable;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Av2Spacing.md),
        child: Av2EmptyState(message: 'No regularization requests'),
      );
    }

    final selectable = requests.where(_canApprove).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectable.isNotEmpty)
          _Header(
            pending: selectable.length,
            selected: selected.length,
            onSelectAll: onSelectAll,
          ),
        for (final r in requests) ...[
          if (!identical(r, requests.first))
            const SizedBox(height: Av2Spacing.xs + 2),
          RegRequestTile(
            request: r,
            busy: busyCode == r.code,
            editable: _canEdit(r),
            selected: selected.contains(r.code),
            onSelectChanged: _canApprove(r) && onSelectChanged != null
                ? (on) => onSelectChanged!(r.code, on)
                : null,
            // Every row is tappable. Admin review wins over edit — an admin
            // looking at someone else's request is not its raiser, so only one
            // of the two ever applies — and a row nobody can act on still
            // opens read-only, which is the only place the approver's note and
            // adjusted time are visible.
            onTap: _canApprove(r)
                ? () => onReview?.call(r)
                : _canEdit(r)
                ? () => onEdit?.call(r)
                : () => onShowDetail?.call(r),
          ),
        ],
        if (hasMore) ...[
          const SizedBox(height: Av2Spacing.xs),
          Center(
            child: TextButton(
              onPressed: loadingMore ? null : onLoadMore,
              child: loadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more'),
            ),
          ),
        ],
        if (selected.isNotEmpty) ...[
          const SizedBox(height: Av2Spacing.sm),
          _ApproveSelectedBar(
            count: selected.length,
            busy: busy,
            onApprove: onApproveSelected,
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pending,
    required this.selected,
    required this.onSelectAll,
  });

  final int pending;
  final int selected;
  final VoidCallback? onSelectAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Av2Spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selected == 0 ? '$pending pending' : '$selected selected',
              style: Av2Text.caption.copyWith(color: Av2Colors.textSecondary),
            ),
          ),
          if (onSelectAll != null)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onSelectAll,
              child: Text(
                selected == pending ? 'Clear' : 'Select all',
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
}

class _ApproveSelectedBar extends StatelessWidget {
  const _ApproveSelectedBar({
    required this.count,
    required this.busy,
    required this.onApprove,
  });

  final int count;
  final bool busy;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      child: InkWell(
        onTap: busy ? null : () => _confirm(context),
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            color: Av2Colors.primaryFill,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Av2Colors.onPrimary,
                    ),
                  )
                : Text(
                    'Approve selected ($count)',
                    style: Av2Text.bodyMedium.copyWith(
                      color: Av2Colors.onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await showAv2ConfirmDialog(
      context,
      title: 'Approve $count request${count == 1 ? '' : 's'}?',
      message: 'Each is approved as submitted, and those days will be counted.',
      confirmLabel: 'Approve',
    );
    if (ok == true) onApprove?.call();
  }
}

/// Binds [RegInboxCubit] to the presentation-only list above.
class _RegRequestsListConnected extends StatelessWidget {
  const _RegRequestsListConnected();

  /// Absent a [RoleCubit] — dev harness, isolated tests — assume the least
  /// privilege rather than handing out approve buttons.
  ///
  /// `RoleState.role` defaults to `admin` until the persona resolves, so the
  /// resolution flag is checked first: without it a staff member would briefly
  /// be offered approve on someone else's requests.
  bool _isAdmin(BuildContext context) {
    try {
      final role = context.read<RoleCubit>();
      return role.isPersonaResolved && role.isTrueAdmin;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin(context);

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
          return const Padding(
            padding: EdgeInsets.all(Av2Spacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.isError && state.requests.isEmpty) {
          return _Failed(
            text: state.message.isEmpty
                ? 'Could not load requests'
                : state.message,
            onRetry: cubit.load,
          );
        }

        return RegRequestsList(
          requests: state.requests,
          currentUserCode: state.currentUserCode,
          isAdmin: isAdmin,
          selected: state.selected,
          busyCode: state.busyCode,
          busy: state.busy,
          hasMore: state.hasMore,
          loadingMore: state.loadingMore,
          onLoadMore: cubit.loadMore,
          onSelectChanged: cubit.toggleSelect,
          onSelectAll: cubit.toggleSelectAll,
          onApproveSelected: cubit.approveSelected,
          onReview: (r) => _review(context, r),
          onEdit: (r) => _edit(context, r),
          onShowDetail: (r) => showRegRequestDetailSheet(context, request: r),
        );
      },
    );
  }

  Future<void> _review(
    BuildContext context,
    RegularizationRequest request,
  ) async {
    final cubit = context.read<RegInboxCubit>();
    final decision = await showRegDecisionSheet(context, request: request);
    if (decision == null) return;
    await cubit.approve(
      request.code,
      signOutLocal: decision.signOutLocal,
      note: decision.note,
    );
  }

  Future<void> _edit(
    BuildContext context,
    RegularizationRequest request,
  ) async {
    final cubit = context.read<RegInboxCubit>();
    final result = await showRegResolveSheet(
      context,
      item: MissedSignout(
        attendanceCode: request.attendanceCode,
        attendanceDate: request.attendanceDate,
        suggestedSignOutTime: request.requestedSignOutTime,
        hasPendingRequest: true,
        pendingRequestCode: request.code,
        staffCode: request.staffCode,
        staffName: request.staffName,
      ),
      mode: RegResolveMode.edit,
      initialSignOutLocal: request.requestedSignOutTime,
      initialReason: request.reason,
    );
    if (result == null) return;
    await cubit.edit(
      request.code,
      attendanceDate: request.attendanceDate,
      signOutLocal: result.signOutLocal,
      reason: result.reason,
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Av2Spacing.md),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Av2Colors.textTertiary),
          const SizedBox(height: Av2Spacing.sm),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
