import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/badge_cubit.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/admin_dashboard_body.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/guardian_dashboard_body.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/staff_dashboard_body.dart';

/// M03. The dashboard, for whichever persona is signed in.
///
/// One screen and three bodies (3A1, 3S1, 3P1), because role carries no
/// colour and no material: an Admin, a Staff member and a Guardian get the
/// same header, the same cards and the same keys, and only what they may see
/// and do differs.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final persona = context.read<SessionCubit>().state.persona;

    return BlocProvider<DashboardCubit>(
      create: (_) {
        final cubit = redesignLocator<DashboardCubit>(param1: persona);
        unawaited(cubit.load());
        return cubit;
      },
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final session = context.watch<SessionCubit>().state;
    final user = session.user;

    return BlocListener<SessionCubit, SessionState>(
      // 13d flips the persona under us; the dashboard reloads rather than
      // redrawing an Admin's cards with a Guardian's data.
      listenWhen: (previous, current) => previous.persona != current.persona,
      listener: (context, state) => unawaited(cubit.setPersona(state.persona)),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => ScreenScaffold(
          header: BlocBuilder<BadgeCubit, BadgeState>(
            builder: (context, badges) => DashboardHeader(
              firstName: user?.firstName ?? '',
              place: _place(session),
              dateLabel: state.snapshot.dateLabel,
              notificationCount: badges.notifications,
              isGuardian: session.isGuardian,
              onOpenMore: () => unawaited(context.push(AppRoutes.more)),
              onScanQr: () => unawaited(context.push(AppRoutes.kioskScanner)),
              onOpenNotifications: () =>
                  unawaited(context.push(AppRoutes.notifications)),
            ),
          ),
          bodyPadding: EdgeInsets.zero,
          body: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, DashboardState state) {
    if (state.isLoading) return const Center(child: LoadingState());
    if (state.isFailed) {
      return Center(
        child: ErrorState(
          onRetry: () => unawaited(context.read<DashboardCubit>().load()),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().refresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: AppSizes.screenBottomPad),
        children: <Widget>[
          switch (state.persona) {
            Persona.admin => AdminDashboardBody(state: state),
            Persona.staff => StaffDashboardBody(state: state),
            Persona.guardian => GuardianDashboardBody(state: state),
          },
        ],
      ),
    );
  }

  /// An Admin is placed by their school, a Staff member by their classroom.
  static String _place(SessionState session) {
    final user = session.user;
    if (user == null) return '';
    if (session.isStaff && user.classroomName != null) {
      return user.classroomName!;
    }
    return user.schoolName;
  }
}
