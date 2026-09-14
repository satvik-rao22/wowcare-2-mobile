import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

import '../../regularization.dart';
import '../cubit/reg_dashboard_cubit.dart';

/// The module's single dashboard surface — the one widget the host app drops
/// into a dashboard.
///
/// It decides what to render from [RoleCubit], so both dashboards add the same
/// line and neither needs to know which persona it is showing:
///
/// * **staff** — the unresolved missed sign-out banner, and the auto-appearing
///   resolve sheet
/// * **admin** — the "needs your approval" card with a pending count
///
/// Renders nothing (zero height) when there is nothing to say, so it is safe
/// to place unconditionally.
class RegDashboardEntry extends StatelessWidget {
  const RegDashboardEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegDashboardCubit>(
      create: (_) => serviceLocator<RegDashboardCubit>(),
      child: const _RegDashboardEntryBody(),
    );
  }
}

class _RegDashboardEntryBody extends StatefulWidget {
  const _RegDashboardEntryBody();

  @override
  State<_RegDashboardEntryBody> createState() =>
      _RegDashboardEntryBodyState();
}

class _RegDashboardEntryBodyState extends State<_RegDashboardEntryBody> {
  bool _kicked = false;

  bool _isAdmin(BuildContext context) {
    try {
      return context.read<RoleCubit>().state.role.toLowerCase() == 'admin';
    } catch (_) {
      // RoleCubit is provided above MaterialApp; if this widget is ever built
      // outside that tree, fall back to the staff view rather than crashing a
      // dashboard.
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_kicked) return;
    _kicked = true;
    context.read<RegDashboardCubit>().load(forAdmin: _isAdmin(context));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin(context);

    return BlocConsumer<RegDashboardCubit, RegDashboardState>(
      listenWhen: (a, b) => a.openSession != b.openSession,
      listener: (context, state) {
        // §5.1 step 1 — on app open, an unresolved day surfaces itself rather
        // than waiting for the staff to attempt a sign-in.
        //
        // Once per app session only: `autoSheetShown` is what stops this
        // re-firing on every rebuild, tab switch or dashboard refresh, which
        // would make the app feel broken.
        if (state.autoSheetShown) return;
        final cubit = context.read<RegDashboardCubit>();
        if (state.needsAction) {
          cubit.resolve(markAuto: true);
        } else if (state.hasOpenSession) {
          // Already raised — the banner is enough, no sheet is due.
          cubit.markAutoSheetShown();
        }
      },
      builder: (context, state) {
        final children = <Widget>[
          if (state.hasOpenSession) _staffBanner(context, state),
          if (isAdmin && state.hasPendingForAdmin) _adminCard(context, state),
        ];
        if (children.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Av2Spacing.md, vertical: Av2Spacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i != 0) const SizedBox(height: Av2Spacing.xs),
                children[i],
              ],
            ],
          ),
        );
      },
    );
  }

  /// Staff: the unresolved day. Copy changes once it has been raised, because
  /// the day is still uncounted (§8.1) but no longer needs action.
  Widget _staffBanner(BuildContext context, RegDashboardState state) {
    final session = state.openSession!;
    final needsAction = state.needsAction;
    final date = Av2DateFormatter.monthDay(session.attendanceDate);

    return _Banner(
      icon: needsAction ? Icons.error_outline : Icons.hourglass_top,
      title: needsAction ? 'Missed sign-out on $date' : 'Awaiting approval',
      subtitle: needsAction
          ? "That day isn't counted until you add the sign-out."
          : "$date is with your admin. It won't count until approved.",
      actionLabel: needsAction ? 'Resolve' : 'Edit',
      onAction: () => context.read<RegDashboardCubit>().resolve(),
    );
  }

  /// Admin: the approval queue, with the count as a badge. Hidden at zero —
  /// an empty queue is not news.
  Widget _adminCard(BuildContext context, RegDashboardState state) {
    final count = state.pendingCount;
    return _Banner(
      icon: Icons.fact_check_outlined,
      title: 'Needs your approval',
      subtitle: '$count regularization request${count == 1 ? '' : 's'} '
          'waiting.',
      actionLabel: 'Review',
      badge: count,
      onAction: () => Regularization.openAdminInbox(context),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Av2Colors.overtimeFill,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
      child: InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(Av2Spacing.sm),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: Av2Colors.overtime),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Av2Colors.danger,
                          borderRadius:
                              BorderRadius.circular(Av2Spacing.radiusPill),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
                          style: Av2Text.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: Av2Spacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: Av2Text.bodyMedium
                            .copyWith(color: Av2Colors.overtime)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Av2Text.caption
                            .copyWith(color: Av2Colors.overtime)),
                  ],
                ),
              ),
              const SizedBox(width: Av2Spacing.xs),
              Text(actionLabel,
                  style: Av2Text.label.copyWith(
                      color: Av2Colors.overtime,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
