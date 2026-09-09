import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_empty_state.dart';

import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';
import '../cubit/reg_my_requests_cubit.dart';
import '../cubit/reg_my_requests_state.dart';
import '../widgets/reg_request_tile.dart';
import '../widgets/reg_resolve_sheet.dart';
import '../widgets/reg_scaffold.dart';

/// Staff "my regularizations" — an optional needs-attention banner (the
/// unresolved missed sign-out) plus the staff's own requests.
///
/// Two constructors on purpose:
///
/// * the default takes plain lists, which keeps the widget tests fast and
///   cubit-free and lets `reg_dev_app.dart` preview it with fixtures;
/// * [RegStaffListScreen.connected] wraps it in its cubit for the real app.
class RegStaffListScreen extends StatelessWidget {
  const RegStaffListScreen({
    super.key,
    required this.requests,
    this.pendingGate,
    this.onRefresh,
    this.onLoadMore,
    this.onResolveGate,
    this.onEdit,
    this.loadingMore = false,
    this.busyCode,
  });

  /// Live version, fed by [RegMyRequestsCubit].
  static Widget connected() {
    return BlocProvider<RegMyRequestsCubit>(
      create: (_) => serviceLocator<RegMyRequestsCubit>()..load(),
      child: const _RegStaffListConnected(),
    );
  }

  final List<RegularizationRequest> requests;

  /// The open past session, if any. Only one can exist: the gate blocks the
  /// next sign-in (staff *and* admin-on-behalf) until it is raised, so a
  /// backlog never accumulates.
  final MissedSignout? pendingGate;

  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final VoidCallback? onResolveGate;

  /// §9.4 — revise a pending request. There is no cancel (§8.4).
  final void Function(RegularizationRequest request)? onEdit;

  final bool loadingMore;
  final String? busyCode;

  @override
  Widget build(BuildContext context) {
    final body = _list(context);
    return RegScaffold(
      title: 'My regularizations',
      body: onRefresh == null
          ? body
          : RefreshIndicator(onRefresh: onRefresh!, child: body),
    );
  }

  Widget _list(BuildContext context) {
    if (pendingGate == null && requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(Av2Spacing.md),
        child: Av2EmptyState(message: 'No regularization requests'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (onLoadMore == null) return false;
        if (notification.metrics.extentAfter < 240) onLoadMore!();
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.all(Av2Spacing.md),
        children: [
          if (pendingGate != null) ...[
            _needsAttention(context, pendingGate!),
            const SizedBox(height: Av2Spacing.md),
          ],
          for (var i = 0; i < requests.length; i++) ...[
            if (i != 0) const SizedBox(height: Av2Spacing.xs + 2),
            RegRequestTile(
              request: requests[i],
              busy: busyCode == requests[i].code,
              // Only a pending request can be edited (§8.6); an approved one
              // is terminal and immutable.
              onTap: requests[i].isEditable && onEdit != null
                  ? () => onEdit!(requests[i])
                  : null,
            ),
          ],
          if (loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Av2Spacing.md),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _needsAttention(BuildContext context, MissedSignout item) {
    // Once raised, the day is still uncounted (§8.1) so the banner stays —
    // but as a status, not a call to action.
    final raised = !item.blocksSignIn;
    return Container(
      padding: const EdgeInsets.all(Av2Spacing.sm),
      decoration: BoxDecoration(
        color: Av2Colors.overtimeFill,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(raised ? Icons.hourglass_top : Icons.error_outline,
              size: 18, color: Av2Colors.overtime),
          const SizedBox(width: Av2Spacing.sm),
          Expanded(
            child: Text(
              raised
                  ? 'Awaiting approval for ${Av2DateFormatter.monthDay(item.attendanceDate)}'
                  : 'Missed sign-out on ${Av2DateFormatter.monthDay(item.attendanceDate)}',
              style: Av2Text.caption.copyWith(color: Av2Colors.overtime),
            ),
          ),
          if (onResolveGate != null)
            TextButton(
              onPressed: onResolveGate,
              child: Text(raised ? 'Edit' : 'Resolve',
                  style: Av2Text.label.copyWith(
                      color: Av2Colors.overtime,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

/// Binds [RegMyRequestsCubit] to the presentation-only screen above.
class _RegStaffListConnected extends StatelessWidget {
  const _RegStaffListConnected();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegMyRequestsCubit, RegMyRequestsState>(
      listenWhen: (a, b) => a.message != b.message && b.message.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.message)));
        context.read<RegMyRequestsCubit>().clearMessage();
      },
      builder: (context, state) {
        final cubit = context.read<RegMyRequestsCubit>();

        if (state.isLoading && state.requests.isEmpty) {
          return const RegScaffold(
            title: 'My regularizations',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.isError && state.requests.isEmpty) {
          return RegScaffold(
            title: 'My regularizations',
            body: _ErrorBody(message: state.message, onRetry: cubit.load),
          );
        }

        return RegStaffListScreen(
          requests: state.requests,
          pendingGate: state.gate,
          loadingMore: state.loadingMore,
          busyCode: state.busyCode,
          onRefresh: cubit.refresh,
          onLoadMore: cubit.loadMore,
          onResolveGate: cubit.resolveGate,
          onEdit: (request) => _openEdit(context, request),
        );
      },
    );
  }

  /// Reuses the resolve sheet in edit mode — §9.4 takes exactly the two
  /// fields it already collects, so there is no second sheet to keep in step.
  Future<void> _openEdit(
    BuildContext context,
    RegularizationRequest request,
  ) async {
    final cubit = context.read<RegMyRequestsCubit>();
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

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Av2Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Av2Colors.textTertiary),
            const SizedBox(height: Av2Spacing.sm),
            Text(
              message.isEmpty ? 'Could not load requests' : message,
              textAlign: TextAlign.center,
              style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
            ),
            const SizedBox(height: Av2Spacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
