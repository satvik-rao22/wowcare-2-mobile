import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/app_update/view_model/app_update_cubit.dart';
import 'package:wowcare/presentation/features/app_update/widgets/required_update_overlay.dart';

/// Wraps the whole routed app. Lays [RequiredUpdateOverlay] over every
/// screen while an update is required, and re-checks the rule each time the
/// app returns to the foreground, so a minimum raised in the console reaches
/// people already inside the app.
///
/// The app below keeps its place in the tree whether or not the overlay is
/// up (it is always the first child), so nothing underneath is rebuilt or
/// loses state when the overlay comes and goes. It only loses focus, so a
/// hardware keyboard cannot type into a screen the overlay covers.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<AppUpdateCubit>().recheck(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppUpdateCubit, AppUpdateState, bool>(
      selector: (AppUpdateState state) => state.showsRequired,
      builder: (BuildContext context, bool blocked) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExcludeFocus(excluding: blocked, child: widget.child),
          if (blocked) const RequiredUpdateOverlay(),
        ],
      ),
    );
  }
}
