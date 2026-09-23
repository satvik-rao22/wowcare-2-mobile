import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';

import '../cubit/reg_dashboard_cubit.dart';

/// Renders nothing. Its only job is to surface an unresolved past day when the
/// app opens, rather than waiting for the staff to attempt a sign-in.
///
/// There is no accompanying card on purpose: sign-in is blocked until the
/// request exists, so the gate itself is the reminder.
class RegGateWatcher extends StatelessWidget {
  const RegGateWatcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegDashboardCubit>(
      create: (_) => serviceLocator<RegDashboardCubit>(),
      child: const _RegGateWatcherBody(),
    );
  }
}

class _RegGateWatcherBody extends StatefulWidget {
  const _RegGateWatcherBody();

  @override
  State<_RegGateWatcherBody> createState() => _RegGateWatcherBodyState();
}

class _RegGateWatcherBodyState extends State<_RegGateWatcherBody> {
  bool _kicked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_kicked) return;
    _kicked = true;
    context.read<RegDashboardCubit>().load(forAdmin: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegDashboardCubit, RegDashboardState>(
      listenWhen: (a, b) => a.openSession != b.openSession,
      listener: (context, state) {
        // Once per app session — `autoSheetShown` is what stops this re-firing
        // on every rebuild, tab switch or dashboard refresh.
        if (state.autoSheetShown) return;
        final cubit = context.read<RegDashboardCubit>();
        if (state.needsAction) {
          cubit.resolve(markAuto: true);
        } else if (state.hasOpenSession) {
          // Already raised — nothing is due.
          cubit.markAutoSheetShown();
        }
      },
      child: const SizedBox.shrink(),
    );
  }
}
